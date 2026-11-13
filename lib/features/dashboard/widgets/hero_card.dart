import 'package:flutter/material.dart';
import 'package:xmrig_monitor/core/theme/app_palette.dart';
import 'package:xmrig_monitor/core/theme/app_theme.dart';
import 'package:xmrig_monitor/core/utils/format.dart';
import 'package:xmrig_monitor/core/widgets/sparkline.dart';
import 'package:xmrig_monitor/state/monitor_controller.dart';

/// The big gradient card at the top of the dashboard: total hashrate.
class HeroCard extends StatelessWidget {
  const HeroCard(this.c, {super.key});
  final MonitorController c;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = context.tt;
    final total = c.monitors.length;
    final online = c.onlineCount;
    final pool = c.poolCount;
    final parts = hashParts(c.totalHashrate);

    final String pill;
    if (total > 0 && pool == total) {
      pill = total == 1 ? 'Connected' : 'All connected';
    } else if (pool > 0) {
      pill = '$pool of $total connected';
    } else if (online > 0) {
      pill = 'Not connected to pool';
    } else {
      pill = 'Offline';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.heroStart, p.heroEnd],
        ),
        boxShadow: [
          BoxShadow(color: p.heroStart.withValues(alpha: 0.28), blurRadius: 28, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('TOTAL HASHRATE',
                  style: t.labelMedium?.copyWith(color: Colors.white70, letterSpacing: 1.2)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(pill, style: t.labelMedium?.copyWith(color: Colors.white)),
            ),
          ]),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  parts.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: numStyle(t.displayMedium)
                      .copyWith(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: -1),
                ),
              ),
              const SizedBox(width: 8),
              Text(parts.unit, style: t.titleMedium?.copyWith(color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 4),
          Text('$online of $total nodes online · $pool connected to pool',
              style: t.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9))),
          const SizedBox(height: 2),
          Text(
            '${c.totalAccepted} shares accepted · ${fmtPercent(c.acceptRate)} accept rate',
            style: t.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: 12),
          Sparkline(c.totalHistory, height: 64, color: Colors.white),
        ],
      ),
    );
  }
}
