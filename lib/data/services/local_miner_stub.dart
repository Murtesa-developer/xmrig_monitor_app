/// Web build: browsers cannot start programs, so only remote monitoring works.
class LocalMiner {
  static bool get supported => false;
  bool get running => false;
  Stream<String> get lines => const Stream<String>.empty();

  Future<String> writeConfig(Map<String, dynamic> config) async =>
      throw UnsupportedError('Starting xmrig is not possible in a browser.');

  Future<void> start(String exePath, Map<String, dynamic> config) async =>
      throw UnsupportedError('Starting xmrig is not possible in a browser.');

  Future<void> stop() async {}
  void dispose() {}
}
