import 'package:flutter/material.dart';
import 'package:xmrig_monitor/core/theme/app_palette.dart';
import 'package:xmrig_monitor/core/widgets/app_card.dart';
import 'package:xmrig_monitor/core/widgets/empty_state.dart';
import 'package:xmrig_monitor/core/widgets/page_body.dart';
import 'package:xmrig_monitor/core/widgets/section_header.dart';
import 'package:xmrig_monitor/core/widgets/status_pill.dart';
import 'package:xmrig_monitor/features/nodes/node_form.dart';
import 'package:xmrig_monitor/features/shared/node_status.dart';
import 'package:xmrig_monitor/state/monitor_controller.dart';

class NodesPage extends StatelessWidget {
  const NodesPage(this.c, {super.key});
  final MonitorController c;

  Future<void> _remove(BuildContext context, NodeMonitor m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove node?'),
        content: Text('“${m.profile.name}” (${m.profile.host}) will be removed from this app. '
            'The miner itself keeps running.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) await c.removeNode(m.profile.id);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final nodes = c.monitors;
    final addButton = FilledButton.icon(
      onPressed: () => showNodeDialog(context, c),
      icon: const Icon(Icons.add),
      label: const Text('Add node'),
    );

    if (nodes.isEmpty) {
      return EmptyState(
        icon: Icons.dns_outlined,
        title: 'No nodes yet',
        message: 'A node is one miner. Add as many as you like — the dashboard adds them together.',
        action: addButton,
      );
    }

    return PageBody(maxWidth: 760, children: [
      SectionHeader('Nodes',
          subtitle: '${nodes.length} connected miner${nodes.length == 1 ? '' : 's'}', trailing: addButton),
      for (final m in nodes) ...[
        Builder(builder: (context) {
          final st = nodeStatus(context, c, m);
          return AppCard(
            child: Row(children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: st.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(st.icon, color: st.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.profile.name, style: context.tt.titleMedium),
                  Text('${m.profile.host}:${m.profile.port}',
                      style: context.tt.bodySmall?.copyWith(color: p.muted)),
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerLeft, child: StatusPill(st.label, st.color)),
                ]),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') showNodeDialog(context, c, initial: m.profile);
                  if (v == 'remove') _remove(context, m);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'remove', child: Text('Remove')),
                ],
              ),
            ]),
          );
        }),
        const SizedBox(height: 10),
      ],
    ]);
  }
}
