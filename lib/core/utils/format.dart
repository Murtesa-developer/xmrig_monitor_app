String fmtHash(double? v) {
  if (v == null) return '—';
  final p = hashParts(v);
  return '${p.value} ${p.unit}';
}

({String value, String unit}) hashParts(double v) {
  if (v >= 1e6) return (value: (v / 1e6).toStringAsFixed(2), unit: 'MH/s');
  if (v >= 1e3) return (value: (v / 1e3).toStringAsFixed(2), unit: 'kH/s');
  return (value: v.toStringAsFixed(1), unit: 'H/s');
}

String fmtDuration(int seconds) {
  final d = Duration(seconds: seconds);
  if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
  if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
  if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds % 60}s';
  return '${d.inSeconds}s';
}

String fmtTime(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

String fmtPercent(double? v) => v == null ? '—' : '${v.toStringAsFixed(v >= 99.95 || v == 0 ? 0 : 1)}%';

String fmtAgo(DateTime? t) {
  if (t == null) return '—';
  final s = DateTime.now().difference(t).inSeconds;
  if (s < 5) return 'just now';
  if (s < 60) return '${s}s ago';
  if (s < 3600) return '${s ~/ 60}m ago';
  if (s < 86400) return '${s ~/ 3600}h ago';
  return '${s ~/ 86400}d ago';
}
