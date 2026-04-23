import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

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

  /// Semantic version without build suffix (e.g. "1.0.0")
  String get displayVersion {
    final idx = version.indexOf('-');
    return idx > 0 ? version.substring(0, idx) : version;
  }

  /// Human-readable build date from tag like "1.0.0-build.202604221613"
  String? get buildDate {
    final match = RegExp(r'build\.(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})').firstMatch(version);
    if (match == null) return null;
    return '${match.group(3)}.${match.group(2)}.${match.group(1)}';
  }

  String get formattedSize {
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).round()} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Clean release notes: remove raw markdown links and GitHub compare URLs
  static String cleanReleaseNotes(String raw) {
    var text = raw;
    // Remove "**Full Changelog**: https://..." lines
    text = text.replaceAll(RegExp(r'\*\*Full Changelog\*\*:?\s*https?://\S+', caseSensitive: false), '');
    // Remove standalone GitHub URLs
    text = text.replaceAll(RegExp(r'https?://github\.com/\S+'), '');
    // Remove markdown bold markers
    text = text.replaceAll('**', '');
    // Collapse multiple newlines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
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
      final releaseNotes = body.isNotEmpty
          ? UpdateInfo.cleanReleaseNotes(body)
          : 'New update available';

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
    // Strip build suffix (e.g. "1.0.0-build.202604221613" -> "1.0.0")
    final clean1 = v1.contains('-') ? v1.substring(0, v1.indexOf('-')) : v1;
    final clean2 = v2.contains('-') ? v2.substring(0, v2.indexOf('-')) : v2;
    final parts1 = clean1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final parts2 = clean2.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    while (parts1.length < parts2.length) parts1.add(0);
    while (parts2.length < parts1.length) parts2.add(0);
    for (int i = 0; i < parts1.length; i++) {
      if (parts1[i] > parts2[i]) return 1;
      if (parts1[i] < parts2[i]) return -1;
    }
    return 0;
  }
}

