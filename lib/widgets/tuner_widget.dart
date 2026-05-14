import 'package:flutter/material.dart';
import 'dart:math' as math;

class TunerWidget extends StatefulWidget {
  const TunerWidget({super.key});

  @override
  State<TunerWidget> createState() => _TunerWidgetState();
}

class _TunerWidgetState extends State<TunerWidget>
    with TickerProviderStateMixin {
  late AnimationController _needleController;
  late Animation<double> _needleAnimation;
  int _selectedStringIndex = 0;
  double _cents = 0;
  bool _isListening = false;
  String _detectedNote = '-';
  String _targetNote = 'E2';
  String _tuningStatus = 'Tap to tune';

  final List<Map<String, dynamic>> _stringData = [
    {'string': '6', 'note': 'E2', 'color': Color(0xFFB8860B)},
    {'string': '5', 'note': 'A2', 'color': Color(0xFFB8860B)},
    {'string': '4', 'note': 'D3', 'color': Color(0xFFDAA520)},
    {'string': '3', 'note': 'G3', 'color': Color(0xFFDAA520)},
    {'string': '2', 'note': 'B3', 'color': Color(0xFFD0D0D0)},
    {'string': '1', 'note': 'E4', 'color': Color(0xFFE8E8E8)},
  ];

  @override
  void initState() {
    super.initState();
    _needleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _needleAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _needleController, curve: Curves.easeOut),
    );
    _targetNote = _stringData[0]['note'];
  }

  @override
  void dispose() {
    _needleController.dispose();
    super.dispose();
  }

  void _simulateTuning() {
    // Simulate tuning detection (real impl needs microphone access)
    setState(() {
      _isListening = true;
      _tuningStatus = 'Listening...';
    });

    // Simulate with random cents deviation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      final random = math.Random();
      final deviation = (random.nextDouble() * 40 - 20).roundToDouble();
      _cents = deviation;

      _needleAnimation = Tween<double>(
        begin: _needleAnimation.value,
        end: deviation / 50,
      ).animate(CurvedAnimation(parent: _needleController, curve: Curves.easeOut));
      _needleController.forward(from: 0);

      String status;
      if (deviation.abs() < 3) {
        status = 'In Tune! ✓';
        _detectedNote = _targetNote;
      } else if (deviation < 0) {
        status = 'Too Low (-${deviation.abs().toStringAsFixed(0)} cents)';
        _detectedNote = '↑ Tighten';
      } else {
        status = 'Too High (+${deviation.toStringAsFixed(0)} cents)';
        _detectedNote = '↓ Loosen';
      }

      setState(() {
        _tuningStatus = status;
        _isListening = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Tuner display
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF5C2A00)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Note display
                Text(
                  _targetNote,
                  style: const TextStyle(
                    color: Color(0xFFDAA520),
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                // Needle gauge
                Expanded(
                  child: AnimatedBuilder(
                    animation: _needleAnimation,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: TunerNeedlePainter(
                          value: _needleAnimation.value,
                          cents: _cents,
                        ),
                        size: const Size(double.infinity, double.infinity),
                      );
                    },
                  ),
                ),
                // Status text
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    _tuningStatus,
                    style: TextStyle(
                      color: _cents.abs() < 3
                          ? const Color(0xFF4CAF50)
                          : _cents.abs() < 10
                              ? const Color(0xFFFF9800)
                              : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // String selector
          const Text(
            'SELECT STRING TO TUNE',
            style: TextStyle(
              color: Colors.white30,
              fontSize: 9,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: List.generate(
              6,
              (i) => GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedStringIndex = i;
                    _targetNote = _stringData[i]['note'];
                    _cents = 0;
                    _tuningStatus = 'Tap to tune';
                    _detectedNote = '-';
                  });
                  _needleAnimation = Tween<double>(begin: 0, end: 0).animate(
                    CurvedAnimation(parent: _needleController, curve: Curves.easeOut),
                  );
                  _needleController.forward(from: 0);
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _selectedStringIndex == i
                        ? (_stringData[i]['color'] as Color).withOpacity(0.3)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _selectedStringIndex == i
                          ? _stringData[i]['color'] as Color
                          : Colors.white.withOpacity(0.1),
                      width: _selectedStringIndex == i ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _stringData[i]['string'],
                        style: TextStyle(
                          color: _stringData[i]['color'] as Color,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _stringData[i]['note'].toString().replaceAll(RegExp(r'\d'), ''),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Listen button
          GestureDetector(
            onTap: _isListening ? null : _simulateTuning,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isListening
                      ? [Colors.grey.shade800, Colors.grey.shade700]
                      : [const Color(0xFF8B4513), const Color(0xFFDAA520)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isListening ? 'Listening...' : 'Detect Note',
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
            '* Microphone access needed for real tuning.\nThis demo simulates detection.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white24, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

// Tuner needle painter
class TunerNeedlePainter extends CustomPainter {
  final double value; // -1 to 1
  final double cents;

  const TunerNeedlePainter({required this.value, required this.cents});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.9);
    final radius = size.width * 0.45;

    // Draw gauge arc
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Red zones
    arcPaint.color = Colors.red.withOpacity(0.4);
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

    // Yellow zones
    arcPaint.color = Colors.orange.withOpacity(0.4);
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

    // Green zone (in tune)
    arcPaint.color = const Color(0xFF4CAF50).withOpacity(0.6);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi * 1.45,
      math.pi * 0.1,
      false,
      arcPaint,
    );

    // Tick marks
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
          ..color = Colors.white.withOpacity(isMajor ? 0.5 : 0.2)
          ..strokeWidth = isMajor ? 1.5 : 0.8,
      );
    }

    // Needle
    final needleAngle = math.pi * 1.5 + value * math.pi * 0.5;
    final needleEnd = Offset(
      center.dx + (radius - 12) * math.cos(needleAngle),
      center.dy + (radius - 12) * math.sin(needleAngle),
    );

    // Needle shadow
    canvas.drawLine(
      center,
      needleEnd,
      Paint()
        ..color = Colors.black.withOpacity(0.4)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // Needle
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

    // Center pivot
    canvas.drawCircle(
      center,
      6,
      Paint()..color = Colors.white.withOpacity(0.8),
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
