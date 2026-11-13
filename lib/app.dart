import 'package:flutter/material.dart';
import 'package:xmrig_monitor/core/app_info.dart';
import 'package:xmrig_monitor/core/theme/app_theme.dart';
import 'package:xmrig_monitor/features/onboarding/login_page.dart';
import 'package:xmrig_monitor/features/onboarding/terms_gate_page.dart';
import 'package:xmrig_monitor/features/shell/app_shell.dart';
import 'package:xmrig_monitor/state/monitor_controller.dart';

class XmrigMonitorApp extends StatelessWidget {
  const XmrigMonitorApp(this.controller, {super.key});
  final MonitorController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (!controller.settings.acceptedTerms) return TermsGatePage(controller);
          if (controller.monitors.isEmpty && !controller.skipLogin) return LoginPage(controller);
          return AppShell(controller);
        },
      ),
    );
  }
}
