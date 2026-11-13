/// One node = one XMRig miner reachable through its HTTP API.
class MinerProfile {
  MinerProfile({
    String? id,
    this.name = 'My miner',
    this.host = '',
    this.port = 44444,
    this.token = '',
    this.https = false,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  final String id;
  String name;
  String host;
  int port;
  String token;
  bool https;

  bool get hasToken => token.isNotEmpty;
  String get label => '$host:$port';

  Uri uri(String path) => Uri(
        scheme: https ? 'https' : 'http',
        host: host,
        port: port,
        path: path,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'port': port,
        'token': token,
        'https': https,
      };

  factory MinerProfile.fromJson(Map<String, dynamic> j) => MinerProfile(
        id: j['id'] as String?,
        name: j['name'] as String? ?? 'My miner',
        host: j['host'] as String? ?? '',
        port: (j['port'] as num?)?.toInt() ?? 44444,
        token: j['token'] as String? ?? '',
        https: j['https'] as bool? ?? false,
      );

  MinerProfile copy() => MinerProfile.fromJson(toJson());
}

/// Accepts "192.168.1.5", "192.168.1.5:44444", "http://host:port" or "https://host".
({String host, int? port, bool? https}) parseNodeAddress(String input) {
  final s = input.trim().replaceAll(RegExp(r'/+$'), '');
  if (s.contains('://')) {
    final u = Uri.tryParse(s);
    if (u != null && u.host.isNotEmpty) {
      return (host: u.host, port: u.hasPort ? u.port : null, https: u.scheme == 'https');
    }
  }
  final i = s.lastIndexOf(':');
  if (i > 0 && s.indexOf(':') == i) {
    // exactly one colon: host:port (IPv6 literals are left alone)
    final port = int.tryParse(s.substring(i + 1));
    if (port != null) return (host: s.substring(0, i), port: port, https: null);
  }
  return (host: s, port: null, https: null);
}
