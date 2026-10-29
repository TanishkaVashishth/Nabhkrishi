import 'package:flutter/material.dart';

/// Custom Tractor Icon representing the NabhKrishi Brand Logo
class TractorIcon extends StatelessWidget {
  final double size;
  final Color color;

  const TractorIcon({
    super.key,
    this.size = 20,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _TractorPainter(color: color),
      ),
    );
  }
}

class _TractorPainter extends CustomPainter {
  final Color color;

  _TractorPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.save();
    // Scale from 24x24 SVG viewport to size
    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    // Large rear tire outer
    canvas.drawCircle(const Offset(19, 18), 3, paint);
    // Large rear tire inner hole
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawCircle(const Offset(19, 18), 1, clearPaint);

    // Front tire outer
    canvas.drawCircle(const Offset(7, 18), 3, paint);
    canvas.drawCircle(const Offset(7, 18), 1, clearPaint);

    // Chassis and cab
    final path = Path();
    // Cab roof & window
    path.moveTo(9, 7);
    path.lineTo(16, 7);
    path.lineTo(16, 10);
    path.lineTo(9, 10);
    path.close();

    // Body
    path.moveTo(21, 10);
    path.lineTo(18, 10);
    path.lineTo(18, 7);
    path.cubicTo(18, 5.9, 17.1, 5, 16, 5);
    path.lineTo(9, 5);
    path.cubicTo(7.9, 5, 7, 5.9, 7, 7);
    path.lineTo(7, 10);
    path.lineTo(4, 10);
    path.cubicTo(2.9, 10, 2, 10.9, 2, 12);
    path.lineTo(2, 18);
    path.lineTo(4.2, 18);
    path.cubicTo(4.6, 16.8, 5.7, 16, 7, 16);
    path.cubicTo(8.3, 16, 9.4, 16.8, 9.8, 18);
    path.lineTo(14.2, 18);
    path.cubicTo(14.6, 16.8, 15.7, 16, 17, 16);
    path.cubicTo(18.3, 16, 19.4, 16.8, 19.8, 18);
    path.lineTo(22, 18);
    path.lineTo(22, 12);
    path.cubicTo(22, 10.9, 21.1, 10, 21, 10);
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TractorPainter oldDelegate) =>
      oldDelegate.color != color;
}
