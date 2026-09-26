import 'dart:math';
import 'package:flutter/material.dart';
import '../models/storage_item.dart';

class CustomDonutChart extends StatelessWidget {
  final List<StorageCategory> categories;
  final double totalGB;
  final double freeGB;

  const CustomDonutChart({
    super.key,
    required this.categories,
    required this.totalGB,
    required this.freeGB,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(170, 170),
            painter: _DonutChartPainter(
              categories: categories,
              totalGB: totalGB,
              freeGB: freeGB,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${totalGB.toInt()} GB',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Total Storage',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final List<StorageCategory> categories;
  final double totalGB;
  final double freeGB;

  _DonutChartPainter({
    required this.categories,
    required this.totalGB,
    required this.freeGB,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const strokeWidth = 20.0;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startAngle = -pi / 2; // Start from top

    // Draw categories
    for (final cat in categories) {
      final sweepAngle = (cat.percentage / 100.0) * 2 * pi;
      paint.color = cat.color;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.03, // Small gap between segments
        false,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Draw Free space segment
    final freePercentage = (freeGB / totalGB) * 100.0;
    final freeSweepAngle = (freePercentage / 100.0) * 2 * pi;
    paint.color = const Color(0xFFE2E8F0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      freeSweepAngle - 0.03,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
