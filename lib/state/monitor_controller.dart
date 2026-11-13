import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:xmrig_monitor/data/models/profile.dart';
import 'package:xmrig_monitor/data/models/summary.dart';
import 'package:xmrig_monitor/data/services/config_builder.dart';
import 'package:xmrig_monitor/data/services/local_miner.dart';
import 'package:xmrig_monitor/data/services/log_parser.dart';
import 'package:xmrig_monitor/data/services/settings_store.dart';
import 'package:xmrig_monitor/data/services/xmrig_api.dart';

enum LinkState { notConfigured, connecting, apiUnreachable, authError, poolDisconnected, paused, mining }

const kLocalNodeId = 'local';

class LogEntry {
  LogEntry(this.level, this.text, {DateTime? time}) : time = time ?? DateTime.now();
  final DateTime time;
  final LogLevel level;
  final String text;
}

/// Live state of one node: polls its API, derives connection state, keeps events.
class NodeMonitor {
  NodeMonitor(this.profile) : _api = XmrigApi(profile);

  MinerProfile profile;
  XmrigApi _api;
  LinkState state = LinkState.connecting;
  MinerSummary? summary;
  String? lastError;
  final List<LogEntry> events = [];
  final List<double> history = [];
  MinerSummary? _prev;
  bool _busy = false;

  /// When this app last saw the accepted-share counter go up (null until then).
  DateTime? lastAcceptedAt;

  bool get online =>
      summary != null &&
      (state == LinkState.mining || state == LinkState.poolDisconnected || state == LinkState.paused);
  bool get poolConnected => online && summary!.poolConnected;
  double get hashrate => online ? (summary!.currentHashrate ?? 0) : 0;

  void setProfile(MinerProfile p) {
    profile = p;
    _api.close();
    _api = XmrigApi(p);
    _prev = null;
    summary = null;
    state = LinkState.connecting;
    _log(LogLevel.info, 'Connecting to ${p.label}…');
  }

  Future<void> poll({required bool booting}) async {
    if (_busy) return;
    _busy = true;
    try {
      _apply(await _api.summary());
    } on ApiException catch (e) {
      lastError = e.message;
      final auth = e.kind == ApiErrorKind.unauthorized || e.kind == ApiErrorKind.forbidden;
      _transition(
          auth ? LinkState.authError : (booting ? LinkState.connecting : LinkState.apiUnreachable), e.message);
      summary = null;
      _prev = null;
    } finally {
      _busy = false;
    }
  }

  void _apply(MinerSummary s) {
    lastError = null;
    final prev = _prev;
    summary = s;

    final next = s.paused
        ? LinkState.paused
        : (s.poolConnected ? LinkState.mining : LinkState.poolDisconnected);

    if (prev == null || prev.pool != s.pool || prev.poolConnected != s.poolConnected) {
      if (s.poolConnected) {
        _log(LogLevel.good,
            'Connected to pool ${s.pool}${s.ip.isEmpty ? '' : ' (${s.ip})'} · ping ${s.ping} ms');
      } else if (prev != null && prev.poolConnected) {
        _log(LogLevel.error, 'Lost connection to pool ${prev.pool}');
      } else if (prev == null) {
        _log(LogLevel.warn, 'Miner is online (${s.version}) but NOT connected to a pool');
      }
    }
    if (prev != null) {
      if (s.accepted > prev.accepted) {
        lastAcceptedAt = DateTime.now();
        _log(LogLevel.good, 'Share accepted (${s.accepted} total, diff ${s.diff})');
      }
      if (s.rejected > prev.rejected) _log(LogLevel.warn, 'Share rejected (${s.rejected} total)');
      if (s.failures > prev.failures) _log(LogLevel.error, 'Pool connection failure #${s.failures}');
    }
    _transition(next, null);

    history.add(s.currentHashrate ?? 0);
    if (history.length > 120) history.removeAt(0);
    _prev = s;
  }

  void _transition(LinkState next, String? msg) {
    if (state == next) return;
    state = next;
    if (msg != null) {
      _log(next == LinkState.connecting ? LogLevel.info : LogLevel.error, msg);
    } else if (next == LinkState.paused) {
      _log(LogLevel.warn, 'Miner is paused');
    }
  }

