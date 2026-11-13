import 'package:flutter/material.dart';
import 'package:xmrig_monitor/core/app_info.dart';
import 'package:xmrig_monitor/core/theme/app_palette.dart';
import 'package:xmrig_monitor/core/widgets/brand_mark.dart';
import 'package:xmrig_monitor/core/widgets/status_pill.dart';
import 'package:xmrig_monitor/features/about/about_page.dart';
import 'package:xmrig_monitor/features/config/config_page.dart';
import 'package:xmrig_monitor/features/dashboard/dashboard_page.dart';
import 'package:xmrig_monitor/features/logs/logs_page.dart';
import 'package:xmrig_monitor/features/nodes/nodes_page.dart';
import 'package:xmrig_monitor/state/monitor_controller.dart';

class AppShell extends StatefulWidget {
  const AppShell(this.c, {super.key});
  final MonitorController c;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Desktop user who chose "run xmrig here" with no node yet starts on Config.
  late int _index = widget.c.monitors.isEmpty && widget.c.localSupported ? 3 : 0;

  static const _dest = [
    (Icons.space_dashboard_outlined, Icons.space_dashboard, 'Dashboard'),
    (Icons.dns_outlined, Icons.dns, 'Nodes'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Logs'),
    (Icons.tune_outlined, Icons.tune, 'Config'),
    (Icons.info_outline, Icons.info, 'About'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.c,
      builder: (context, _) {
        final c = widget.c;
        final p = context.pal;
        final pages = <Widget>[
          DashboardPage(c, onAddNode: () => setState(() => _index = 1)),
          NodesPage(c),
          LogsPage(c),
          ConfigPage(c),
          const AboutPage(),
        ];
        final width = MediaQuery.sizeOf(context).width;
        final wide = width >= 860;
        final extended = width >= 1180;
        final body = IndexedStack(index: _index, children: pages);

        final total = c.monitors.length;
        final online = c.onlineCount;
        final live = total == 0
            ? null
            : StatusPill(
                '$online / $total online',
                online == total ? p.good : (online > 0 ? p.warn : p.bad),
              );

        return Scaffold(
          appBar: AppBar(
            title: Text(_dest[_index].$3),
            actions: [if (live != null) Padding(padding: const EdgeInsets.only(right: 16), child: live)],
          ),
          body: wide
              ? Row(children: [
                  NavigationRail(
                    extended: extended,
                    selectedIndex: _index,
                    labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                    onDestinationSelected: (i) => setState(() => _index = i),
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: extended
                          ? Row(mainAxisSize: MainAxisSize.min, children: [
                              const BrandMark(size: 36),
                              const SizedBox(width: 10),
                              Text(kAppName, style: context.tt.titleSmall),
                            ])
                          : const BrandMark(size: 36),
                    ),
                    destinations: [
                      for (final d in _dest)
                        NavigationRailDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: Text(d.$3)),
                    ],
                  ),
                  VerticalDivider(width: 1, color: p.border),
                  Expanded(child: body),
                ])
              : body,
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: [
                    for (final d in _dest)
                      NavigationDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: d.$3),
                  ],
                ),
        );
      },
    );
  }
}
