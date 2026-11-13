import 'package:flutter_test/flutter_test.dart';
import 'package:xmrig_monitor/data/models/profile.dart';
import 'package:xmrig_monitor/data/models/summary.dart';
import 'package:xmrig_monitor/data/services/log_parser.dart';

void main() {
  test('parses connection errors and success from console lines', () {
    expect(parseLogLine('\x1B[1;31mnet  connect error: "connection refused"').hint, PoolHint.disconnected);
    expect(parseLogLine('net  use pool pool.example.com:3333 1.2.3.4').hint, PoolHint.connected);
    expect(parseLogLine('cpu  accepted (3/3) diff 1000 (50 ms)').level, LogLevel.good);
  });

  test('summary reports pool connection state', () {
    final up = MinerSummary.fromJson({
      'connection': {'pool': 'p:3333', 'uptime_ms': 5000, 'ping': 40},
      'hashrate': {'total': [100.0, 99.5, null]},
      'results': {'shares_good': 3, 'shares_total': 4},
    });
    expect(up.poolConnected, isTrue);
    expect(up.rejected, 1);
    expect(up.hr10s, 100.0);
    final down = MinerSummary.fromJson({'connection': {'pool': '', 'uptime_ms': 0}});
    expect(down.poolConnected, isFalse);
  });

  test('node address parsing', () {
    expect(parseNodeAddress('192.168.1.240').host, '192.168.1.240');
    final a = parseNodeAddress('192.168.1.240:5555');
    expect((a.host, a.port), ('192.168.1.240', 5555));
    final b = parseNodeAddress('https://miner.local/');
    expect((b.host, b.https), ('miner.local', true));
  });

  test('accept rate', () {
    final s = MinerSummary.fromJson({
      'results': {'shares_good': 99, 'shares_total': 100},
    });
    expect(s.accepted, 99);
    expect(s.rejected, 1);
    expect(s.acceptRate, closeTo(99.0, 0.001));
    expect(MinerSummary.fromJson({}).acceptRate, isNull);
  });
}
