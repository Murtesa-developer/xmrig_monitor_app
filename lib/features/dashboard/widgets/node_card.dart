import 'package:flutter/material.dart';
import 'package:xmrig_monitor/core/theme/app_palette.dart';
import 'package:xmrig_monitor/core/theme/app_theme.dart';
import 'package:xmrig_monitor/core/utils/format.dart';
import 'package:xmrig_monitor/core/widgets/app_card.dart';
import 'package:xmrig_monitor/core/widgets/sparkline.dart';
import 'package:xmrig_monitor/core/widgets/stat_tile.dart';
import 'package:xmrig_monitor/core/widgets/status_pill.dart';
import 'package:xmrig_monitor/features/shared/node_status.dart';
import 'package:xmrig_monitor/state/monitor_controller.dart';

/// One worker (node). Tap to expand all of its stats.
class NodeCard extends StatefulWidget {
  const NodeCard(this.c, this.m, {super.key});
  final MonitorController c;
  final NodeMonitor m;

  @override
  State<NodeCard> createState() => _NodeCardState();
}

class _NodeCardState extends State<NodeCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = context.tt;
    final m = widget.m;
    final st = nodeStatus(context, widget.c, m);
    final s = m.summary;
    final online = m.online && s != null;

    return AppCard(
      onTap: online ? () => setState(() => _open = !_open) : null,
      borderColor: online ? null : st.color.withValues(alpha: 0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: st.color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: st.color.withValues(alpha: 0.6), blurRadius: 8)],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.profile.name, style: t.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text('Node IP ${m.profile.host}', style: t.bodySmall?.copyWith(color: p.muted)),
              ]),
            ),
            if (online) ...[
              Text(fmtHash(m.hashrate), style: numStyle(t.titleMedium)),
              const SizedBox(width: 4),
              Icon(_open ? Icons.expand_less : Icons.expand_more, color: p.muted),
            ],
          ]),
          const SizedBox(height: 10),
          Align(alignment: Alignment.centerLeft, child: StatusPill(st.label, st.color, icon: st.icon)),
          if (!online && m.lastError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(m.lastError!, style: t.bodySmall?.copyWith(color: p.muted)),
            ),
          if (s != null && online) ...[
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _Mini('Accepted', '${s.accepted}', color: p.good)),
              Expanded(child: _Mini('Rejected', '${s.rejected}', color: s.rejected > 0 ? p.warn : null)),
              Expanded(child: _Mini('Accept rate', fmtPercent(s.acceptRate))),
              Expanded(child: _Mini('Last share', fmtAgo(m.lastAcceptedAt))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(flex: 2, child: _Mini('Pool', s.pool.isEmpty ? 'none' : s.pool)),
              Expanded(child: _Mini('Ping', s.poolConnected ? '${s.ping} ms' : '—')),
            ]),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _open
                  ? Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Column(children: [
                        Sparkline(m.history, height: 56, color: st.color),
                        const SizedBox(height: 12),
                        StatGrid(minTileWidth: 130, children: [
                          StatTile('10 s', fmtHash(s.hr10s)),
                          StatTile('60 s', fmtHash(s.hr60s)),
                          StatTile('15 min', fmtHash(s.hr15m)),
                          StatTile('Avg share time', s.avgTimeMs > 0 ? '${(s.avgTimeMs / 1000).toStringAsFixed(1)} s' : '—'),
                          StatTile('Total hashes', '${s.hashesTotal}'),
                          StatTile('Failures', '${s.failures}'),
                          StatTile('Uptime', fmtDuration(s.uptime)),
                          StatTile('Algorithm', s.algo.isEmpty ? '—' : s.algo),
                          StatTile('Worker', s.workerId.isEmpty ? '—' : s.workerId),
                          StatTile('Version', s.version),
                          StatTile('CPU', s.cpuBrand.isEmpty ? '—' : s.cpuBrand),
                          StatTile('Config', s.restricted ? 'read-only' : 'editable'),
                        ]),
                      ]),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.label, this.value, {this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: context.tt.labelMedium?.copyWith(color: context.pal.muted)),
        const SizedBox(height: 2),
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: numStyle(context.tt.bodyMedium)
            .copyWith(fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}
