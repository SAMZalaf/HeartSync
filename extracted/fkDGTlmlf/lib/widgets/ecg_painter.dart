import 'package:flutter/material.dart';
import 'dart:math' as math;

class ECGPainter extends CustomPainter {
  final double progress;
  final Color color;

  ECGPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final width = size.width;
    final height = size.height;
    final centerY = height / 2;

    // Start from left
    path.moveTo(0, centerY);

    // Calculate how far along the ECG line we should draw based on progress
    final animatedWidth = width * progress;

    if (animatedWidth > 0) {
      // Flat line at the beginning
      final flatStart = width * 0.2;
      if (animatedWidth <= flatStart) {
        path.lineTo(animatedWidth, centerY);
      } else {
        path.lineTo(flatStart, centerY);

        // First small bump (P wave)
        final pWaveEnd = width * 0.35;
        if (animatedWidth <= pWaveEnd) {
          final localProgress = (animatedWidth - flatStart) / (pWaveEnd - flatStart);
          _drawSmallBump(path, flatStart, pWaveEnd, centerY, height * 0.15, localProgress);
        } else {
          _drawSmallBump(path, flatStart, pWaveEnd, centerY, height * 0.15, 1.0);

          // Flat line between P and QRS
          final flatMiddle = width * 0.4;
          if (animatedWidth <= flatMiddle) {
            path.lineTo(animatedWidth, centerY);
          } else {
            path.lineTo(flatMiddle, centerY);

            // Main spike (QRS complex)
            final qrsEnd = width * 0.6;
            if (animatedWidth <= qrsEnd) {
              final localProgress = (animatedWidth - flatMiddle) / (qrsEnd - flatMiddle);
              _drawMainSpike(path, flatMiddle, qrsEnd, centerY, height, localProgress);
            } else {
              _drawMainSpike(path, flatMiddle, qrsEnd, centerY, height, 1.0);

              // T wave
              final tWaveEnd = width * 0.75;
              if (animatedWidth <= tWaveEnd) {
                final localProgress = (animatedWidth - qrsEnd) / (tWaveEnd - qrsEnd);
                _drawSmallBump(path, qrsEnd, tWaveEnd, centerY, height * 0.2, localProgress);
              } else {
                _drawSmallBump(path, qrsEnd, tWaveEnd, centerY, height * 0.2, 1.0);

                // Final flat line
                if (animatedWidth <= width) {
                  path.lineTo(animatedWidth, centerY);
                } else {
                  path.lineTo(width, centerY);
                }
              }
            }
          }
        }
      }
    }

    canvas.drawPath(path, paint);
  }

  void _drawSmallBump(Path path, double startX, double endX, double centerY, double amplitude, double progress) {
    final midX = startX + (endX - startX) * 0.5;
    final segmentWidth = endX - startX;
    final currentEnd = startX + segmentWidth * progress;

    if (progress < 0.5) {
      // Going up
      final x = startX + segmentWidth * progress * 2;
      final t = progress * 2;
      final y = centerY - amplitude * math.sin(t * math.pi);
      path.lineTo(x, y);
    } else {
      // Going down
      path.lineTo(midX, centerY - amplitude);
      final x = midX + (currentEnd - midX);
      final t = (progress - 0.5) * 2;
      final y = centerY - amplitude * math.cos(t * math.pi);
      path.lineTo(x, y);
    }
  }

  void _drawMainSpike(Path path, double startX, double endX, double centerY, double height, double progress) {
    final segmentWidth = endX - startX;
    final qPoint = startX + segmentWidth * 0.2;
    final rPoint = startX + segmentWidth * 0.5;
    final sPoint = startX + segmentWidth * 0.8;

    if (progress < 0.2) {
      // Q wave (small dip)
      final x = startX + segmentWidth * progress * 5;
      final t = progress * 5;
      final y = centerY + height * 0.1 * math.sin(t * math.pi);
      path.lineTo(x, y);
    } else if (progress < 0.5) {
      // Q wave complete
      path.lineTo(qPoint, centerY + height * 0.1);
      
      // R wave (large spike up)
      final localProgress = (progress - 0.2) / 0.3;
      final x = qPoint + (rPoint - qPoint) * localProgress;
      final t = localProgress;
      final y = centerY - height * 0.8 * math.sin(t * math.pi);
      path.lineTo(x, y);
    } else if (progress < 0.8) {
      // Q and R complete
      path.lineTo(qPoint, centerY + height * 0.1);
      path.lineTo(rPoint, centerY - height * 0.8);
      
      // S wave (spike down)
      final localProgress = (progress - 0.5) / 0.3;
      final x = rPoint + (sPoint - rPoint) * localProgress;
      final t = localProgress;
      final y = centerY - height * 0.8 * math.cos(t * math.pi) + height * 0.15 * math.sin(t * math.pi);
      path.lineTo(x, y);
    } else {
      // All waves complete
      path.lineTo(qPoint, centerY + height * 0.1);
      path.lineTo(rPoint, centerY - height * 0.8);
      path.lineTo(sPoint, centerY + height * 0.15);
      
      // Return to baseline
      final localProgress = (progress - 0.8) / 0.2;
      final x = sPoint + (endX - sPoint) * localProgress;
      final t = localProgress;
      final y = centerY + height * 0.15 * (1 - t);
      path.lineTo(x, y);
    }
  }

  @override
  bool shouldRepaint(ECGPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
