import 'dart:convert';
import 'dart:math';

/// Mirrors src/config.json from the XMRig repo (the built-in default).
const String kDefaultConfigJson = r'''
{
  "api": {"id": null, "worker-id": null},
  "http": {"enabled": false, "host": "127.0.0.1", "port": 0, "access-token": null, "restricted": true},
  "autosave": true,
  "background": false,
  "colors": true,
  "title": true,
  "randomx": {"init": -1, "init-avx2": -1, "mode": "auto", "1gb-pages": false, "rdmsr": true, "wrmsr": true, "cache_qos": false, "numa": true, "scratchpad_prefetch_mode": 1},
  "cpu": {"enabled": true, "huge-pages": true, "huge-pages-jit": false, "hw-aes": null, "priority": null, "memory-pool": false, "yield": true, "max-threads-hint": 100, "asm": true, "argon2-impl": null},
  "opencl": {"enabled": false, "cache": true, "loader": null, "platform": "AMD", "adl": true},
  "cuda": {"enabled": false, "loader": null, "nvml": true},
  "donate-level": 1,
  "donate-over-proxy": 1,
  "log-file": null,
  "pools": [
    {"algo": null, "coin": null, "url": "", "user": "", "pass": "x", "rig-id": null, "nicehash": false, "keepalive": false, "enabled": true, "tls": false, "tls-fingerprint": null, "daemon": false, "socks5": null, "self-select": null, "submit-to-origin": false}
  ],
  "print-time": 60,
  "health-print-time": 60,
  "dmi": true,
  "retries": 5,
  "retry-pause": 5,
  "syslog": false,
  "tls": {"enabled": false, "protocols": null, "cert": null, "cert_key": null, "ciphers": null, "ciphersuites": null, "dhparam": null},
  "dns": {"ip_version": 0, "ttl": 30},
  "user-agent": null,
  "verbose": 0,
  "watch": true,
  "pause-on-battery": false,
  "pause-on-active": false
}
''';

String randomToken([int bytes = 16]) {
  final r = Random.secure();
  return List.generate(bytes, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
}

/// The settings the setup form edits. Everything else in the XMRig config is
/// preserved (remote) or left at XMRig defaults (local start).
class ConfigForm {
  ConfigForm({
    this.poolUrl = '',
    this.wallet = '',
    this.password = 'x',
    this.rigId = '',
    this.algo = '',
    this.tls = false,
    this.keepalive = true,
    this.hugePages = true,
    this.threadsHint = 100,
    this.apiPort = 44444,
    this.allowLan = false,
  });

  String poolUrl, wallet, password, rigId, algo;
  bool tls, keepalive, hugePages, allowLan;
  int threadsHint, apiPort;

  String? validate() {
    if (poolUrl.trim().isEmpty) return 'Enter a pool address (host:port).';
    if (!poolUrl.contains(':')) return 'Pool address needs a port, e.g. pool.example.com:3333';
    if (wallet.trim().isEmpty) return 'Enter your wallet address (the pool "user").';
    if (apiPort < 1 || apiPort > 65535) return 'API port must be 1-65535.';
    return null;
  }

  Map<String, dynamic> toJson() => {
        'poolUrl': poolUrl, 'wallet': wallet, 'password': password, 'rigId': rigId,
        'algo': algo, 'tls': tls, 'keepalive': keepalive, 'hugePages': hugePages,
        'threadsHint': threadsHint, 'apiPort': apiPort, 'allowLan': allowLan,
      };

  factory ConfigForm.fromJson(Map<String, dynamic> j) => ConfigForm(
        poolUrl: j['poolUrl'] as String? ?? '',
        wallet: j['wallet'] as String? ?? '',
        password: j['password'] as String? ?? 'x',
        rigId: j['rigId'] as String? ?? '',
        algo: j['algo'] as String? ?? '',
        tls: j['tls'] as bool? ?? false,
        keepalive: j['keepalive'] as bool? ?? true,
        hugePages: j['hugePages'] as bool? ?? true,
        threadsHint: (j['threadsHint'] as num?)?.toInt() ?? 100,
        apiPort: (j['apiPort'] as num?)?.toInt() ?? 44444,
        allowLan: j['allowLan'] as bool? ?? false,
      );

  /// Reads the form fields back out of a config fetched from a running miner.
  void loadFrom(Map<String, dynamic> c) {
    final pools = c['pools'];
    if (pools is List && pools.isNotEmpty && pools.first is Map) {
      final p = pools.first as Map;
      poolUrl = (p['url'] as String?) ?? poolUrl;
      wallet = (p['user'] as String?) ?? wallet;
      password = (p['pass'] as String?) ?? password;
      rigId = (p['rig-id'] as String?) ?? '';
      algo = (p['algo'] as String?) ?? '';
      tls = p['tls'] == true;
      keepalive = p['keepalive'] == true;
    }
    final http = c['http'];
    if (http is Map) {
      final port = http['port'];
      if (port is num && port > 0) apiPort = port.toInt();
      final host = http['host'];
      if (host is String) allowLan = host != '127.0.0.1' && host != 'localhost';
    }
    final cpu = c['cpu'];
    if (cpu is Map) {
      hugePages = cpu['huge-pages'] != false;
      final h = cpu['max-threads-hint'];
      if (h is num) threadsHint = h.toInt().clamp(1, 100);
    }
  }
}

Map<String, dynamic> _copy(Map<String, dynamic> m) => jsonDecode(jsonEncode(m)) as Map<String, dynamic>;

/// Merges [f] into [base] (or XMRig's default config).
///
/// With [local] true the `http` section is (re)written so the app can talk to
/// the miner it starts, and console colours are turned off for clean logs.
/// For a remote miner the http section is never touched, otherwise the
/// running miner could rebind its API and drop the connection.
Map<String, dynamic> buildConfig(ConfigForm f,
    {Map<String, dynamic>? base, required bool local, String token = ''}) {
  final c = base != null ? _copy(base) : jsonDecode(kDefaultConfigJson) as Map<String, dynamic>;

  final pools = c['pools'] is List ? List<dynamic>.from(c['pools'] as List) : <dynamic>[];
  final first = pools.isNotEmpty && pools.first is Map
      ? Map<String, dynamic>.from(pools.first as Map)
      : <String, dynamic>{};
  first['url'] = f.poolUrl.trim();
  first['user'] = f.wallet.trim();
  first['pass'] = f.password;
  first['rig-id'] = f.rigId.trim().isEmpty ? null : f.rigId.trim();
  first['tls'] = f.tls;
  first['keepalive'] = f.keepalive;
  first['enabled'] = true;
  if (f.algo.trim().isNotEmpty) first['algo'] = f.algo.trim();
  if (pools.isEmpty) {
    pools.add(first);
  } else {
    pools[0] = first;
  }
  c['pools'] = pools;

  final cpu = c['cpu'] is Map ? Map<String, dynamic>.from(c['cpu'] as Map) : <String, dynamic>{};
  cpu['max-threads-hint'] = f.threadsHint;
  cpu['huge-pages'] = f.hugePages;
  c['cpu'] = cpu;

  if (local) {
    c['http'] = {
      'enabled': true,
      'host': f.allowLan ? '0.0.0.0' : '127.0.0.1',
      'port': f.apiPort,
      'access-token': token,
      // Needed so the app can push config changes later (PUT /1/config).
      'restricted': false,
    };
    c['colors'] = false;
    c['title'] = false;
    c['background'] = false;
  }
  return c;
}
