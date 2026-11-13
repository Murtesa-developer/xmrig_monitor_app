final _ansi = RegExp(r'\x1B\[[0-9;?]*[A-Za-z]');

String stripAnsi(String s) => s.replaceAll(_ansi, '');

enum LogLevel { info, good, warn, error }

/// What a log line says about the pool connection.
enum PoolHint { unknown, connected, disconnected }

class ParsedLine {
  const ParsedLine(this.text, this.level, this.hint);
  final String text;
  final LogLevel level;
  final PoolHint hint;
}

/// Classifies one line of XMRig console output. Strings match the LOG_*
/// calls in src/base/net/stratum/Client.cpp and src/net/Network.cpp.
ParsedLine parseLogLine(String raw) {
  final text = stripAnsi(raw).trimRight();
  final l = text.toLowerCase();
  bool any(List<String> keys) => keys.any(l.contains);

  if (any(['connect error', 'read error', 'dns error', 'login error', 'write error',
      'send failed', 'no active pools', 'no active connection', 'unsupported algorithm'])) {
    return ParsedLine(text, LogLevel.error, PoolHint.disconnected);
  }
  if (l.contains('rejected')) return ParsedLine(text, LogLevel.warn, PoolHint.connected);
  if (l.contains('accepted')) return ParsedLine(text, LogLevel.good, PoolHint.connected);
  if (any(['use pool', 'new job'])) return ParsedLine(text, LogLevel.good, PoolHint.connected);
  if (any(['error', 'failed'])) return ParsedLine(text, LogLevel.error, PoolHint.unknown);
  if (any(['reconnect', 'paused', 'warn'])) return ParsedLine(text, LogLevel.warn, PoolHint.unknown);
  return ParsedLine(text, LogLevel.info, PoolHint.unknown);
}
