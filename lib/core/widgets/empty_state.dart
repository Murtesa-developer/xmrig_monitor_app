import 'package:flutter/material.dart';
import 'package:xmrig_monitor/core/theme/app_palette.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.message, this.action});
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: p.cardAlt, shape: BoxShape.circle),
                child: Icon(icon, size: 32, color: p.muted),
              ),
              const SizedBox(height: 16),
              Text(title, style: context.tt.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(message,
                  textAlign: TextAlign.center, style: context.tt.bodyMedium?.copyWith(color: p.muted)),
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ),
    );
  }
}
