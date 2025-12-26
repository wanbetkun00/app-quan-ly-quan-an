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
        // Logo icon - square with rounded corners
        Container(
          width: iconSize ?? 40,
          height: iconSize ?? 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primaryOrange, width: 3.5),
          ),
          child: CustomPaint(painter: TkaIconPainter()),
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
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final padding = size.width * 0.15;

    // Central horizontal bar (curved/rounded)
    final hubWidth = size.width * 0.4;
    final hubHeight = size.width * 0.12;
    final hubX = centerX - hubWidth / 2;
    final hubY = centerY - hubHeight / 2;

    // Draw central horizontal rounded rectangle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(hubX, hubY, hubWidth, hubHeight),
        Radius.circular(hubHeight / 2),
      ),
      paint,
    );

    // Left side: Two separate circles, each with its own curved arm
    final leftCircleRadius = size.width * 0.12;
    final leftTopCircleX = padding + leftCircleRadius;
    final leftTopCircleY = padding + leftCircleRadius;
    final leftBottomCircleX = padding + leftCircleRadius;
    final leftBottomCircleY = size.height - padding - leftCircleRadius;

    // Top left circle
    canvas.drawCircle(
      Offset(leftTopCircleX, leftTopCircleY),
      leftCircleRadius,
      paint,
    );

    // Bottom left circle
    canvas.drawCircle(
      Offset(leftBottomCircleX, leftBottomCircleY),
      leftCircleRadius,
      paint,
    );

    // Right side: Two smaller circles connected by a bifurcated arm
    final rightCircleRadius = size.width * 0.09;
    final rightTopCircleX = size.width - padding - rightCircleRadius;
    final rightTopCircleY = padding + rightCircleRadius * 1.2;
    final rightBottomCircleX = size.width - padding - rightCircleRadius;
    final rightBottomCircleY = size.height - padding - rightCircleRadius * 1.2;

    // Top right circle
    canvas.drawCircle(
      Offset(rightTopCircleX, rightTopCircleY),
      rightCircleRadius,
      paint,
    );

    // Bottom right circle
    canvas.drawCircle(
      Offset(rightBottomCircleX, rightBottomCircleY),
      rightCircleRadius,
      paint,
    );

    // Connection arms - using curved paths
    final armPaint = Paint()
      ..color = AppTheme.primaryOrange
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Left top circle to hub - curved arm
    final leftTopPath = Path()
      ..moveTo(
        leftTopCircleX + leftCircleRadius * 0.7,
        leftTopCircleY - leftCircleRadius * 0.3,
      )
      ..quadraticBezierTo(
        (leftTopCircleX + hubX) / 2,
        (leftTopCircleY + hubY) / 2 - size.width * 0.05,
        hubX,
        hubY,
      );
    canvas.drawPath(leftTopPath, armPaint);

    // Left bottom circle to hub - curved arm
    final leftBottomPath = Path()
      ..moveTo(
        leftBottomCircleX + leftCircleRadius * 0.7,
        leftBottomCircleY + leftCircleRadius * 0.3,
      )
      ..quadraticBezierTo(
        (leftBottomCircleX + hubX) / 2,
        (leftBottomCircleY + hubY + hubHeight) / 2 + size.width * 0.05,
        hubX,
        hubY + hubHeight,
      );
    canvas.drawPath(leftBottomPath, armPaint);

    // Right side - bifurcated arm (single arm that splits to both circles)
    final rightArmStartX = hubX + hubWidth;
    final rightArmStartY = centerY;

    // Main arm from hub
    final rightMainPath = Path()
      ..moveTo(rightArmStartX, rightArmStartY)
      ..lineTo(rightTopCircleX - rightCircleRadius * 0.8, rightArmStartY);
    canvas.drawPath(rightMainPath, armPaint);

    // Branch to top right circle
    final rightTopBranch = Path()
      ..moveTo(rightTopCircleX - rightCircleRadius * 0.8, rightArmStartY)
      ..quadraticBezierTo(
        rightTopCircleX - rightCircleRadius * 0.4,
        (rightArmStartY + rightTopCircleY) / 2,
        rightTopCircleX - rightCircleRadius * 0.3,
        rightTopCircleY,
      );
    canvas.drawPath(rightTopBranch, armPaint);

    // Branch to bottom right circle
    final rightBottomBranch = Path()
      ..moveTo(rightTopCircleX - rightCircleRadius * 0.8, rightArmStartY)
      ..quadraticBezierTo(
        rightBottomCircleX - rightCircleRadius * 0.4,
        (rightArmStartY + rightBottomCircleY) / 2,
        rightBottomCircleX - rightCircleRadius * 0.3,
        rightBottomCircleY,
      );
    canvas.drawPath(rightBottomBranch, armPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
