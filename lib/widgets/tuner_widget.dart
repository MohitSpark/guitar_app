import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../providers/guitar_provider.dart';

class TunerWidget extends StatefulWidget {
  const TunerWidget({super.key});

  @override
  State<TunerWidget> createState() => _TunerWidgetState();
}

class _TunerWidgetState extends State<TunerWidget> with TickerProviderStateMixin {
  late AnimationController _needleController;
  late Animation<double> _needleAnimation;

  @override
  void initState() {
    super.initState();
    _needleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _needleAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _needleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _needleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GuitarProvider>(
      builder: (context, provider, child) {
        final double centsValue = provider.tuningCents;
        final bool isListening = provider.isTunerActive;

        // Drive the custom needle position
        _needleAnimation = Tween<double>(
          begin: _needleAnimation.value,
          end: (centsValue / 50).clamp(-1.0, 1.0),
        ).animate(CurvedAnimation(parent: _needleController, curve: Curves.easeOut));
        _needleController.forward(from: 0);

        // Map text and styling states directly out of the state engine
        String displayStatusText;
        Color displayTextColor;

        if (!isListening) {
          displayStatusText = 'Tap button below to start';
          displayTextColor = Colors.white30;
        } else if (!provider.isProcessingVirtualNote) {
          displayStatusText = 'Listening... Pluck a string!';
          displayTextColor = const Color(0xFFDAA520);
        } else if (centsValue.abs() < 3) {
          displayStatusText = 'In Tune! ✓';
          displayTextColor = const Color(0xFF4CAF50);
        } else if (centsValue < 0) {
          displayStatusText = 'Too Low (-${centsValue.abs().toStringAsFixed(0)} cents)';
          displayTextColor = const Color(0xFFFF9800);
        } else {
          displayStatusText = 'Too High (+${centsValue.toStringAsFixed(0)} cents)';
          displayTextColor = Colors.red;
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Tuner display box using your exact decoration style
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF5C2A00)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      isListening ? provider.autoDetectedNote : '--',
                      style: const TextStyle(
                        color: Color(0xFFDAA520),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _needleAnimation,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: TunerNeedlePainter(
                              value: isListening ? _needleAnimation.value : 0.0,
                              cents: isListening ? centsValue : 0.0,
                            ),
                            size: const Size(double.infinity, double.infinity),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Text(
                        displayStatusText,
                        style: TextStyle(
                          color: displayTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Your original design button, now wired to trigger your provider!
              GestureDetector(
                onTap: () => provider.toggleTunerListening(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isListening
                          ? [Colors.grey.shade800, Colors.grey.shade700] // Dark design when listening
                          : [const Color(0xFF8B4513), const Color(0xFFDAA520)], // Original gold gradient when idle
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isListening ? 'Stop Listening' : 'Detect Note',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),
              const Text(
                '* Virtual Tuner Mode Connected.\nInteract with your guitar fretboard to test needle behaviors.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white24, fontSize: 9),
              ),
            ],
          ),
        );
      },
    );
  }
}

class TunerNeedlePainter extends CustomPainter {
  final double value;
  final double cents;

  const TunerNeedlePainter({required this.value, required this.cents});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.9);
    final radius = size.width * 0.45;

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    arcPaint.color = Colors.red.withValues(alpha: 0.4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 1.0,
      math.pi * 0.25,
      false,
      arcPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 1.75,
      math.pi * 0.25,
      false,
      arcPaint,
    );

    arcPaint.color = Colors.orange.withValues(alpha: 0.4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 1.25,
      math.pi * 0.2,
      false,
      arcPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 1.55,
      math.pi * 0.2,
      false,
      arcPaint,
    );

    arcPaint.color = const Color(0xFF4CAF50).withValues(alpha: 0.6);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 1.45,
      math.pi * 0.1,
      false,
      arcPaint,
    );

    for (int i = 0; i <= 20; i++) {
      final angle = math.pi + (i / 20) * math.pi;
      final isMajor = i % 5 == 0;
      final len = isMajor ? 10.0 : 5.0;
      final r1 = radius - len;

      final start = Offset(
        center.dx + r1 * math.cos(angle),
        center.dy + r1 * math.sin(angle),
      );
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = Colors.white.withValues(alpha: isMajor ? 0.5 : 0.2)
          ..strokeWidth = isMajor ? 1.5 : 0.8,
      );
    }

    final needleAngle = math.pi * 1.5 + value * math.pi * 0.5;
    final needleEnd = Offset(
      center.dx + (radius - 12) * math.cos(needleAngle),
      center.dy + (radius - 12) * math.sin(needleAngle),
    );

    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    final needleColor = cents.abs() < 3
        ? const Color(0xFF4CAF50)
        : cents.abs() < 10
            ? Colors.orange
            : Colors.red;

    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = needleColor
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(
      center,
      6,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
    canvas.drawCircle(
      center,
      3,
      Paint()..color = needleColor,
    );
  }

  @override
  bool shouldRepaint(TunerNeedlePainter old) =>
      old.value != value || old.cents != cents;
}
