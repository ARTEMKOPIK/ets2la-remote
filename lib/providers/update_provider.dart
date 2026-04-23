import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/install_permission_service.dart';
import '../services/update_service.dart';

enum UpdateState {
  idle,
  checking,
  available,
  downloading,
  downloaded,
  installing,
  error,
}

class UpdateProvider extends ChangeNotifier {
  UpdateState _state = UpdateState.idle;
  UpdateInfo? _updateInfo;
  double _downloadProgress = 0.0;
  String? _errorMessage;
  String? _downloadedPath;
  bool _needsInstallPermission = false;

  /// Release notes to show in the "What's new" dialog on first launch of
  /// a new build. Non-null exactly once per version upgrade.
  String? _whatsNewNotes;
  String? _whatsNewVersion;

  UpdateState get state => _state;
  UpdateInfo? get updateInfo => _updateInfo;
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;
  String? get downloadedPath => _downloadedPath;
  String? get whatsNewNotes => _whatsNewNotes;
  String? get whatsNewVersion => _whatsNewVersion;
  bool get hasWhatsNew => _whatsNewNotes != null;

  /// True when the APK is downloaded but the user hasn't granted
  /// "Install unknown apps" for this app. The dialog surfaces a help button
  /// that deep-links to the matching Settings screen.
  bool get needsInstallPermission => _needsInstallPermission;

  bool get hasUpdate => _updateInfo != null;
  bool get canInstall => _state == UpdateState.downloaded && _downloadedPath != null;

  /// Check GitHub for a new release.
  ///
  /// [manual] — true when the user explicitly tapped "Check for updates" in
  /// Settings. In that case we bypass the "Remind me later" suppression:
  /// the user is actively asking, so silently saying "up-to-date" when a
  /// newer version actually exists would be a lie. Auto-checks on app
  /// startup still honour the skipped-version flag so users aren't nagged
  /// on every launch.
  Future<void> checkForUpdate({bool manual = false}) async {
    if (_state == UpdateState.checking || _state == UpdateState.downloading) return;

    _state = UpdateState.checking;
    _errorMessage = null;
    notifyListeners();

    try {
      final updateInfo = await UpdateService.checkForUpdate();
      if (updateInfo != null) {
        if (!manual) {
          // Auto-check: honour "Remind me later" until a newer release appears.
          final prefs = await SharedPreferences.getInstance();
          final skipped = prefs.getString('update_skipped_version');
          if (skipped != null && skipped == updateInfo.version) {
            _state = UpdateState.idle;
            notifyListeners();
            return;
          }
        }
        _updateInfo = updateInfo;
        _state = UpdateState.available;
      } else {
        // Up-to-date: clear any stale skip flag so that, after the user
        // installs the latest release, the next real update isn't
        // accidentally suppressed by a leftover "skip v1.2.3" preference.
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('update_skipped_version');
        _updateInfo = null;
        _state = UpdateState.idle;
      }
    } catch (e) {
      debugPrint('UpdateProvider.checkForUpdate error: $e');
      _state = UpdateState.error;
      _errorMessage = 'Check error: $e';
    }
    notifyListeners();
  }

  Future<void> downloadUpdate() async {
    if (_updateInfo == null) return;

    _state = UpdateState.downloading;
    _downloadProgress = 0.0;
    notifyListeners();

    final client = http.Client();
    IOSink? sink;
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = 'ets2la-${_updateInfo!.version}.apk';
      final file = File('${tempDir.path}/$fileName');

      final req = http.Request('GET', Uri.parse(_updateInfo!.downloadUrl));
      final res = await client.send(req);

      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }

      final contentLength = res.contentLength ?? _updateInfo!.sizeBytes;
      int received = 0;
      sink = file.openWrite();

