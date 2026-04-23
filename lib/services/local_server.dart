/// Singleton local HTTP server for Unity WebGL assets.
/// Started once at app launch, stays alive for the full session.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

class LocalUnityServer {
  LocalUnityServer._();
  static final LocalUnityServer instance = LocalUnityServer._();

  static const int port = 8765;

  HttpServer? _server;
  bool _ready = false;
  bool _starting = false;

  bool get isReady => _ready;

  static const List<String> _assets = [
    'assets/unity_build/index.html',
    'assets/unity_build/visualization.loader.js',
    'assets/unity_build/visualization.framework.js',
    'assets/unity_build/visualization.data',
    'assets/unity_build/visualization.wasm',
    'assets/unity_build/version.txt',
  ];

  static const String _version = 'v4';

  /// Extract assets and start server. Safe to call multiple times.
  Future<void> ensureStarted({void Function(String)? onProgress}) async {
    if (_ready || _starting) return;
    _starting = true;

    try {
      final appDir = await getApplicationSupportDirectory();
      final outDir = Directory('${appDir.path}/unity_viz');
      if (!await outDir.exists()) await outDir.create(recursive: true);

      // Re-extract if version changed
      final versionFile = File('${outDir.path}/version.txt');
      final cachedVersion = await versionFile.exists()
          ? (await versionFile.readAsString()).trim() : '';
      final forceReExtract = cachedVersion != _version;

      for (final asset in _assets) {
        final name = asset.split('/').last;
        final outFile = File('${outDir.path}/$name');
        if (!await outFile.exists() || forceReExtract) {
          onProgress?.call('Updating $name...');
          final bytes = await rootBundle.load(asset);
          await outFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
        }
      }

      onProgress?.call('Starting local server...');
      await _startServer(outDir.path);
      _ready = true;
      _starting = false; // reset so ensureStarted can be called again if needed
    } catch (e) {
      _starting = false;
      // Log error internally, do not rethrow since this is often called fire-and-forget
      debugPrint('[LocalUnityServer] Failed to start: $e');
    }
  }

  Future<void> _startServer(String dirPath) async {
    await _server?.close(force: true);

    final staticHandler = createStaticHandler(dirPath, defaultDocument: 'index.html');

    final handler = shelf.Pipeline()
        .addMiddleware((inner) => (req) async {
              final res = await inner(req);
              return res.change(headers: {
                ...res.headers,
                'Cross-Origin-Opener-Policy': 'same-origin',
                'Cross-Origin-Embedder-Policy': 'require-corp',
                'Cross-Origin-Resource-Policy': 'cross-origin',
                'Access-Control-Allow-Origin': '*',
                'Cache-Control': 'public, max-age=86400', // cache assets 24h
              });
            })
        .addHandler(staticHandler);

    _server = await shelf_io.serve(
      handler,
      InternetAddress.loopbackIPv4,
      port,
    );
  }

  Future<void> dispose() async {
    await _server?.close(force: true);
    _server = null;
    _ready = false;
    _starting = false;
  }
}
