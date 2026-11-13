import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Starts the xmrig binary as a child process and streams its console output.
/// Only usable on Windows, macOS and Linux (mobile OSes cannot run it).
class LocalMiner {
  static bool get supported => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  Process? _proc;
  final _ctl = StreamController<String>.broadcast();

  bool get running => _proc != null;
  Stream<String> get lines => _ctl.stream;

  Future<String> writeConfig(Map<String, dynamic> config) async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}xmrig_config.json');
    await file.create(recursive: true);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(config));
    return file.path;
  }

  Future<void> start(String exePath, Map<String, dynamic> config) async {
    if (_proc != null) await stop();
    final exe = File(exePath);
    if (!await exe.exists()) {
      throw StateError('xmrig executable not found: $exePath');
    }
    final cfgPath = await writeConfig(config);
    final p = await Process.start(exePath, ['-c', cfgPath], workingDirectory: exe.parent.path);
    _proc = p;

    void pipe(Stream<List<int>> s) => s
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen(_ctl.add, onError: (_) {});
    pipe(p.stdout);
    pipe(p.stderr);

    unawaited(p.exitCode.then((code) {
      if (identical(_proc, p)) _proc = null;
      if (!_ctl.isClosed) _ctl.add('[app] xmrig exited with code $code');
    }));
  }

  Future<void> stop() async {
    final p = _proc;
    if (p == null) return;
    _proc = null;
    p.kill();
    try {
      await p.exitCode.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      p.kill(ProcessSignal.sigkill);
    }
  }

  void dispose() {
    _proc?.kill();
    _proc = null;
    _ctl.close();
  }
}
