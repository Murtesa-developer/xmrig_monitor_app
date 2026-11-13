import 'package:flutter/material.dart';

class Sparkline extends StatelessWidget {
  const Sparkline(this.values, {super.key, this.height = 80, this.color});
  final List<double> values;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _SparkPainter(List.of(values), c)),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.v, this.color);
  final List<double> v;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (v.length < 2) {
      canvas.drawLine(
        Offset(0, size.height - 1),
        Offset(size.width, size.height - 1),
        Paint()
          ..color = color.withValues(alpha: 0.3)
          ..strokeWidth = 1.5,
      );
      return;
    }
    final maxV = v.reduce((a, b) => a > b ? a : b);
    final top = maxV <= 0 ? 1.0 : maxV * 1.15;
    final pts = <Offset>[
      for (var i = 0; i < v.length; i++)
        Offset(size.width * i / (v.length - 1), size.height - (v[i] / top) * (size.height - 4) - 2),
    ];

    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      final q = pts[i - 1], p = pts[i];
      line.quadraticBezierTo(q.dx, q.dy, (q.dx + p.dx) / 2, (q.dy + p.dy) / 2);
    }
    line.lineTo(pts.last.dx, pts.last.dy);

    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.0)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) => true;
}
