


import 'dart:math';

import 'package:flutter/material.dart';

class BackgroundShapes extends StatelessWidget {
  const BackgroundShapes({super.key, this.reverse = false});
  final bool reverse;

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary لتقليل إعادة الرسم
    return RepaintBoundary(
      child: CustomPaint(
        painter: BubblesStatic(reverse: reverse),
        size: Size.infinite,
      ),
    );
  }
}

class BubblesStatic extends CustomPainter {
  BubblesStatic({required this.reverse});
  final bool reverse;

  // Random بذرة ثابتة لضمان ثبات الترتيب/المواقع عبر الإطارات
  final Random rnd = Random(7);

  @override
  void paint(Canvas canvas, Size size) {
    final colors = [
      const Color(0x332F3C7E),
      const Color(0x334F8FC0),
      const Color(0x332AA7B6),
    ];

    // إزاحة بسيطة ثابتة (بدون حركة)
    final double dx = reverse ? -8.0 : 8.0;

    for (var i = 0; i < 28; i++) {
      final paint = Paint()..color = colors[i % colors.length];
      final radius = rnd.nextDouble() * 80 + 16;
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;

      canvas.drawCircle(Offset(x + dx, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}