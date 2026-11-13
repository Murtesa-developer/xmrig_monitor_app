import 'package:flutter/material.dart';

/// Scrollable page content centred with a max width, so wide screens
/// don't stretch cards edge to edge.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.maxWidth = 980});
  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final side = ((box.maxWidth - maxWidth) / 2).clamp(16.0, double.infinity);
      return ListView(
        padding: EdgeInsets.fromLTRB(side, 8, side, 32),
        children: children,
      );
    });
  }
}
