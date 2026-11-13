import 'package:flutter/material.dart';
import 'package:xmrig_monitor/core/theme/app_palette.dart';
import 'package:xmrig_monitor/data/models/profile.dart';
import 'package:xmrig_monitor/data/services/xmrig_api.dart';
import 'package:xmrig_monitor/state/monitor_controller.dart';

/// Fields to add or edit a node. Tests the connection before saving.
class NodeForm extends StatefulWidget {
  const NodeForm({super.key, this.initial, required this.onSave, this.submitLabel = 'Connect', this.onCancel});
  final MinerProfile? initial;
  final Future<void> Function(MinerProfile) onSave;
  final String submitLabel;
  final VoidCallback? onCancel;

  @override
  State<NodeForm> createState() => _NodeFormState();
}

class _NodeFormState extends State<NodeForm> {
  late final MinerProfile? p = widget.initial;
  late final _name = TextEditingController(text: p?.name ?? '');
  late final _node = TextEditingController(text: p?.host ?? '');
  late final _port = TextEditingController(text: '${p?.port ?? 44444}');
  late final _token = TextEditingController(text: p?.token ?? '');
  late bool _https = p?.https ?? false;
  String? _error;
  bool _busy = false;
  bool _canForce = false;

  @override
  void dispose() {
    for (final t in [_name, _node, _port, _token]) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> _submit({bool force = false}) async {
    final addr = parseNodeAddress(_node.text);
    if (addr.host.isEmpty) {
      setState(() => _error = 'Enter the node IP address or hostname.');
      return;
    }
    final profile = MinerProfile(
      id: p?.id,
      name: _name.text.trim().isEmpty ? addr.host : _name.text.trim(),
      host: addr.host,
      port: addr.port ?? int.tryParse(_port.text.trim()) ?? 44444,
      token: _token.text.trim(),
      https: addr.https ?? _https,
    );

    setState(() {
      _busy = true;
      _error = null;
      _canForce = false;
    });
    if (!force) {
      final api = XmrigApi(profile);
      try {
        await api.summary();
      } on ApiException catch (e) {
        if (mounted) {
          setState(() {
            _busy = false;
            _error = e.message;
            _canForce = true;
          });
        }
        return;
      } finally {
        api.close();
      }
    }
    await widget.onSave(profile);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _node,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'Node IP / host',
            hintText: '192.168.1.240',
            prefixIcon: Icon(Icons.dns_outlined),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _port,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'API port'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name (optional)')),
          ),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _token,
          obscureText: true,
          onSubmitted: (_) => _submit(),
          decoration: const InputDecoration(
            labelText: 'Access token (if the node has one)',
            prefixIcon: Icon(Icons.key_outlined),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Use HTTPS'),
          value: _https,
          onChanged: (v) => setState(() => _https = v),
        ),
        const SizedBox(height: 4),
        Row(children: [
          if (widget.onCancel != null) ...[
            TextButton(onPressed: _busy ? null : widget.onCancel, child: const Text('Cancel')),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.login),
              label: Text(widget.submitLabel),
            ),
          ),
        ]),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: p.bad)),
          if (_canForce) TextButton(onPressed: () => _submit(force: true), child: const Text('Save anyway')),
        ],
      ],
    );
  }
}

/// Dialog used by the Nodes tab to add or edit a node.
Future<void> showNodeDialog(BuildContext context, MonitorController c, {MinerProfile? initial}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(initial == null ? 'Add node' : 'Edit node', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              NodeForm(
                initial: initial,
                submitLabel: initial == null ? 'Add' : 'Save',
                onCancel: () => Navigator.pop(ctx),
                onSave: (p) async {
                  if (initial == null) {
                    await c.addNode(p);
                  } else {
                    await c.updateNode(p);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
