import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/guitar_provider.dart';

class GuitarBodyWidget extends StatefulWidget {
  final VoidCallback onStrumDown;
  final VoidCallback onStrumUp;

  const GuitarBodyWidget({
    super.key,
    required this.onStrumDown,
    required this.onStrumUp,
  });

  @override
  State<GuitarBodyWidget> createState() => _GuitarBodyWidgetState();
}

class _GuitarBodyWidgetState extends State<GuitarBodyWidget>
    with TickerProviderStateMixin {
  late AnimationController _strumController;
  late AnimationController _pulseController;
  late Animation<double> _strumAnimation;
  late Animation<double> _pulseAnimation;
  bool _isStrumming = false;

  @override
  void initState() {
    super.initState();
    _strumController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _strumAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _strumController, curve: Curves.easeOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _strumController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GuitarProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1a0a00),
                Color(0xFF2d1500),
              ],
            ),
          ),
          child: CustomPaint(
            painter: GuitarBodyPainter(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Guitar body top curve
                const Spacer(flex: 2),

                // Sound hole and strum area
                Expanded(
                  flex: 5,
                  child: _buildStrumArea(provider),
                ),

                // Bridge area
                Expanded(
                  flex: 2,
                  child: _buildBridgeArea(provider),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStrumArea(GuitarProvider provider) {
    return GestureDetector(
      onVerticalDragStart: (details) {
        setState(() => _isStrumming = true);
        _strumController.forward(from: 0);
      },
      onVerticalDragUpdate: (details) {
        if (details.delta.dy > 3) {
          widget.onStrumDown();
        } else if (details.delta.dy < -3) {
          widget.onStrumUp();
        }
      },
      onVerticalDragEnd: (details) {
        setState(() => _isStrumming = false);
      },
      onTap: () {
        widget.onStrumDown();
        _strumController.forward(from: 0);
      },
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isStrumming ? 1.05 : _pulseAnimation.value,
            child: child,
          );
        },
        child: CustomPaint(
          painter: SoundHolePainter(isActive: _isStrumming),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                Text(
                  'STRUM',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 8,
                    letterSpacing: 2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.swipe_vertical,
                  color: Colors.white.withOpacity(0.2),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBridgeArea(GuitarProvider provider) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Volume slider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Icon(
                provider.isMuted ? Icons.volume_off : Icons.volume_down,
                color: Colors.white.withOpacity(0.5),
                size: 12,
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: const Color(0xFFDAA520),
                    inactiveTrackColor: Colors.white.withOpacity(0.2),
                    thumbColor: const Color(0xFFDAA520),
                  ),
                  child: Slider(
                    value: provider.volume,
                    onChanged: (v) => provider.setVolume(v),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => provider.toggleMute(),
                child: Icon(
                  provider.isMuted ? Icons.volume_mute : Icons.volume_up,
                  color: provider.isMuted
                      ? Colors.orange
                      : Colors.white.withOpacity(0.5),
                  size: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Recording button
        GestureDetector(
          onTap: () {
            if (provider.isRecording) {
              provider.stopRecording();
            } else {
              provider.startRecording();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: provider.isRecording
                  ? Colors.red.withOpacity(0.8)
                  : Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: provider.isRecording
                    ? Colors.red
                    : Colors.white.withOpacity(0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  provider.isRecording ? Icons.stop : Icons.fiber_manual_record,
                  color: provider.isRecording ? Colors.white : Colors.red,
                  size: 10,
                ),
                const SizedBox(width: 4),
                Text(
                  provider.isRecording ? 'Stop' : 'Rec',
                  style: const TextStyle(color: Colors.white, fontSize: 9),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// Guitar body background painter
class GuitarBodyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw guitar body outline
    final bodyPaint = Paint()
      ..color = const Color(0xFF5C2A00).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Left side wood grain
    for (double y = 0; y < h; y += 8) {
      final linePaint = Paint()
        ..color = Colors.black.withOpacity(0.1)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, y), Offset(w, y + 3), linePaint);
    }
  }

  @override
  bool shouldRepaint(GuitarBodyPainter oldDelegate) => false;
}

// Sound hole painter
class SoundHolePainter extends CustomPainter {
  final bool isActive;

  const SoundHolePainter({required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Outer ring
    for (int i = 5; i >= 0; i--) {
      final ringPaint = Paint()
        ..color = isActive
            ? Color.lerp(const Color(0xFF5C2A00), const Color(0xFFDAA520), i / 5)!.withOpacity(0.4 + i * 0.05)
            : const Color(0xFF5C2A00).withOpacity(0.3 + i * 0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(center, radius + i * 3, ringPaint);
    }

    // Sound hole (dark)
    final holePaint = Paint()
      ..color = Colors.black.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, holePaint);

    // Rosette decoration
    final rosettePaint = Paint()
      ..color = const Color(0xFFDAA520).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(center, radius - 4 - i * 3, rosettePaint);
    }

    // Inner reflection
    if (isActive) {
      final glowPaint = Paint()
        ..color = const Color(0xFFDAA520).withOpacity(0.15)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius * 0.8, glowPaint);
    }

    // Strings crossing sound hole
    final stringPaint = Paint()
      ..style = PaintingStyle.stroke;

    const thicknesses = [2.0, 1.7, 1.4, 1.1, 0.8, 0.6];
    const colors = [
      Color(0xFFB8860B),
      Color(0xFFB8860B),
      Color(0xFFDAA520),
      Color(0xFFDAA520),
      Color(0xFFD0D0D0),
      Color(0xFFE8E8E8),
    ];

    for (int i = 0; i < 6; i++) {
      final y = (i + 0.5) * size.height / 6;
      stringPaint.color = isActive ? Colors.white.withOpacity(0.7) : colors[i];
      stringPaint.strokeWidth = thicknesses[i];
      canvas.drawLine(Offset(0, y), Offset(size.width, y), stringPaint);
    }
  }

  @override
  bool shouldRepaint(SoundHolePainter old) => old.isActive != isActive;
}
