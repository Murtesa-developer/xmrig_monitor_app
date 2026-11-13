import 'package:flutter/material.dart';
import 'package:xmrig_monitor/core/app_info.dart';
import 'package:xmrig_monitor/core/theme/app_palette.dart';
import 'package:xmrig_monitor/core/widgets/brand_mark.dart';
import 'package:xmrig_monitor/features/about/legal_pages.dart';
import 'package:xmrig_monitor/features/nodes/node_form.dart';
import 'package:xmrig_monitor/features/onboarding/auth_scaffold.dart';
import 'package:xmrig_monitor/state/monitor_controller.dart';

/// Shown when there are no nodes yet: asks for the first node's IP.
class LoginPage extends StatelessWidget {
  const LoginPage(this.c, {super.key});
  final MonitorController c;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = context.tt;
    return AuthScaffold(children: [
      const Center(child: BrandMark(size: 64)),
      const SizedBox(height: 16),
      Text(kAppName, textAlign: TextAlign.center, style: t.headlineSmall),
      const SizedBox(height: 4),
      Text('Add your first node. You can add more later.',
          textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: p.muted)),
      const SizedBox(height: 24),
      NodeForm(onSave: c.addNode),
      if (c.localSupported) ...[
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: c.enterWithoutNode,
          icon: const Icon(Icons.computer),
          label: const Text('Run xmrig on this computer instead'),
        ),
      ],
      const SizedBox(height: 20),
      Text('Developed by $kDeveloper',
          textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: p.muted)),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        TextButton(onPressed: () => openTerms(context), child: const Text('Terms')),
        TextButton(onPressed: () => openPrivacy(context), child: const Text('Privacy')),
      ]),
    ]);
  }
}
