import 'package:flutter/material.dart';
import 'package:xmrig_monitor/core/app_info.dart';
import 'package:xmrig_monitor/core/theme/app_palette.dart';
import 'package:xmrig_monitor/core/widgets/app_card.dart';

const List<(String, String)> _terms = [
  ('1. About this app',
      '$kAppName (“the App”) is a free tool made by $kDeveloper (“the Developer”) to view and configure '
          'XMRig miners that you own or are allowed to manage. XMRig is a separate open-source project. '
          'The App is not affiliated with, endorsed by or supported by the XMRig project. The App’s source code '
          'is open source under the MIT License; the license covers use of the code, and these terms cover '
          'use of the App.'),
  ('2. Use at your own risk',
      'The App is provided “as is” and “as available”, without warranties of any kind, express or implied, '
          'including accuracy, reliability, availability, fitness for a particular purpose and non-infringement. '
          'You use the App entirely at your own risk.'),
  ('3. The Developer is not responsible',
      'To the maximum extent permitted by law, the Developer is not responsible or liable for anything that '
          'happens as a result of installing or using the App. This includes, without limitation: loss of funds, '
          'cryptocurrency, earnings or data; damage to, overheating of, wear on or failure of hardware; '
          'electricity, hosting or internet costs; downtime; wrong, missing or delayed statistics '
          '(hashrate, shares, connection status); wrong, lost or overwritten configuration, wallet or pool '
          'settings; security incidents or unauthorized access to your miners, tokens or network; the actions '
          'of pools, wallets, exchanges or other third parties; and any direct, indirect, incidental or '
          'consequential damage of any kind.'),
  ('4. Your responsibilities',
      'You are responsible for: mining only on hardware and networks you own or have explicit permission to '
          'use; following all laws, regulations, tax rules and provider/hosting rules that apply to you; '
          'checking your pool address and wallet address before sending any configuration; keeping access '
          'tokens secret and not exposing a miner’s API to the internet; and keeping backups of your '
          'configuration. Every configuration change you send from the App is your own decision.'),
  ('5. Third-party software and services',
      'The App talks to XMRig miners you add. XMRig, mining pools, networks and wallets are controlled by '
          'third parties. Their terms and policies apply to them, and the Developer has no control over them.'),
  ('6. No promise of earnings',
      'Mining can earn nothing. The App does not promise any income, performance or result.'),
  ('7. Changes',
      'The Developer may change or stop the App, or change these terms, at any time. Continuing to use the '
          'App after a change means you accept the new terms.'),
  ('8. Acceptance',
      'By tapping “I agree” or by using the App you accept these terms. If you do not agree, do not use the App.'),
];

const List<(String, String)> _privacy = [
  ('1. Summary',
      'The App has no accounts, no ads, no analytics and no tracking. The Developer does not collect, receive '
          'or sell your data.'),
  ('2. What is stored on your device',
      'To work, the App stores on your device: the nodes you add (name, IP address or hostname, port, access '
          'token, HTTPS setting), the last pool settings you entered (pool address, wallet address, pool '
          'password, rig ID), the path to your xmrig program, and whether you accepted these terms. This data '
          'is kept in the App’s local storage and is not encrypted by the App, so protect your device with a '
          'lock screen. Removing a node deletes it from the App; uninstalling the App or clearing its data '
          'removes everything.'),
  ('3. Network connections',
      'The App connects only to the nodes you add, using each miner’s HTTP API, to read status and, if you '
          'choose, to send configuration. The miner itself (not the App) connects to your pool. The App does '
          'not send any data to the Developer or to any other server. Connections to a node over plain HTTP '
          'are not encrypted, so use trusted networks or HTTPS.'),
  ('4. Logs and files',
      'Connection events and console output are kept in memory while the App is open. On desktop, when the '
          'App starts xmrig for you, it writes a config file (xmrig_config.json) to its own support folder; '
          'that file contains your pool, wallet and API token details.'),
  ('5. Children',
      'The App is not directed at children.'),
  ('6. Third parties',
      'The App does not include third-party analytics or advertising. XMRig and mining pools have their own '
          'privacy practices.'),
  ('7. Your choices',
      'You can delete any node in the Nodes tab, and delete all App data by clearing its storage or '
          'uninstalling it.'),
  ('8. Responsibility',
      'The Developer is not responsible for data exposed through a lost or compromised device, an unsafe '
          'network, or a miner that is misconfigured (see the Terms of Use).'),
  ('9. Changes and contact',
      'This policy may change with new versions of the App. Developer: $kDeveloper.'),
];

class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.title, required this.sections});
  final String title;
  final List<(String, String)> sections;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = context.tt;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text('$kAppName · $kDeveloper', style: t.titleMedium),
                Text('Last updated: $kLegalUpdated', style: t.bodySmall?.copyWith(color: p.muted)),
                const SizedBox(height: 16),
                for (final (h, b) in sections) ...[
                  AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(h, style: t.titleSmall),
                      const SizedBox(height: 6),
                      Text(b, style: t.bodyMedium?.copyWith(height: 1.45)),
                    ]),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void openTerms(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute<void>(builder: (_) => const LegalPage(title: 'Terms of Use', sections: _terms)));

void openPrivacy(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute<void>(builder: (_) => const LegalPage(title: 'Privacy Policy', sections: _privacy)));