  void _log(LogLevel level, String text) {
    events.add(LogEntry(level, text));
    if (events.length > 500) events.removeRange(0, events.length - 500);
  }

  void close() => _api.close();
}

/// Owns the node list, polls every node, and computes totals across nodes.
class MonitorController extends ChangeNotifier {
  MonitorController(this.settings) {
    _logSub = _local.lines.listen(_onProcessLine);
    _sync();
  }

  AppSettings settings;
  final LocalMiner _local = LocalMiner();
  StreamSubscription<String>? _logSub;
  final Map<String, NodeMonitor> _monitors = {};
  Timer? _timer;
  bool _polling = false;
  DateTime _localStartedAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Set when the user continues without a node (desktop local setup / after deleting all).
  bool skipLogin = false;
  PoolHint logHint = PoolHint.unknown;
  final List<LogEntry> processLog = [];
  final List<double> totalHistory = [];

  bool get localSupported => LocalMiner.supported;
  bool get localRunning => _local.running;

  List<NodeMonitor> get monitors => [
        for (final n in settings.nodes)
          if (_monitors[n.id] != null) _monitors[n.id]!,
      ];
  NodeMonitor? monitorFor(String id) => _monitors[id];

  // ---- totals --------------------------------------------------------------

  int get onlineCount => monitors.where((m) => m.online).length;
  int get poolCount => monitors.where((m) => m.poolConnected).length;
  double get totalHashrate => monitors.fold(0.0, (s, m) => s + m.hashrate);
  int get totalAccepted => monitors.fold(0, (s, m) => s + (m.online ? m.summary!.accepted : 0));
  int get totalRejected => monitors.fold(0, (s, m) => s + (m.online ? m.summary!.rejected : 0));

  /// Accepted shares as a percentage of all shares across online nodes.
  double? get acceptRate {
    final all = totalAccepted + totalRejected;
    return all == 0 ? null : totalAccepted * 100 / all;
  }

  /// Pool status of one node. For the node this app launched, the miner's
  /// console output is used when its API is unreachable.
  PoolHint poolStatusOf(NodeMonitor m) {
    if (m.online) return m.summary!.poolConnected ? PoolHint.connected : PoolHint.disconnected;
    if (m.profile.id == kLocalNodeId && localRunning) return logHint;
    return PoolHint.unknown;
  }

  // ---- lifecycle -----------------------------------------------------------

  void _sync() {
    final ids = settings.nodes.map((n) => n.id).toSet();
    _monitors.removeWhere((id, m) {
      final gone = !ids.contains(id);
      if (gone) m.close();
      return gone;
    });
    for (final n in settings.nodes) {
      _monitors.putIfAbsent(n.id, () => NodeMonitor(n).._log(LogLevel.info, 'Connecting to ${n.label}…'));
    }
  }

  void start() => _ensureTimer(pollNow: true);

  void _ensureTimer({bool pollNow = false}) {
    if (_monitors.isEmpty) {
      _timer?.cancel();
      _timer = null;
      totalHistory.clear();
      return;
    }
    _timer ??= Timer.periodic(const Duration(seconds: 2), (_) => _pollAll());
    if (pollNow) _pollAll();
  }

  Future<void> _pollAll() async {
    if (_polling) return;
    _polling = true;
    try {
      final booting = _local.running && DateTime.now().difference(_localStartedAt).inSeconds < 20;
      await Future.wait([
        for (final m in monitors) m.poll(booting: booting && m.profile.id == kLocalNodeId),
      ]);
      totalHistory.add(totalHashrate);
      if (totalHistory.length > 120) totalHistory.removeAt(0);
    } finally {
      _polling = false;
      notifyListeners();
    }
  }

  Future<void> saveSettings() => SettingsStore.save(settings);

  Future<void> _commit() async {
    _sync();
    await saveSettings();
    _ensureTimer(pollNow: true);
    notifyListeners();
  }

  Future<void> acceptTerms() async {
    settings.acceptedTerms = true;
    await saveSettings();
    notifyListeners();
  }