      await for (final chunk in res.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          _downloadProgress = received / contentLength;
          notifyListeners();
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;

      _downloadedPath = file.path;
      _state = UpdateState.downloaded;
      notifyListeners();
    } catch (e) {
      debugPrint('UpdateProvider.downloadUpdate error: $e');
      _state = UpdateState.error;
      _errorMessage = 'Download error: $e';
      notifyListeners();
    } finally {
      await sink?.close();
      client.close();
    }
  }

  /// Reset state to idle (for retry after error)
  void resetState() {
    _state = UpdateState.idle;
    _errorMessage = null;
    notifyListeners();
  }

  /// Detect a freshly installed build and, if so, load the release notes for
  /// it so the UI can show a one-shot "What's new" dialog. First install of
  /// the app is silent — we only show notes after an actual upgrade.
  Future<void> checkWhatsNew() async {
    try {
      final current = await UpdateService.getCurrentVersion();
      final prefs = await SharedPreferences.getInstance();
      final last = prefs.getString('last_seen_version');
      if (last == null) {
        // Fresh install — nothing to show, just seed the baseline.
        await prefs.setString('last_seen_version', current);
        return;
      }
      if (UpdateService.compareVersions(current, last) <= 0) return;

      // Mark the upgrade as seen before we fetch release notes so a network
      // failure doesn't make us re-try on every launch.
      await prefs.setString('last_seen_version', current);

      final notes = await UpdateService.getReleaseNotes(current);
      if (notes == null || notes.isEmpty) return;
      _whatsNewVersion = current;
      _whatsNewNotes = notes;
      notifyListeners();
    } catch (e) {
      debugPrint('UpdateProvider.checkWhatsNew error: $e');
    }
  }

  /// Clear the "What's new" payload after the dialog is dismissed so it
  /// doesn't re-open.
  void dismissWhatsNew() {
    if (_whatsNewNotes == null) return;
    _whatsNewNotes = null;
    _whatsNewVersion = null;
    notifyListeners();
  }

  /// Launch the downloaded APK for installation.
  ///
  /// Returns true only when Android's package installer was actually
  /// launched. Callers (e.g. the update dialog) use this to decide whether
  /// to close themselves — when install can't be launched, the dialog
  /// stays open so the user sees the error instead of the screen silently
  /// returning to the dashboard.
  Future<bool> installUpdate() async {
    if (_downloadedPath == null) return false;
    _state = UpdateState.installing;
    _errorMessage = null;
    _needsInstallPermission = false;
    notifyListeners();

    // Android 8+ requires the user to have granted "Install unknown apps"
    // for this app; without it the package installer rejects the intent
    // with "Permission denied: REQUEST_INSTALL_PACKAGES" even though the
    // manifest declares the permission. Check up-front so we can surface
    // a "Allow install" button instead of the cryptic system error.
    final canInstallNow = await InstallPermissionService.instance.canInstall();
    if (!canInstallNow) {
      _state = UpdateState.error;
      _needsInstallPermission = true;
      _errorMessage = null;
      notifyListeners();
      return false;
    }

    try {
      final result = await OpenFilex.open(_downloadedPath!);
      if (result.type != ResultType.done) {
        _state = UpdateState.error;
        // open_filex surfaces the missing grant through a permission-denied
        // message; if we see one, treat it as the same case we already
        // handle up-front instead of showing raw text to the user.
        final msg = result.message;
        if (msg.contains('REQUEST_INSTALL_PACKAGES') ||
            msg.toLowerCase().contains('permission denied')) {
          _needsInstallPermission = true;
          _errorMessage = null;
        } else {
          _errorMessage = msg.isNotEmpty ? msg : 'Install failed';
        }
        notifyListeners();
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('UpdateProvider.installUpdate error: $e');
      _state = UpdateState.error;
      _errorMessage = 'Install error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Open Android Settings → "Install unknown apps" for this app so the
  /// user can grant the permission that the APK installer requires.
  Future<void> openInstallPermissionSettings() async {
    await InstallPermissionService.instance.openSettings();
  }

  Future<void> skipUpdate() async {
    if (_updateInfo != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('update_skipped_version', _updateInfo!.version);
    }
    _state = UpdateState.idle;
    _updateInfo = null;
    notifyListeners();
  }
}