double? _d(dynamic v) => v is num ? v.toDouble() : null;
int _i(dynamic v) => v is num ? v.toInt() : 0;
String _s(dynamic v) => v is String ? v : '';
Map _m(dynamic v) => v is Map ? v : const {};

/// Parsed `GET /2/summary` response from XMRig.
class MinerSummary {
  MinerSummary({
    required this.id,
    required this.workerId,
    required this.version,
    required this.ua,
    required this.algo,
    required this.cpuBrand,
    required this.uptime,
    required this.paused,
    required this.restricted,
    required this.hr10s,
    required this.hr60s,
    required this.hr15m,
    required this.highest,
    required this.pool,
    required this.ip,
    required this.tls,
    required this.connUptimeMs,
    required this.ping,
    required this.failures,
    required this.accepted,
    required this.rejected,
    required this.avgTimeMs,
    required this.hashesTotal,
    required this.diff,
  });

  final String id, workerId, version, ua, algo, cpuBrand;
  final int uptime;
  final bool paused, restricted;
  final double? hr10s, hr60s, hr15m, highest;
  final String pool, ip, tls;
  final int connUptimeMs, ping, failures;
  final int accepted, rejected, avgTimeMs, hashesTotal;
  final num diff;

  /// XMRig reports an empty pool string and 0 connection time while the
  /// stratum connection is down (see NetworkState::getConnection).
  bool get poolConnected => pool.isNotEmpty && connUptimeMs > 0;

  int get sharesTotal => accepted + rejected;

  /// Accepted shares as a percentage of all submitted shares (null before the first share).
  double? get acceptRate => sharesTotal == 0 ? null : accepted * 100 / sharesTotal;
  double? get currentHashrate => hr10s ?? hr60s ?? hr15m;

  factory MinerSummary.fromJson(Map<String, dynamic> j) {
    final cpu = _m(j['cpu']);
    final hr = _m(j['hashrate']);
    final total = hr['total'] is List ? hr['total'] as List : const [];
    final conn = _m(j['connection']);
    final res = _m(j['results']);
    double? t(int i) => i < total.length ? _d(total[i]) : null;
    final good = _i(res['shares_good']);

    return MinerSummary(
      id: _s(j['id']),
      workerId: _s(j['worker_id']),
      version: _s(j['version']),
      ua: _s(j['ua']),
      algo: _s(j['algo']),
      cpuBrand: _s(cpu['brand']),
      uptime: _i(j['uptime']),
      paused: j['paused'] == true,
      restricted: j['restricted'] != false,
      hr10s: t(0),
      hr60s: t(1),
      hr15m: t(2),
      highest: _d(hr['highest']),
      pool: _s(conn['pool']),
      ip: _s(conn['ip']),
      tls: _s(conn['tls']),
      connUptimeMs: _i(conn['uptime_ms'] ?? conn['uptime']),
      ping: _i(conn['ping']),
      failures: _i(conn['failures']),
      accepted: good,
      rejected: _i(res['shares_total']) - good,
      avgTimeMs: _i(res['avg_time_ms']),
      hashesTotal: _i(res['hashes_total']),
      diff: (conn['diff'] ?? res['diff_current'] ?? 0) as num,
    );
  }
}
