import 'package:flutter/material.dart';
import 'package:xmrig_monitor/core/app_info.dart';
import 'package:xmrig_monitor/core/theme/app_palette.dart';
import 'package:xmrig_monitor/core/widgets/brand_mark.dart';
import 'package:xmrig_monitor/features/about/legal_pages.dart';
import 'package:xmrig_monitor/features/onboarding/auth_scaffold.dart';
import 'package:xmrig_monitor/state/monitor_controller.dart';

/// First-run screen: the user must accept the Terms and Privacy Policy.
class TermsGatePage extends StatefulWidget {
  const TermsGatePage(this.c, {super.key});
  final MonitorController c;

  @override
  State<TermsGatePage> createState() => _TermsGatePageState();
}

class _TermsGatePageState extends State<TermsGatePage> {
  bool _agree = false;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = context.tt;
    return AuthScaffold(children: [
      const Center(child: BrandMark(size: 64)),
      const SizedBox(height: 16),
      Text('Before you start', textAlign: TextAlign.center, style: t.headlineSmall),
      const SizedBox(height: 12),
      Text(
        '$kAppName is made by $kDeveloper. You use it at your own risk: $kDeveloper is not responsible for '
        'anything that happens when you install or use it — including lost earnings, hardware damage, costs '
        'or security problems.',
        textAlign: TextAlign.center,
        style: t.bodyMedium?.copyWith(color: p.muted, height: 1.45),
      ),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        TextButton(onPressed: () => openTerms(context), child: const Text('Terms of Use')),
        TextButton(onPressed: () => openPrivacy(context), child: const Text('Privacy Policy')),
      ]),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        value: _agree,
        onChanged: (v) => setState(() => _agree = v ?? false),
        title: const Text('I have read and agree to the Terms of Use and Privacy Policy.'),
      ),
      const SizedBox(height: 8),
      FilledButton(onPressed: _agree ? widget.c.acceptTerms : null, child: const Text('Continue')),
    ]);
  }
}
