import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:xmrig_monitor/data/models/profile.dart';
import 'package:xmrig_monitor/data/services/config_builder.dart';

class AppSettings {
  AppSettings({
    List<MinerProfile>? nodes,
    ConfigForm? form,
    this.exePath = '',
    this.acceptedTerms = false,
    this.configNodeId,
  })  : nodes = nodes ?? [],
        form = form ?? ConfigForm();

  List<MinerProfile> nodes;
  ConfigForm form; // last pool settings used to start a local miner
  String exePath;
  bool acceptedTerms;
  String? configNodeId; // node last chosen in the Config tab

  Map<String, dynamic> toJson() => {
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'form': form.toJson(),
        'exePath': exePath,
        'acceptedTerms': acceptedTerms,
        'configNodeId': configNodeId,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) {
    var nodes = <MinerProfile>[];
    if (j['nodes'] is List) {
      nodes = (j['nodes'] as List)
          .whereType<Map>()
          .map((e) => MinerProfile.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else if (j['profile'] is Map) {
      // migrate the single connection saved by version 1
      final p = MinerProfile.fromJson(Map<String, dynamic>.from(j['profile'] as Map));
      if (p.host.isNotEmpty) nodes = [p];
    }
    return AppSettings(
      nodes: nodes,
      form: j['form'] is Map ? ConfigForm.fromJson(Map<String, dynamic>.from(j['form'] as Map)) : null,
      exePath: j['exePath'] as String? ?? '',
      acceptedTerms: j['acceptedTerms'] as bool? ?? false,
      configNodeId: j['configNodeId'] as String?,
    );
  }
}

class SettingsStore {
  static const _key = 'xmrig_monitor_settings_v1';

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return AppSettings();
    }
  }

  static Future<void> save(AppSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(s.toJson()));
  }
}
