import 'package:flutter/material.dart';
import 'package:xmrig_monitor/core/app_info.dart';
import 'package:xmrig_monitor/core/theme/app_palette.dart';
import 'package:xmrig_monitor/core/widgets/app_card.dart';
import 'package:xmrig_monitor/core/widgets/brand_mark.dart';
import 'package:xmrig_monitor/core/widgets/page_body.dart';
import 'package:xmrig_monitor/core/widgets/status_pill.dart';
import 'package:xmrig_monitor/features/about/legal_pages.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = context.tt;
    return PageBody(maxWidth: 560, children: [
      const SizedBox(height: 12),
      const Center(child: BrandMark(size: 76)),
      const SizedBox(height: 16),
      Text(kAppName, textAlign: TextAlign.center, style: t.headlineMedium),
      const SizedBox(height: 8),
      Center(child: StatusPill('Version $kAppVersion', context.cs.primary)),
      const SizedBox(height: 24),
      AppCard(
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: p.cardAlt, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.code),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Developed by', style: t.labelMedium?.copyWith(color: p.muted)),
              Text(kDeveloper, style: t.titleMedium),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      AppCard(
        child: Text(
          'Monitor many XMRig miners in one place: total hashrate, every worker’s status, pool connection, '
          'shares, logs and pool settings. Works on Android, iOS, web, Windows, macOS and Linux.\n\n'
          'Works with XMRig (GPL-3.0) through its HTTP API. This app is not affiliated with or endorsed by '
          'the XMRig project.',
          style: t.bodyMedium?.copyWith(height: 1.45),
        ),
      ),
      const SizedBox(height: 12),
      AppCard(
        color: p.bad.withValues(alpha: 0.10),
        borderColor: p.bad.withValues(alpha: 0.4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.warning_amber_rounded, color: p.bad),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Use at your own risk. $kDeveloper is not responsible for anything that happens from '
              'installing or using this app.',
              style: t.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      AppCard(
        padding: EdgeInsets.zero,
        child: Column(children: [
          _Row(Icons.description_outlined, 'Terms of Use', () => openTerms(context)),
          Divider(color: p.border),
          _Row(Icons.privacy_tip_outlined, 'Privacy Policy', () => openPrivacy(context)),
          Divider(color: p.border),
          _Row(
            Icons.article_outlined,
            'Open-source licenses',
            () => showLicensePage(
              context: context,
              applicationName: kAppName,
              applicationVersion: kAppVersion,
              applicationLegalese: 'Developed by $kDeveloper',
            ),
          ),
        ]),
      ),
      const SizedBox(height: 20),
      Text('© $kDeveloper', textAlign: TextAlign.center, style: t.bodySmall?.copyWith(color: p.muted)),
    ]);
  }
}

class _Row extends StatelessWidget {
  const _Row(this.icon, this.label, this.onTap);
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      );
}
