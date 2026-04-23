import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  UpdateState get state => _state;
  UpdateInfo? get updateInfo => _updateInfo;
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;
  String? get downloadedPath => _downloadedPath;

  bool get hasUpdate => _updateInfo != null;
  bool get canInstall => _state == UpdateState.downloaded && _downloadedPath != null;

  Future<void> checkForUpdate() async {
    if (_state == UpdateState.checking || _state == UpdateState.downloading) return;

    _state = UpdateState.checking;
    _errorMessage = null;
    notifyListeners();

    try {
      final updateInfo = await UpdateService.checkForUpdate();
      if (updateInfo != null) {
        _updateInfo = updateInfo;
        _state = UpdateState.available;
      } else {
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
    notifyListeners();
    try {
      final result = await OpenFile.open(_downloadedPath!);
      if (result.type != ResultType.done) {
        _state = UpdateState.error;
        _errorMessage =
            result.message.isNotEmpty ? result.message : 'Install failed';
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