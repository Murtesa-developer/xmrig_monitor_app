import 'package:flutter/material.dart';
import 'package:xmrig_monitor/core/theme/app_palette.dart';
import 'package:xmrig_monitor/data/services/log_parser.dart';
import 'package:xmrig_monitor/state/monitor_controller.dart';

class NodeStatus {
  const NodeStatus(this.color, this.icon, this.label);
  final Color color;
  final IconData icon;
  final String label;
}

NodeStatus nodeStatus(BuildContext context, MonitorController c, NodeMonitor m) {
  final p = context.pal;
  final cs = context.cs;
  switch (m.state) {
    case LinkState.mining:
      return NodeStatus(p.good, Icons.check_circle, 'Connected to pool');
    case LinkState.poolDisconnected:
      return NodeStatus(p.warn, Icons.link_off, 'Online · not connected to pool');
    case LinkState.paused:
      return NodeStatus(p.warn, Icons.pause_circle, 'Paused');
    case LinkState.connecting:
      return NodeStatus(cs.primary, Icons.sync, 'Connecting…');
    case LinkState.authError:
      return NodeStatus(p.bad, Icons.lock, 'Access token rejected');
    case LinkState.notConfigured:
      return NodeStatus(p.muted, Icons.help_outline, 'Not set up');
    case LinkState.apiUnreachable:
      switch (c.poolStatusOf(m)) {
        case PoolHint.connected:
          return NodeStatus(p.warn, Icons.link, 'Pool connected (miner log) · API unreachable');
        case PoolHint.disconnected:
          return NodeStatus(p.bad, Icons.link_off, 'Not connected to pool (miner log)');
        case PoolHint.unknown:
          return NodeStatus(p.bad, Icons.cloud_off, 'Cannot reach node');
      }
  }
}
