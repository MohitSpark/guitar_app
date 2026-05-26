import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/guitar_provider.dart';

class GuitarNeckWidget extends StatefulWidget {
  const GuitarNeckWidget({super.key});

  @override
  State<GuitarNeckWidget> createState() => _GuitarNeckWidgetState();
}

class _GuitarNeckWidgetState extends State<GuitarNeckWidget>
    with TickerProviderStateMixin {
  final int _visibleFrets = 12;
  int _startFret = 0;

  int _lastPlayedString = -1;
  int _lastPlayedFretVal = -1;
  bool _isSliding = false;
  int _lastPlayedMs = 0;
  static const int _slideThrottleMs = 55; // min ms between notes while sliding

  @override
  void initState() {
    super.initState();
  }


  void _tryPlay(GuitarProvider provider, int stringIndex, int actualFret,
      {bool reset = false}) {
    if (reset) {
      _lastPlayedString = -1;
      _lastPlayedFretVal = -1;
      _lastPlayedMs = 0;
    }

    // Skip if identical string+fret
    if (_lastPlayedString == stringIndex && _lastPlayedFretVal == actualFret) {
      return;
    }

    // Throttle rapid events during slide to keep audio clean
    if (_isSliding) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastPlayedMs < _slideThrottleMs) return;
      _lastPlayedMs = now;
    }

    debugPrint('Triggering note: String $stringIndex, Fret $actualFret');
    _lastPlayedString = stringIndex;
    _lastPlayedFretVal = actualFret;
    provider.playString(stringIndex, actualFret);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GuitarProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF2C1810),
                Color(0xFF3D2314),
                Color(0xFF2C1810),
              ],
            ),
          ),
          child: Column(
            children: [
              _buildFretNavigation(provider),
              Expanded(
                child: GestureDetector(
                  onHorizontalDragEnd: (details) {
                    if (details.primaryVelocity != null) {
                      setState(() {
                        if (details.primaryVelocity! < 0 && _startFret < 12) {
                          _startFret = (_startFret + 2).clamp(0, 12);
                        } else if (details.primaryVelocity! > 0 &&
                            _startFret > 0) {
                          _startFret = (_startFret - 2).clamp(0, 12);
                        }
                      });
                    }
                  },
                  child: CustomPaint(
                    painter: GuitarNeckPainter(
                      visibleFrets: _visibleFrets,
                      startFret: _startFret,
                      showFretNumbers: provider.showFretNumbers,
                      showNoteNames: provider.showNoteNames,
                      highlightedFrets: provider.highlightedFrets,
                      tuningNotes: provider.currentTuning.notes,
                      activeString: provider.activeString,
                      activeFret: provider.activeFret,
                      leftHanded: provider.leftHanded,
                      capoFret: provider.capoFret,
                    ),
                    child: _buildTouchOverlay(provider),
                  ),
                ),
              ),
              _buildOpenStringLabels(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFretNavigation(GuitarProvider provider) {
    return Container(
      height: 32,
      color: const Color(0xFF1A0A00),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              _startFret == 0 ? 'Open' : 'Fret $_startFret',
              style: const TextStyle(color: Color(0xFFDAA520), fontSize: 11),
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _showCapoDialog(context, provider),
            icon: const Icon(Icons.music_note,
                size: 12, color: Color(0xFFDAA520)),
            label: Text(
              provider.capoFret > 0 ? 'Capo ${provider.capoFret}' : 'Capo',
              style: const TextStyle(color: Color(0xFFDAA520), fontSize: 11),
            ),
            style: TextButton.styleFrom(minimumSize: const Size(60, 28)),
          ),
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                7,
                    (i) => GestureDetector(
                  onTap: () => setState(() => _startFret = i * 2),
                  child: Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _startFret == i * 2
                          ? const Color(0xFFDAA520)
                          : Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildTouchOverlay(GuitarProvider provider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fretWidth = constraints.maxWidth / _visibleFrets;
        final stringHeight = constraints.maxHeight / 6;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,

          onTapDown: (details) {
            final s = _stringFromDy(details.localPosition.dy, stringHeight);
            final f = _fretFromDx(details.localPosition.dx, fretWidth);
            _isSliding = false;
            _tryPlay(provider, s, f + _startFret, reset: true);
          },

          onPanStart: (details) {
            _isSliding = true;
            _lastPlayedMs = 0;
            final s = _stringFromDy(details.localPosition.dy, stringHeight);
            final f = _fretFromDx(details.localPosition.dx, fretWidth);
            _tryPlay(provider, s, f + _startFret, reset: true);
          },

          // No setState here — zero rebuilds during slide, butter smooth
          onPanUpdate: (details) {
            final s = _stringFromDy(details.localPosition.dy, stringHeight);
            final f = _fretFromDx(details.localPosition.dx, fretWidth);
            _tryPlay(provider, s, f + _startFret);
          },

          onPanEnd: (_) {
            _isSliding = false;
            _lastPlayedString = -1;
            _lastPlayedFretVal = -1;
          },

          child: const SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(color: Colors.transparent),
            ),
          ),
        );
      },
    );
  }

  /// Converts local dx → fret index.
  int _fretFromDx(double dx, double fretWidth) =>
      (dx / fretWidth).floor().clamp(0, _visibleFrets);

  /// Converts local dy → string index (0 = thickest/top string).
  int _stringFromDy(double dy, double stringHeight) =>
      (dy / stringHeight).floor().clamp(0, 5);

  Widget _buildOpenStringLabels(GuitarProvider provider) {
    const stringNames = ['E', 'A', 'D', 'G', 'B', 'e'];
    return Container(
      height: 28,
      color: const Color(0xFF1A0A00),
      child: Row(
        children: [
          const SizedBox(width: 8),
          ...List.generate(
            6,
                (i) => Expanded(
              child: GestureDetector(
                onTap: () => provider.playString(i, 0),
                child: Center(
                  child: Container(
                    width: 28,
                    height: 20,
                    decoration: BoxDecoration(
                      color: provider.activeString == i
                          ? const Color(0xFFDAA520)
                          : const Color(0xFF3D2314),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF8B4513),
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        stringNames[i],
                        style: TextStyle(
                          color: provider.activeString == i
                              ? Colors.black
                              : const Color(0xFFDAA520),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  void _showCapoDialog(BuildContext context, GuitarProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2d1500),
        title:
        const Text('Set Capo', style: TextStyle(color: Color(0xFFDAA520))),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            8,
                (i) => GestureDetector(
              onTap: () {
                provider.setCapo(i);
                Navigator.pop(ctx);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: provider.capoFret == i
                      ? const Color(0xFFDAA520)
                      : const Color(0xFF5C2A00),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    i == 0 ? 'Off' : '$i',
                    style: TextStyle(
                      color:
                      provider.capoFret == i ? Colors.black : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom painter — unchanged from original
// ─────────────────────────────────────────────────────────────────────────────
class GuitarNeckPainter extends CustomPainter {
  final int visibleFrets;
  final int startFret;
  final bool showFretNumbers;
  final bool showNoteNames;
  final Map<int, Set<int>> highlightedFrets;
  final List<String> tuningNotes;
  final int? activeString;
  final int? activeFret;
  final bool leftHanded;
  final int capoFret;

  const GuitarNeckPainter({
    required this.visibleFrets,
    required this.startFret,
    required this.showFretNumbers,
    required this.showNoteNames,
    required this.highlightedFrets,
    required this.tuningNotes,
    required this.activeString,
    required this.activeFret,
    required this.leftHanded,
    required this.capoFret,
  });

  static const List<double> stringThicknesses = [
    3.5, 3.0, 2.5, 2.0, 1.5, 1.0
  ];
  static const List<Color> stringColors = [
    Color(0xFFB8860B),
    Color(0xFFB8860B),
    Color(0xFFDAA520),
    Color(0xFFDAA520),
    Color(0xFFD0D0D0),
    Color(0xFFE8E8E8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final fretWidth = size.width / visibleFrets;
    final stringSpacing = size.height / 6;

    _drawNeckBackground(canvas, size);
    _drawFrets(canvas, size, fretWidth);
    _drawInlays(canvas, size, fretWidth, stringSpacing);
    _drawStrings(canvas, size, stringSpacing);
    _drawHighlights(canvas, size, fretWidth, stringSpacing);
    _drawActiveNote(canvas, size, fretWidth, stringSpacing);
    if (showFretNumbers) _drawFretNumbers(canvas, size, fretWidth);
    if (showNoteNames) _drawNoteNames(canvas, size, fretWidth, stringSpacing);
  }

  void _drawNeckBackground(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF3D2010),
          Color(0xFF4A2814),
          Color(0xFF3D2010),
          Color(0xFF452212),
          Color(0xFF3D2010),
        ],
        stops: [0, 0.25, 0.5, 0.75, 1],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);

    final grainPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    for (double x = 0; x < size.width; x += 3.5) {
      canvas.drawLine(Offset(x, 0), Offset(x + 8, size.height), grainPaint);
    }
  }

  void _drawFrets(Canvas canvas, Size size, double fretWidth) {
    final fretPaint = Paint()
      ..color = const Color(0xFFC0C0C0)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final nut = Paint()
      ..color = const Color(0xFFF5F5DC)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= visibleFrets; i++) {
      final x = i * fretWidth;
      final isNut = startFret == 0 && i == 0;
      canvas.drawLine(
          Offset(x, 0), Offset(x, size.height), isNut ? nut : fretPaint);
    }
  }

  void _drawInlays(
      Canvas canvas, Size size, double fretWidth, double stringSpacing) {
    const inlayFrets = [3, 5, 7, 9, 12, 15, 17, 19, 21];

    final inlayPaint = Paint()
      ..color = const Color(0xFFE8DCC8).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    for (final fret in inlayFrets) {
      final relativeFret = fret - startFret;
      if (relativeFret < 0 || relativeFret >= visibleFrets) continue;

      final x = (relativeFret + 0.5) * fretWidth;
      final y = size.height / 2;

      if (fret == 12) {
        canvas.drawCircle(Offset(x, y - stringSpacing), 6, inlayPaint);
        canvas.drawCircle(Offset(x, y + stringSpacing), 6, inlayPaint);
      } else {
        canvas.drawCircle(Offset(x, y), 6, inlayPaint);
      }
    }
  }

  void _drawStrings(Canvas canvas, Size size, double stringSpacing) {
    for (int i = 0; i < 6; i++) {
      final y = (i + 0.5) * stringSpacing;
      final isActive = activeString == i;

      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..strokeWidth = stringThicknesses[i] + 1
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
          Offset(0, y + 1), Offset(size.width, y + 1), shadowPaint);

      final stringPaint = Paint()
        ..color = isActive ? Colors.white.withValues(alpha: 0.95) : stringColors[i]
        ..strokeWidth =
        isActive ? stringThicknesses[i] + 0.5 : stringThicknesses[i]
        ..style = PaintingStyle.stroke;

      if (isActive) {
        final path = Path();
        path.moveTo(0, y);
        for (double x = 0; x < size.width; x += 4) {
          path.lineTo(x, y + (x % 8 < 4 ? 1.5 : -1.5));
        }
        canvas.drawPath(path, stringPaint);
      } else {
        canvas.drawLine(
            Offset(0, y), Offset(size.width, y), stringPaint);
      }

      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..strokeWidth = stringThicknesses[i] * 0.3
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(0, y - stringThicknesses[i] * 0.2),
        Offset(size.width, y - stringThicknesses[i] * 0.2),
        highlightPaint,
      );
    }
  }

  void _drawHighlights(
      Canvas canvas, Size size, double fretWidth, double stringSpacing) {
    for (final entry in highlightedFrets.entries) {
      final stringIndex = entry.key;
      final frets = entry.value;

      for (final fret in frets) {
        final relativeFret = fret - startFret;
        if (relativeFret < 0 || relativeFret >= visibleFrets) continue;

        final x = fret == 0
            ? 12.0
            : (relativeFret - 0.5) * fretWidth + fretWidth * 0.5;
        final y = (stringIndex + 0.5) * stringSpacing;

        final highlightPaint = Paint()
          ..color = const Color(0xFF4CAF50).withValues(alpha: 0.8)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(x, y), 10, highlightPaint);

        final textPainter = TextPainter(
          text: TextSpan(
            text: fret == 0 ? 'O' : '$fret',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2),
        );
      }
    }
  }

  void _drawActiveNote(
      Canvas canvas, Size size, double fretWidth, double stringSpacing) {
    if (activeString == null || activeFret == null) return;

    final relativeFret = (activeFret!) - startFret;
    if (relativeFret < 0 || relativeFret > visibleFrets) return;

    final x = activeFret == 0
        ? 16.0
        : (relativeFret - 0.5) * fretWidth + fretWidth * 0.5;
    final y = (activeString! + 0.5) * stringSpacing;

    for (double r = 24; r >= 14; r -= 2) {
      final glowPaint = Paint()
        ..color = const Color(0xFFDAA520).withValues(alpha: 0.08)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), r, glowPaint);
    }

    final notePaint = Paint()
      ..color = const Color(0xFFDAA520)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), 14, notePaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(x, y), 14, borderPaint);
  }

  void _drawFretNumbers(Canvas canvas, Size size, double fretWidth) {
    for (int i = 1; i <= visibleFrets; i++) {
      final fretNumber = i + startFret;
      final x = (i - 0.5) * fretWidth;

      final textPainter = TextPainter(
        text: TextSpan(
          text: '$fretNumber',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, 2));
    }
  }

  void _drawNoteNames(
      Canvas canvas, Size size, double fretWidth, double stringSpacing) {
    const noteForMidi = [
      'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'
    ];
    const openMidi = [40, 45, 50, 55, 59, 64];

    for (int s = 0; s < 6; s++) {
      for (int f = 0; f <= visibleFrets; f++) {
        final actualFret = f + startFret;
        final midi = openMidi[s] + actualFret;
        final note = noteForMidi[midi % 12];

        final x = f == 0 ? 16.0 : (f - 0.5) * fretWidth + fretWidth * 0.5;
        final y = (s + 0.5) * stringSpacing;

        final textPainter = TextPainter(
          text: TextSpan(
            text: note,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 8,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y + 6),
        );
      }
    }
  }

  @override
  bool shouldRepaint(GuitarNeckPainter oldDelegate) {
    return oldDelegate.activeString != activeString ||
        oldDelegate.activeFret != activeFret ||
        oldDelegate.highlightedFrets != highlightedFrets ||
        oldDelegate.startFret != startFret ||
        oldDelegate.showFretNumbers != showFretNumbers ||
        oldDelegate.showNoteNames != showNoteNames ||
        oldDelegate.capoFret != capoFret;
  }
}