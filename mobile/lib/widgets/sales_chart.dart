import 'package:flutter/material.dart';

import '../core/colors.dart';
import '../core/format.dart';
import '../models/reports.dart';

/// Grafik batang penjualan harian (dibuat sendiri dengan CustomPainter, tanpa paket tambahan).
class SalesBarChart extends StatelessWidget {
  const SalesBarChart({super.key, required this.points, this.height = 180});

  final List<SalesPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _BarPainter(points)),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.points);

  final List<SalesPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 42.0;
    const bottomPad = 22.0;
    const topPad = 8.0;
    final chartW = size.width - leftPad;
    final chartH = size.height - bottomPad - topPad;
    if (chartW <= 0 || chartH <= 0) return;

    var maxValue = 0;
    for (final p in points) {
      if (p.total > maxValue) maxValue = p.total;
    }
    final top = maxValue == 0 ? 1 : maxValue;

    final grid = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = topPad + chartH * (1 - i / 3);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), grid);
      _text(canvas, rpCompact(top * i / 3), Offset(0, y - 7), 10);
    }
    final n = points.length;
    if (n == 0) return;

    final slot = chartW / n;
    final barWidth = slot * 0.62;
    final bar = Paint()..color = AppColors.navy;
    final step = (n / 8).ceil();
    for (var i = 0; i < n; i++) {
      final h = chartH * points[i].total / top;
      final x = leftPad + slot * i + (slot - barWidth) / 2;
      if (h > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x, topPad + chartH - h, barWidth, h), const Radius.circular(3)),
          bar,
        );
      }
      if (i % step == 0) {
        _text(canvas, dayMonth(points[i].date), Offset(x - 6, size.height - 16), 9.5);
      }
    }
  }

  void _text(Canvas canvas, String text, Offset offset, double fontSize) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: fontSize, color: AppColors.muted)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _BarPainter oldDelegate) => oldDelegate.points != points;
}
