import 'package:flutter/material.dart';
import 'package:xmrig_monitor/core/theme/app_palette.dart';
import 'package:xmrig_monitor/core/utils/format.dart';
import 'package:xmrig_monitor/core/widgets/empty_state.dart';
import 'package:xmrig_monitor/core/widgets/page_body.dart';
import 'package:xmrig_monitor/core/widgets/section_header.dart';
import 'package:xmrig_monitor/core/widgets/stat_tile.dart';
import 'package:xmrig_monitor/features/dashboard/widgets/hero_card.dart';
import 'package:xmrig_monitor/features/dashboard/widgets/node_card.dart';
import 'package:xmrig_monitor/state/monitor_controller.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage(this.c, {super.key, this.onAddNode});
  final MonitorController c;
  final VoidCallback? onAddNode;

  @override
  Widget build(BuildContext context) {
    final nodes = c.monitors;
    if (nodes.isEmpty) {
      return EmptyState(
        icon: Icons.dns_outlined,
        title: 'No nodes yet',
        message: 'Add the miner nodes you want to watch.',
        action: FilledButton.icon(onPressed: onAddNode, icon: const Icon(Icons.add), label: const Text('Add node')),
      );
    }
    final p = context.pal;
    return PageBody(children: [
      HeroCard(c),
      const SizedBox(height: 14),
      StatGrid(minTileWidth: 150, children: [
        StatTile('Nodes online', '${c.onlineCount} / ${nodes.length}',
            valueColor: c.onlineCount == nodes.length ? p.good : p.warn),
        StatTile('Connected to pool', '${c.poolCount} / ${nodes.length}',
            valueColor: c.poolCount == nodes.length ? p.good : p.warn),
        StatTile('Shares accepted', '${c.totalAccepted}', valueColor: p.good),
        StatTile('Shares rejected', '${c.totalRejected}',
            valueColor: c.totalRejected > 0 ? p.warn : null),
        StatTile('Accept rate', fmtPercent(c.acceptRate)),
      ]),
      const SizedBox(height: 12),
      SectionHeader('Workers', subtitle: 'Tap a card for full details'),
      LayoutBuilder(builder: (context, box) {
        const gap = 12.0;
        final cols = box.maxWidth >= 760 ? 2 : 1;
        final w = (box.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final m in nodes) SizedBox(width: w, child: NodeCard(c, m))],
        );
      }),
    ]);
  }
}
