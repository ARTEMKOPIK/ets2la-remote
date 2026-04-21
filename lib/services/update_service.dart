import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

// Use try-catch for package_info_plus - only available at runtime
DynamicLibrary? _tryLoadPackageInfo() => null;

/// Information about an available update
class UpdateInfo {
  final String version;
  final String releaseNotes;
  final String downloadUrl;
  final int sizeBytes;
  final bool isMandatory;

  UpdateInfo({
    required this.version,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.sizeBytes,
    this.isMandatory = false,
  });

  String get formattedSize {
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).round()} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Service for checking and downloading updates from GitHub
class UpdateService {
  static const String _repoOwner = 'ARTEMKOPIK';
  static const String _repoName = 'ets2la-remote';
  static String get _apiUrl =>
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';

  /// Get current app version
  static Future<String> getCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return info.version;
    } catch (e) {
      debugPrint('getCurrentVersion error: $e');
      return '1.0.0';
    }
  }

  /// Check for updates from GitHub
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final currentV = await getCurrentVersion();

      final res = await http.get(
        Uri.parse(_apiUrl),
        headers: {'Accept': 'application/vnd.github+json'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return null;

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final tagName = data['tag_name'] as String? ?? '';
      final latestVersion = tagName.startsWith('v') ? tagName.substring(1) : tagName;

      if (_compareVersions(latestVersion, currentV) <= 0) return null;

      final body = data['body'] as String? ?? '';
      final releaseNotes = body.isNotEmpty ? body : 'Новое обновление доступно';

      String? downloadUrl;
      int sizeBytes = 0;
      final assets = data['assets'] as List<dynamic>? ?? [];
      for (final asset in assets) {
        final name = asset['name'] as String? ?? '';
        if (name.contains('.apk')) {
          downloadUrl = asset['browser_download_url'] as String?;
          sizeBytes = asset['size'] as int? ?? 0;
          break;
        }
      }

      if (downloadUrl == null) return null;

      final isMandatory = body.toLowerCase().contains('critical');

      return UpdateInfo(
        version: latestVersion,
        releaseNotes: releaseNotes,
        downloadUrl: downloadUrl,
        sizeBytes: sizeBytes,
        isMandatory: isMandatory,
      );
    } catch (e) {
      debugPrint('UpdateService.checkForUpdate error: $e');
      return null;
    }
  }

  static int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final parts2 = v2.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    while (parts1.length < parts2.length) parts1.add(0);
    while (parts2.length < parts1.length) parts2.add(0);
    for (int i = 0; i < parts1.length; i++) {
      if (parts1[i] > parts2[i]) return 1;
      if (parts1[i] < parts2[i]) return -1;
    }
    return 0;
  }
}