  void enterWithoutNode() {
    skipLogin = true;
    notifyListeners();
  }

  // ---- nodes ---------------------------------------------------------------

  Future<void> addNode(MinerProfile p) async {
    settings.nodes.add(p);
    await _commit();
  }

  Future<void> updateNode(MinerProfile p) async {
    final i = settings.nodes.indexWhere((n) => n.id == p.id);
    if (i < 0) return addNode(p);
    settings.nodes[i] = p;
    _monitors[p.id]?.setProfile(p);
    await _commit();
  }

  Future<void> removeNode(String id) async {
    settings.nodes.removeWhere((n) => n.id == id);
    if (settings.configNodeId == id) settings.configNodeId = null;
    if (settings.nodes.isEmpty) skipLogin = true; // stay in the app, show "add node"
    await _commit();
  }

  // ---- logs ----------------------------------------------------------------

  void _onProcessLine(String raw) {
    final p = parseLogLine(raw);
    if (p.text.isEmpty) return;
    processLog.add(LogEntry(p.level, p.text));
    if (processLog.length > 2000) processLog.removeRange(0, processLog.length - 2000);
    if (p.hint != PoolHint.unknown) logHint = p.hint;
    notifyListeners();
  }

  void clearEvents([String? nodeId]) {
    if (nodeId != null) {
      _monitors[nodeId]?.events.clear();
    } else {
      for (final m in _monitors.values) {
        m.events.clear();
      }
    }
    notifyListeners();
  }

  void clearProcessLog() {
    processLog.clear();
    notifyListeners();
  }

  // ---- local miner (desktop) ----------------------------------------------

  Future<void> startLocal(ConfigForm form) async {
    final err = form.validate();
    if (err != null) throw StateError(err);
    if (settings.exePath.trim().isEmpty) throw StateError('Set the path to the xmrig executable first.');

    final i = settings.nodes.indexWhere((n) => n.id == kLocalNodeId);
    final token = i >= 0 && settings.nodes[i].hasToken ? settings.nodes[i].token : randomToken();
    final config = buildConfig(form, local: true, token: token);

    logHint = PoolHint.unknown;
    _localStartedAt = DateTime.now();
    processLog.add(LogEntry(LogLevel.info, '[app] Starting local xmrig…'));
    await _local.start(settings.exePath.trim(), config);

    final p = MinerProfile(
        id: kLocalNodeId, name: 'This computer', host: '127.0.0.1', port: form.apiPort, token: token);
    if (i >= 0) {
      settings.nodes[i] = p;
      _monitors[kLocalNodeId]?.setProfile(p);
    } else {
      settings.nodes.add(p);
    }
    settings.form = form;
    settings.configNodeId = kLocalNodeId;
    skipLogin = true;
    await _commit();
  }

  Future<void> stopLocal() async {
    await _local.stop();
    processLog.add(LogEntry(LogLevel.info, '[app] Local xmrig stopped'));
    logHint = PoolHint.unknown;
    notifyListeners();
  }

  // ---- config of a chosen node --------------------------------------------

  MinerProfile _profileOf(String id) {
    final m = _monitors[id];
    if (m == null) throw StateError('That node no longer exists.');
    return m.profile;
  }

  Future<Map<String, dynamic>> fetchConfig(String nodeId) async {
    final api = XmrigApi(_profileOf(nodeId));
    try {
      return await api.getConfig();
    } finally {
      api.close();
    }
  }

  /// Merges [form] into the node's current config and uploads it.
  Future<void> pushConfig(String nodeId, ConfigForm form, {Map<String, dynamic>? raw}) async {
    final api = XmrigApi(_profileOf(nodeId));
    try {
      final config = raw ?? buildConfig(form, base: await api.getConfig(), local: false);
      await api.putConfig(config);
    } finally {
      api.close();
    }
    _monitors[nodeId]?._log(LogLevel.info, 'Config sent to the node');
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _logSub?.cancel();
    for (final m in _monitors.values) {
      m.close();
    }
    _local.dispose();
    super.dispose();
  }
}
