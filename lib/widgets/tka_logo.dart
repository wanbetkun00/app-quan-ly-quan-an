import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TkaLogo extends StatelessWidget {
  final double? iconSize;
  final double? fontSize;
  final bool showText;

  const TkaLogo({
    super.key,
    this.iconSize,
    this.fontSize,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo icon - circuit board style
        Container(
          width: iconSize ?? 40,
          height: iconSize ?? 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primaryOrange,
              width: 3,
            ),
          ),
          child: CustomPaint(
            painter: TkaIconPainter(),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 12),
          Text(
            'TKA',
            style: TextStyle(
              fontSize: fontSize ?? 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGreyText,
              letterSpacing: 1,
            ),
          ),
        ],
      ],
    );
  }
}

class TkaIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primaryOrange
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final strokePaint = Paint()
      ..color = AppTheme.primaryOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final padding = size.width * 0.15;

    // Left circles (top and bottom)
    final circleRadius = size.width * 0.12;
    final leftX = padding + circleRadius;
    
    // Top left circle
    canvas.drawCircle(
      Offset(leftX, padding + circleRadius),
      circleRadius,
      strokePaint,
    );
    // Draw 4 protrusions (gear-like)
    _drawGearProtrusions(
      canvas,
      Offset(leftX, padding + circleRadius),
      circleRadius,
      strokePaint,
    );

    // Bottom left circle
    canvas.drawCircle(
      Offset(leftX, size.height - padding - circleRadius),
      circleRadius,
      strokePaint,
    );
    _drawGearProtrusions(
      canvas,
      Offset(leftX, size.height - padding - circleRadius),
      circleRadius,
      strokePaint,
    );

    // Right rectangles (top and bottom)
    final rectWidth = size.width * 0.15;
    final rectHeight = size.width * 0.2;
    final rightX = size.width - padding - rectWidth;

    // Top right rectangle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rightX,
          padding,
          rectWidth,
          rectHeight,
        ),
        const Radius.circular(2),
      ),
      paint,
    );
    // Draw pins on left and right
    _drawPins(canvas, Offset(rightX, padding), rectHeight, strokePaint);

    // Bottom right rectangle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rightX,
          size.height - padding - rectHeight,
          rectWidth,
          rectHeight,
        ),
        const Radius.circular(2),
      ),
      paint,
    );
    _drawPins(
      canvas,
      Offset(rightX, size.height - padding - rectHeight),
      rectHeight,
      strokePaint,
    );

    // Central horizontal rectangle (hub)
    final hubWidth = size.width * 0.3;
    final hubHeight = size.width * 0.12;
    final hubX = centerX - hubWidth / 2;
    final hubY = centerY - hubHeight / 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(hubX, hubY, hubWidth, hubHeight),
        const Radius.circular(2),
      ),
      paint,
    );

    // Draw circular cutout on left side of hub
    canvas.drawCircle(
      Offset(hubX, centerY),
      hubHeight * 0.3,
      Paint()..color = Colors.white,
    );

    // Connection lines
    final linePaint = Paint()
      ..color = AppTheme.primaryOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // From top left circle to hub
    canvas.drawLine(
      Offset(leftX + circleRadius, padding + circleRadius),
      Offset(hubX, hubY),
      linePaint,
    );

    // From bottom left circle to hub
    canvas.drawLine(
      Offset(leftX + circleRadius, size.height - padding - circleRadius),
      Offset(hubX, centerY + hubHeight / 2),
      linePaint,
    );

    // From top right rectangle to hub
    canvas.drawLine(
      Offset(rightX, padding + rectHeight / 2),
      Offset(hubX + hubWidth, hubY),
      linePaint,
    );

    // From bottom right rectangle to hub
    canvas.drawLine(
      Offset(rightX, size.height - padding - rectHeight / 2),
      Offset(hubX + hubWidth, centerY + hubHeight / 2),
      linePaint,
    );

    // Connection points (small circles)
    final pointRadius = 2.0;
    final pointPaint = Paint()
      ..color = AppTheme.primaryOrange
      ..style = PaintingStyle.fill;

    // Connection points at intersections
    canvas.drawCircle(Offset(hubX, hubY), pointRadius, pointPaint);
    canvas.drawCircle(Offset(hubX, centerY + hubHeight / 2), pointRadius, pointPaint);
    canvas.drawCircle(Offset(hubX + hubWidth, hubY), pointRadius, pointPaint);
    canvas.drawCircle(Offset(hubX + hubWidth, centerY + hubHeight / 2), pointRadius, pointPaint);
  }

  void _drawGearProtrusions(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
  ) {
    final protrusionLength = radius * 0.4;
    final angles = [0.0, 90.0, 180.0, 270.0]; // 4 directions

    for (final angle in angles) {
      final radians = angle * math.pi / 180;
      final startX = center.dx + radius * 0.7 * math.cos(radians);
      final startY = center.dy + radius * 0.7 * math.sin(radians);
      final endX = center.dx + (radius + protrusionLength) * math.cos(radians);
      final endY = center.dy + (radius + protrusionLength) * math.sin(radians);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  void _drawPins(Canvas canvas, Offset topLeft, double height, Paint paint) {
    final pinWidth = 2.5;
    final pinHeight = height * 0.2;
    final spacing = height * 0.1;
    final rectWidth = height * 0.6; // Approximate width of the rectangle

    // Left side pins (4 pins)
    for (int i = 0; i < 4; i++) {
      final yPos = topLeft.dy + spacing + i * (pinHeight + spacing);
      canvas.drawRect(
        Rect.fromLTWH(
          topLeft.dx - pinWidth - 1,
          yPos,
          pinWidth,
          pinHeight,
        ),
        paint,
      );
    }

    // Right side pins (4 pins)
    for (int i = 0; i < 4; i++) {
      final yPos = topLeft.dy + spacing + i * (pinHeight + spacing);
      canvas.drawRect(
        Rect.fromLTWH(
          topLeft.dx + rectWidth + 1,
          yPos,
          pinWidth,
          pinHeight,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

