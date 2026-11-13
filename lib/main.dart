import 'package:flutter/material.dart';
import 'package:xmrig_monitor/app.dart';
import 'package:xmrig_monitor/data/services/settings_store.dart';
import 'package:xmrig_monitor/state/monitor_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await SettingsStore.load();
  final controller = MonitorController(settings)..start();
  runApp(XmrigMonitorApp(controller));
}
