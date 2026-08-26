import 'dart:math';

import 'package:flutter/material.dart';

class BlinkitStyleDeliveryBoy extends StatefulWidget {
  final double rating;

  const BlinkitStyleDeliveryBoy({super.key, required this.rating});

  @override
  State<BlinkitStyleDeliveryBoy> createState() =>
      _BlinkitStyleDeliveryBoyState();
}

class _BlinkitStyleDeliveryBoyState extends State<BlinkitStyleDeliveryBoy>
    with TickerProviderStateMixin {
  late AnimationController _walkController;
  late AnimationController _celebrateController;
  late AnimationController _sadController;
  late Animation<double> _walkAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Walking animation (continuous)
    _walkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _walkAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _walkController, curve: Curves.easeInOut),
    );

    // Celebration animation for high ratings
    _celebrateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Sad animation for low ratings
    _sadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _bounceAnimation = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _celebrateController, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(BlinkitStyleDeliveryBoy oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Trigger animations based on rating
    if (widget.rating >= 4 && widget.rating != oldWidget.rating) {
      _celebrateController.forward(from: 0);
    } else if (widget.rating > 0 &&
        widget.rating <= 2 &&
        widget.rating != oldWidget.rating) {
      _sadController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _walkController.dispose();
    _celebrateController.dispose();
    _sadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _walkController,
        _celebrateController,
        _sadController,
      ]),
      builder: (context, child) {
        double legOffset = _walkAnimation.value;
        double armOffset = _walkAnimation.value * 0.5;
        double bodyOffset = 0;
        double rotation = 0;

        if (_celebrateController.isAnimating) {
          bodyOffset = _bounceAnimation.value;
          rotation = sin(_celebrateController.value * 4 * 3.14) * 0.1;
        } else if (_sadController.isAnimating) {
          bodyOffset = sin(_sadController.value * 3.14) * 3;
        } else if (widget.rating >= 4) {
          bodyOffset = sin(_walkController.value * 2 * 3.14) * 3;
        } else if (widget.rating <= 2 && widget.rating > 0) {
          bodyOffset = sin(_walkController.value * 3.14) * 2;
        }

        return Transform.translate(
          offset: Offset(0, bodyOffset),
          child: Transform.rotate(
            angle: rotation,
            child: SizedBox(
              width: 90,
              height: 90,
              child: CustomPaint(
                painter: BlinkitDeliveryBoyPainter(
                  rating: widget.rating,
                  legOffset: legOffset,
                  armOffset: armOffset,
                  isCelebrating: _celebrateController.isAnimating,
                  isSad: _sadController.isAnimating,
                  celebrationValue: _celebrateController.value,
                  sadValue: _sadController.value,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class BlinkitDeliveryBoyPainter extends CustomPainter {
  final double rating;
  final double legOffset;
  final double armOffset;
  final bool isCelebrating;
  final bool isSad;
  final double celebrationValue;
  final double sadValue;

  BlinkitDeliveryBoyPainter({
    required this.rating,
    required this.legOffset,
    required this.armOffset,
    required this.isCelebrating,
    required this.isSad,
    required this.celebrationValue,
    required this.sadValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Get expression based on rating
    final isHappy = rating >= 4;
    final isSadFace = rating > 0 && rating < 2.5;

    // Draw shadow on ground
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy + 40),
        width: 60,
        height: 10,
      ),
      shadowPaint,
    );

    // Body (T-shirt)
    final bodyPaint = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx + 2, center.dy + 5),
          width: 40,
          height: 35,
        ),
        const Radius.circular(10),
      ),
      bodyPaint,
    );

    // Blinkit logo on shirt
    final logoPaint = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx + 2, center.dy + 8),
        width: 20,
        height: 3,
      ),
      logoPaint,
    );

    // Left Leg with walking animation
    final legPaint = Paint()..color = const Color(0xFF1B5E20);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx - 8 + legOffset * 0.5, center.dy + 30),
          width: 10,
          height: 20,
        ),
        const Radius.circular(5),
      ),
      legPaint,
    );

    // Right Leg with walking animation
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx + 12 - legOffset * 0.5, center.dy + 30),
          width: 10,
          height: 20,
        ),
        const Radius.circular(5),
      ),
      legPaint,
    );

    // Left Arm with swinging animation
    final armPaint = Paint()..color = const Color(0xFF4CAF50);
    canvas.save();
    canvas.translate(center.dx - 18, center.dy - 5);
    canvas.rotate(armOffset * 0.1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-4, 0, 10, 25),
        const Radius.circular(5),
      ),
      armPaint,
    );
    canvas.restore();

    // Right Arm with swinging animation
    canvas.save();
    canvas.translate(center.dx + 22, center.dy - 5);
    canvas.rotate(-armOffset * 0.1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-6, 0, 10, 25),
        const Radius.circular(5),
      ),
      armPaint,
    );
    canvas.restore();

    // Head
    final headPaint = Paint()..color = const Color(0xFF8D6E63);
    canvas.drawCircle(Offset(center.dx + 2, center.dy - 15), 20, headPaint);

    // Hair
    final hairPaint = Paint()..color = const Color(0xFF4E342E);
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(center.dx + 2, center.dy - 25),
        radius: 22,
      ),
      -3.14,
      3.14,
      true,
      hairPaint,
    );

    // Helmet (Delivery helmet)
    final helmetPaint = Paint()..color = const Color(0xFFFF6B00);
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(center.dx + 2, center.dy - 28),
        radius: 16,
      ),
      0,
      3.14,
      true,
      helmetPaint,
    );

    // Helmet stripe
    final stripePaint = Paint()..color = Colors.white;
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(center.dx + 2, center.dy - 28),
        radius: 14,
      ),
      0.2,
      2.7,
      false,
      stripePaint..strokeWidth = 2,
    );

    // Eyes
    final eyeWhitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(center.dx - 6, center.dy - 20), 5, eyeWhitePaint);
    canvas.drawCircle(Offset(center.dx + 10, center.dy - 20), 5, eyeWhitePaint);

    // Pupils with expression
    final pupilPaint = Paint()..color = Colors.black;
    if (isCelebrating) {
      // Happy squint eyes
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx - 6, center.dy - 20),
            width: 6,
            height: 4,
          ),
          const Radius.circular(2),
        ),
        pupilPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx + 10, center.dy - 20),
            width: 6,
            height: 4,
          ),
          const Radius.circular(2),
        ),
        pupilPaint,
      );
    } else if (isSad || isSadFace) {
      // Sad downward eyes
      canvas.drawCircle(Offset(center.dx - 8, center.dy - 18), 3, pupilPaint);
      canvas.drawCircle(Offset(center.dx + 12, center.dy - 18), 3, pupilPaint);
    } else {
      // Normal eyes
      canvas.drawCircle(Offset(center.dx - 6, center.dy - 20), 3, pupilPaint);
      canvas.drawCircle(Offset(center.dx + 10, center.dy - 20), 3, pupilPaint);

      // Eye highlights
      final highlightPaint = Paint()..color = Colors.white;
      canvas.drawCircle(
        Offset(center.dx - 7, center.dy - 21),
        1.5,
        highlightPaint,
      );
      canvas.drawCircle(
        Offset(center.dx + 9, center.dy - 21),
        1.5,
        highlightPaint,
      );
    }

    // Eyebrows
    final browPaint = Paint()
      ..color = const Color(0xFF4E342E)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    if (isHappy || isCelebrating) {
      // Happy eyebrows
      canvas.drawLine(
        Offset(center.dx - 12, center.dy - 27),
        Offset(center.dx - 4, center.dy - 29),
        browPaint,
      );
      canvas.drawLine(
        Offset(center.dx + 8, center.dy - 29),
        Offset(center.dx + 16, center.dy - 27),
        browPaint,
      );
    } else if (isSad || isSadFace) {
      // Sad eyebrows
      canvas.drawLine(
        Offset(center.dx - 12, center.dy - 29),
        Offset(center.dx - 4, center.dy - 27),
        browPaint,
      );
      canvas.drawLine(
        Offset(center.dx + 8, center.dy - 27),
        Offset(center.dx + 16, center.dy - 29),
        browPaint,
      );
    } else {
      // Neutral eyebrows
      canvas.drawLine(
        Offset(center.dx - 12, center.dy - 28),
        Offset(center.dx - 4, center.dy - 28),
        browPaint,
      );
      canvas.drawLine(
        Offset(center.dx + 8, center.dy - 28),
        Offset(center.dx + 16, center.dy - 28),
        browPaint,
      );
    }

    // Mouth based on rating
    final mouthPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    if (isHappy || isCelebrating) {
      // Big smile
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(center.dx + 2, center.dy - 12),
          radius: 8,
        ),
        0.1,
        3.0,
        false,
        mouthPaint,
      );

      // Cheeks
      final cheekPaint = Paint()
        ..color = const Color(0xFFFF9999).withValues(alpha: 0.5);
      canvas.drawCircle(Offset(center.dx - 12, center.dy - 14), 4, cheekPaint);
      canvas.drawCircle(Offset(center.dx + 16, center.dy - 14), 4, cheekPaint);
    } else if (isSad || isSadFace) {
      // Sad mouth
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(center.dx + 2, center.dy - 8),
          radius: 6,
        ),
        3.14,
        3.14,
        false,
        mouthPaint,
      );
    } else {
      // Neutral smile
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(center.dx + 2, center.dy - 12),
          radius: 6,
        ),
        0.2,
        2.8,
        false,
        mouthPaint,
      );
    }

    // Celebration stars for high rating
    if (isCelebrating || (rating >= 4 && celebrationValue > 0)) {
      for (int i = 0; i < 4; i++) {
        final angle = (i * 90) * 3.14 / 180 + celebrationValue * 6.28;
        final radius = 30 + sin(celebrationValue * 10) * 5;
        final starX = center.dx + 2 + cos(angle) * radius;
        final starY = center.dy - 15 + sin(angle) * radius;

        final starPaint = Paint()..color = Colors.amber;
        final starSize = 6 + sin(celebrationValue * 20) * 2;
        canvas.drawCircle(Offset(starX, starY), starSize, starPaint);
      }
    }

    // Tears for low rating
    if (isSad || (sadValue > 0 && rating <= 2)) {
      final tearPaint = Paint()..color = Colors.blue[300]!;
      canvas.drawCircle(
        Offset(center.dx - 10, center.dy - 14 + sadValue * 10),
        3,
        tearPaint,
      );
      canvas.drawCircle(
        Offset(center.dx + 14, center.dy - 14 + sadValue * 10),
        3,
        tearPaint,
      );
    }

    // Delivery bag on back
    final bagPaint = Paint()..color = const Color(0xFF795548);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx + 18, center.dy - 5),
          width: 15,
          height: 25,
        ),
        const Radius.circular(4),
      ),
      bagPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
