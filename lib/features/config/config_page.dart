import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:xmrig_monitor/core/theme/app_palette.dart';
import 'package:xmrig_monitor/core/widgets/app_card.dart';
import 'package:xmrig_monitor/core/widgets/page_body.dart';
import 'package:xmrig_monitor/core/widgets/section_header.dart';
import 'package:xmrig_monitor/data/services/config_builder.dart';
import 'package:xmrig_monitor/state/monitor_controller.dart';

const _kNewLocal = '__new_local__';

class ConfigPage extends StatefulWidget {
  const ConfigPage(this.c, {super.key});
  final MonitorController c;

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  MonitorController get c => widget.c;

  ConfigForm f = ConfigForm();
  String? _nodeId;
  Map<String, dynamic>? _loaded; // config as fetched from the chosen node
  Map<String, dynamic>? _rawOverride;
  String? _status;
  bool _statusErr = false;
  bool _busy = false;

  final _pool = TextEditingController();
  final _wallet = TextEditingController();
  final _pass = TextEditingController();
  final _rig = TextEditingController();
  final _algo = TextEditingController();
  final _port = TextEditingController();
  late final _exe = TextEditingController(text: c.settings.exePath);

  @override
  void initState() {
    super.initState();
    final last = c.settings.configNodeId;
    if (last != null && c.monitorFor(last) != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _select(last));
    }
  }

  @override
  void dispose() {
    for (final t in [_pool, _wallet, _pass, _rig, _algo, _port, _exe]) {
      t.dispose();
    }
    super.dispose();
  }

  void _readFields() {
    f.poolUrl = _pool.text;
    f.wallet = _wallet.text;
    f.password = _pass.text;
    f.rigId = _rig.text;
    f.algo = _algo.text;
    f.apiPort = int.tryParse(_port.text) ?? 0;
    c.settings.exePath = _exe.text;
  }

  void _writeFields() {
    _pool.text = f.poolUrl;
    _wallet.text = f.wallet;
    _pass.text = f.password;
    _rig.text = f.rigId;
    _algo.text = f.algo;
    _port.text = '${f.apiPort}';
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  /// The node the user picked, or null if none / it was removed.
  String? get _sel {
    final id = _nodeId;
    if (id == null) return null;
    if (id == _kNewLocal) return c.monitorFor(kLocalNodeId) == null ? id : null;
    return c.monitorFor(id) == null ? null : id;
  }

  Future<void> _select(String? id) async {
    setState(() {
      _nodeId = id;
      _loaded = null;
      _rawOverride = null;
      _status = null;
      _statusErr = false;
    });
    if (id == null) return;
    if (id == _kNewLocal) {
      f = ConfigForm.fromJson(c.settings.form.toJson());
      _writeFields();
      setState(() {});
      return;
    }
    c.settings.configNodeId = id;
    c.saveSettings();
    await _loadFromNode(id);
  }

  Future<void> _loadFromNode(String id) async {
    final name = c.monitorFor(id)?.profile.name ?? 'node';
    setState(() {
      _busy = true;
      _status = 'Loading pool settings from $name…';
      _statusErr = false;
    });
    try {
      final cfg = await c.fetchConfig(id);
      if (!mounted || _nodeId != id) return;
      f = ConfigForm()..loadFrom(cfg);
      _loaded = cfg;
      _writeFields();
      _status = 'Pool settings loaded from $name.';
    } catch (e) {
      if (!mounted || _nodeId != id) return;
      _status = '${e.toString().replaceFirst('Bad state: ', '')}\n'
          'Pool data could not be loaded. If the token is right, the node is probably read-only — '
          'start xmrig with --http-no-restricted (and an access token).';
      _statusErr = true;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _push() async {
    final id = _sel;
    if (id == null || id == _kNewLocal) return;
    setState(() => _busy = true);
    try {
      _readFields();
      final err = f.validate();
      if (err != null) throw StateError(err);
      await c.pushConfig(id, f, raw: _rawOverride);
      _rawOverride = null;
      _toast('Config sent. XMRig applies it automatically.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _startLocal() async {
    setState(() => _busy = true);
    try {
      _readFields();
      _rawOverride = null;
      await c.startLocal(f);
      if (!mounted) return;
      setState(() {
        _nodeId = kLocalNodeId;
        _loaded = null;
        _status = 'Miner started. Give it a few seconds, then press Reload to read its settings.';
        _statusErr = false;
      });
      _toast('Miner started — watch the Dashboard and Logs tabs.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stopLocal() async {
    setState(() => _busy = true);
    try {
      await c.stopLocal();
      _toast('Miner stopped.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editRaw() async {
    _readFields();
    final base = buildConfig(f, base: _rawOverride ?? _loaded, local: false);
    final text = TextEditingController(text: const JsonEncoder.withIndent('  ').convert(base));
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Raw config.json'),
        content: SizedBox(
          width: 600,
          child: TextField(
            controller: text,
            maxLines: 20,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              try {
                Navigator.pop(ctx, jsonDecode(text.text) as Map<String, dynamic>);
              } catch (_) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Invalid JSON')));
              }
            },
            child: const Text('Use this'),
          ),
        ],
      ),
    );
    text.dispose();
    if (result != null) {
      _rawOverride = result;
      f.loadFrom(result);
      _writeFields();
      setState(() {});
      _toast('Raw config will be used for “Send to node”.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final sel = _sel;
    final nodes = c.monitors;
    final isLocalSel = sel == _kNewLocal || sel == kLocalNodeId;
    final isRemote = sel != null && sel != _kNewLocal;
    const gap = SizedBox(height: 12);

    final items = <DropdownMenuItem<String>>[
      for (final m in nodes)
        DropdownMenuItem(value: m.profile.id, child: Text('${m.profile.name} (${m.profile.host})')),
      if (c.localSupported && c.monitorFor(kLocalNodeId) == null)
        const DropdownMenuItem(value: _kNewLocal, child: Text('＋ New miner on this computer')),
    ];

    return PageBody(maxWidth: 760, children: [
      const SectionHeader('Config', subtitle: 'Choose a node, then edit its pool settings'),
      // ---- 1. node --------------------------------------------------------
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Node', style: context.tt.titleMedium),
          gap,
          InputDecorator(
            decoration: const InputDecoration(contentPadding: EdgeInsets.fromLTRB(14, 4, 8, 4)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: sel,
                hint: const Text('Select the node to configure'),
                items: items,
                onChanged: _busy ? null : _select,
              ),
            ),
          ),
          if (sel == null) ...[
            gap,
            Text(
              nodes.isEmpty && !c.localSupported
                  ? 'Add a node first in the Nodes tab.'
                  : 'Pick a node to see and change its pool settings.',
              style: TextStyle(color: p.muted),
            ),
          ],
          if (_status != null) ...[
            gap,
            Text(_status!, style: TextStyle(color: _statusErr ? p.bad : p.muted)),
          ],
        ]),
      ),
      if (sel != null) ...[
        const SizedBox(height: 14),
        // ---- 2. pool ------------------------------------------------------
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Pool', style: context.tt.titleMedium),
            gap,
            TextField(
              controller: _pool,
              decoration: const InputDecoration(labelText: 'Pool address', hintText: 'host:port'),
            ),
            gap,
            TextField(controller: _wallet, decoration: const InputDecoration(labelText: 'Wallet address (pool user)')),
            gap,
            Row(children: [
              Expanded(child: TextField(controller: _pass, decoration: const InputDecoration(labelText: 'Pool password'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _rig, decoration: const InputDecoration(labelText: 'Rig ID (optional)'))),
            ]),
            gap,
            TextField(
              controller: _algo,
              decoration: const InputDecoration(labelText: 'Algorithm (optional)', hintText: 'e.g. rx/0'),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        // ---- 3. performance -----------------------------------------------
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Options', style: context.tt.titleMedium),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('TLS'),
              value: f.tls,
              onChanged: (v) => setState(() => f.tls = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Keepalive'),
              value: f.keepalive,
              onChanged: (v) => setState(() => f.keepalive = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Huge pages'),
              value: f.hugePages,
              onChanged: (v) => setState(() => f.hugePages = v),
            ),
            const SizedBox(height: 4),
            Row(children: [
              const Expanded(child: Text('CPU usage')),
              Text('${f.threadsHint}%', style: context.tt.titleSmall),
            ]),
            Slider(
              min: 10,
              max: 100,
              divisions: 9,
              value: f.threadsHint.toDouble().clamp(10, 100),
              label: '${f.threadsHint}%',
              onChanged: (v) => setState(() => f.threadsHint = v.round()),
            ),
          ]),
        ),
        if (isRemote) ...[
          const SizedBox(height: 14),
          Wrap(spacing: 10, runSpacing: 10, children: [
            FilledButton.icon(
              onPressed: _busy ? null : _push,
              icon: const Icon(Icons.upload),
              label: const Text('Send to node'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : () => _loadFromNode(sel),
              icon: const Icon(Icons.refresh),
              label: const Text('Reload'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _editRaw,
              icon: const Icon(Icons.code),
              label: const Text('Raw JSON'),
            ),
          ]),
          const SizedBox(height: 8),
          Text('Sending needs an access token and "restricted": false on that node.',
              style: TextStyle(color: p.muted, fontSize: 12.5)),
        ],
        // ---- 4. local run -------------------------------------------------
        if (isLocalSel && c.localSupported) ...[
          const SizedBox(height: 14),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Run on this computer', style: context.tt.titleMedium),
              gap,
              TextField(
                controller: _exe,
                decoration: const InputDecoration(
                  labelText: 'Path to xmrig executable',
                  hintText: '/path/to/xmrig/build/xmrig  or  C:\\xmrig\\xmrig.exe',
                ),
              ),
              gap,
              TextField(
                controller: _port,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Local API port'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow other devices on my network'),
                subtitle: const Text('Lets your phone monitor this miner. Protected by a generated token.'),
                value: f.allowLan,
                onChanged: (v) => setState(() => f.allowLan = v),
              ),
              gap,
              Row(children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _startLocal,
                    icon: const Icon(Icons.play_arrow),
                    label: Text(c.localRunning ? 'Restart with this config' : 'Save & start miner'),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _busy || !c.localRunning ? null : _stopLocal,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ]),
              if (c.monitorFor(kLocalNodeId)?.profile.hasToken ?? false)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: SelectableText('Token for other devices: ${c.monitorFor(kLocalNodeId)!.profile.token}',
                      style: TextStyle(color: p.muted)),
                ),
            ]),
          ),
        ],
      ],
    ]);
  }
}
