import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xmrig_monitor/core/theme/app_palette.dart';
import 'package:xmrig_monitor/core/utils/format.dart';
import 'package:xmrig_monitor/core/widgets/status_pill.dart';
import 'package:xmrig_monitor/data/services/log_parser.dart';
import 'package:xmrig_monitor/state/monitor_controller.dart';

class LogsPage extends StatefulWidget {
  const LogsPage(this.c, {super.key});
  final MonitorController c;

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  String? _nodeId; // null = all nodes
  int _tab = 1; // 0 = miner output, 1 = connection events
  bool _tabChosen = false;

  MonitorController get c => widget.c;

  List<LogEntry> _events() {
    if (_nodeId != null) return c.monitorFor(_nodeId!)?.events ?? <LogEntry>[];
    final all = <LogEntry>[
      for (final m in c.monitors)
        for (final e in m.events) LogEntry(e.level, '[${m.profile.name}] ${e.text}', time: e.time),
    ];
    all.sort((a, b) => a.time.compareTo(b.time));
    return all;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    if (_nodeId != null && c.monitorFor(_nodeId!) == null) _nodeId = null;
    if (!_tabChosen && c.localSupported && c.localRunning) _tab = 0;
    final nodes = c.monitors;

    String label;
    Color color;
    if (_nodeId != null) {
      switch (c.poolStatusOf(c.monitorFor(_nodeId!)!)) {
        case PoolHint.connected:
          (label, color) = ('Pool connected', p.good);
        case PoolHint.disconnected:
          (label, color) = ('Pool not connected', p.bad);
        case PoolHint.unknown:
          (label, color) = ('Pool unknown', p.muted);
      }
    } else {
      final ok = c.poolCount;
      (label, color) = (
        'Pools connected $ok / ${nodes.length}',
        ok == nodes.length && ok > 0 ? p.good : (ok > 0 ? p.warn : p.bad),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Row(children: [
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Node', contentPadding: EdgeInsets.fromLTRB(14, 4, 8, 4)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        isExpanded: true,
                        value: _nodeId,
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('All nodes')),
                          for (final m in nodes)
                            DropdownMenuItem<String?>(value: m.profile.id, child: Text(m.profile.name)),
                        ],
                        onChanged: (v) => setState(() => _nodeId = v),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                StatusPill(label, color),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 0, icon: Icon(Icons.terminal), label: Text('Miner output')),
                    ButtonSegment(value: 1, icon: Icon(Icons.timeline), label: Text('Events')),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (s) => setState(() {
                    _tab = s.first;
                    _tabChosen = true;
                  }),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _tab == 0
                    ? (c.localSupported
                        ? LogList(
                            key: const ValueKey('output'),
                            entries: c.processLog,
                            onClear: c.clearProcessLog,
                            empty: 'No output yet.\nStart the miner on this computer from the Config tab.')
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Live console output is available on Windows, macOS and Linux, where the app '
                                'starts xmrig itself. On this device use “Events” — they are built from each '
                                'node’s HTTP API.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: p.muted),
                              ),
                            ),
                          ))
                    : LogList(
                        key: const ValueKey('events'),
                        entries: _events(),
                        onClear: () => c.clearEvents(_nodeId),
                        empty: 'No events yet.'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Terminal-style list with follow / copy / clear controls.
class LogList extends StatefulWidget {
  const LogList({super.key, required this.entries, required this.onClear, required this.empty});
  final List<LogEntry> entries;
  final VoidCallback onClear;
  final String empty;

  @override
  State<LogList> createState() => _LogListState();
}

class _LogListState extends State<LogList> {
  final _scroll = ScrollController();
  bool _follow = true;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Color _color(LogLevel l, AppPalette p) => switch (l) {
        LogLevel.good => p.good,
        LogLevel.warn => p.warn,
        LogLevel.error => p.bad,
        LogLevel.info => const Color(0xFFD7DCE3),
      };

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final entries = widget.entries;
    if (_follow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
      });
    }
    const dim = Color(0xFF6B7684);
    return Container(
      decoration: BoxDecoration(
        color: p.terminal,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
            child: Row(children: [
              Text('${entries.length} lines', style: const TextStyle(color: dim, fontSize: 12)),
              const Spacer(),
              const Text('Follow', style: TextStyle(color: dim, fontSize: 12)),
              Switch(value: _follow, onChanged: (v) => setState(() => _follow = v)),
              IconButton(
                tooltip: 'Copy all',
                color: dim,
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () => Clipboard.setData(
                    ClipboardData(text: entries.map((e) => '${fmtTime(e.time)} ${e.text}').join('\n'))),
              ),
              IconButton(
                tooltip: 'Clear',
                color: dim,
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: widget.onClear,
              ),
            ]),
          ),
          Divider(height: 1, color: p.border),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(widget.empty, textAlign: TextAlign.center, style: const TextStyle(color: dim)))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: entries.length,
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1.5),
                        child: SelectableText.rich(
                          TextSpan(children: [
                            TextSpan(text: '${fmtTime(e.time)}  ', style: const TextStyle(color: dim)),
                            TextSpan(text: e.text, style: TextStyle(color: _color(e.level, p))),
                          ]),
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.35),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
