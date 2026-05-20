import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/guitar_provider.dart';
import '../models/guitar_models.dart';

class ChordPanelWidget extends StatelessWidget {
  const ChordPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GuitarProvider>(
      builder: (context, provider, _) {
        return ListView(
          padding: const EdgeInsets.all(8),
          children: [
            // Strum buttons
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStrumButton(
                      context,
                      provider,
                      isDown: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStrumButton(
                      context,
                      provider,
                      isDown: false,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF5C2A00)),

            // Chord list
            ...commonChords.map(
              (chord) => _buildChordTile(context, provider, chord),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStrumButton(
    BuildContext context,
    GuitarProvider provider, {
    required bool isDown,
  }) {
    return GestureDetector(
      onTap: () {
        if (provider.selectedChord != null) {
          provider.strumChord(provider.selectedChord!, downStrum: isDown);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: provider.selectedChord != null
              ? const Color(0xFF4CAF50).withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: provider.selectedChord != null
                ? const Color(0xFF4CAF50).withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Column(
          children: [
            Icon(
              isDown ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
              color: provider.selectedChord != null
                  ? const Color(0xFF4CAF50)
                  : Colors.white30,
              size: 24,
            ),
            Text(
              isDown ? 'Down' : 'Up',
              style: TextStyle(
                color: provider.selectedChord != null
                    ? const Color(0xFF4CAF50)
                    : Colors.white30,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChordTile(
    BuildContext context,
    GuitarProvider provider,
    GuitarChord chord,
  ) {
    final isSelected = provider.selectedChord?.name == chord.name;

    return GestureDetector(
      onTap: () {
        provider.selectChord(chord);
        provider.strumChord(chord);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4CAF50).withOpacity(0.15)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4CAF50).withOpacity(0.6)
                : const Color(0xFF5C2A00).withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            // Chord name
            Container(
              width: 52,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF4CAF50).withOpacity(0.3)
                    : const Color(0xFF3D2010).withOpacity(0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    chord.name,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFFDAA520),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Mini chord diagram
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: _MiniChordDiagram(chord: chord),
              ),
            ),
            // Play button
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                Icons.play_circle_outline,
                color: isSelected
                    ? const Color(0xFF4CAF50)
                    : Colors.white30,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniChordDiagram extends StatelessWidget {
  final GuitarChord chord;

  const _MiniChordDiagram({required this.chord});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: CustomPaint(
        painter: _MiniChordPainter(chord: chord),
      ),
    );
  }
}

class _MiniChordPainter extends CustomPainter {
  final GuitarChord chord;

  const _MiniChordPainter({required this.chord});

  @override
  void paint(Canvas canvas, Size size) {
    final stringSpacing = size.width / 5;
    final fretSpacing = size.height / 4;
    chord.frets.where((f) => f > 0).fold(0, (a, b) => a > b ? a : b);
    final minFret = chord.frets.where((f) => f > 0).fold(99, (a, b) => a < b ? a : b);

    // Draw fret lines
    final fretPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int f = 0; f <= 4; f++) {
      final y = f * fretSpacing;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), fretPaint);
    }

    // Draw strings
    final stringPaint = Paint()
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    for (int s = 0; s < 6; s++) {
      final x = s * stringSpacing;
      stringPaint.color = chord.frets[s] == -1
          ? Colors.red.withOpacity(0.5)
          : Colors.white.withOpacity(0.3);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), stringPaint);
    }

    // Draw fret markers
    final dotPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;

    final offset = minFret > 3 ? minFret - 1 : 0;

    for (int s = 0; s < 6; s++) {
      final fret = chord.frets[s];
      if (fret <= 0) {
        // Open (circle) or muted (X)
        final x = s * stringSpacing;
        if (fret == 0) {
          final openPaint = Paint()
            ..color = Colors.white.withOpacity(0.6)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke;
          canvas.drawCircle(Offset(x, -4), 3, openPaint);
        } else {
          final mutePaint = Paint()
            ..color = Colors.red.withOpacity(0.6)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke;
          canvas.drawLine(
            Offset(x - 3, -7), Offset(x + 3, -1), mutePaint);
          canvas.drawLine(
            Offset(x + 3, -7), Offset(x - 3, -1), mutePaint);
        }
      } else {
        final x = s * stringSpacing;
        final y = (fret - offset - 0.5) * fretSpacing;
        if (y > 0 && y < size.height) {
          canvas.drawCircle(Offset(x, y), 5, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_MiniChordPainter old) => old.chord != chord;
}
