// Picks the real process runner on dart:io platforms and a stub on web.
export 'package:xmrig_monitor/data/services/local_miner_stub.dart' if (dart.library.io) 'package:xmrig_monitor/data/services/local_miner_io.dart';
