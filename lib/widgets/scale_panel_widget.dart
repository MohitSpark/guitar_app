import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/guitar_provider.dart';
import '../models/guitar_models.dart';

class ScalePanelWidget extends StatelessWidget {
  const ScalePanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GuitarProvider>(
      builder: (context, provider, _) {
        return ListView(
          padding: const EdgeInsets.all(10),
          children: [
            const Text(
              'SELECT A SCALE',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...commonScales.map(
              (scale) => _buildScaleTile(context, provider, scale),
            ),
            const SizedBox(height: 16),
            const Text(
              'TUNING',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...tuningPresets.map(
              (tuning) => _buildTuningTile(context, provider, tuning),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScaleTile(
    BuildContext context,
    GuitarProvider provider,
    GuitarScale scale,
  ) {
    final isSelected = provider.selectedScale?.name == scale.name &&
        provider.selectedScale?.root == scale.root;

    return GestureDetector(
      onTap: () => provider.selectScale(scale),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2196F3).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2196F3).withValues(alpha: 0.5)
                : const Color(0xFF5C2A00).withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2196F3).withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  scale.root,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF2196F3)
                        : const Color(0xFFDAA520),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${scale.root} ${scale.name}',
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF2196F3) : Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _getScaleIntervalNames(scale.intervals),
                    style: const TextStyle(
                      color: Colors.white30,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF2196F3),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTuningTile(
    BuildContext context,
    GuitarProvider provider,
    TuningPreset tuning,
  ) {
    final isSelected = provider.currentTuning.name == tuning.name;

    return GestureDetector(
      onTap: () => provider.setTuning(tuning),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF9800).withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF9800).withValues(alpha: 0.4)
                : const Color(0xFF5C2A00).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.music_note,
              color: isSelected ? const Color(0xFFFF9800) : Colors.white30,
              size: 14,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tuning.name,
                style: TextStyle(
                  color: isSelected ? const Color(0xFFFF9800) : Colors.white54,
                  fontSize: 11,
                ),
              ),
            ),
            Text(
              tuning.notes.map((n) => n.replaceAll(RegExp(r'\d'), '')).join(' '),
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFFFF9800).withValues(alpha: 0.7)
                    : Colors.white24,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getScaleIntervalNames(List<int> intervals) {
    const names = {
      0: 'R',
      1: 'b2',
      2: '2',
      3: 'b3',
      4: '3',
      5: '4',
      6: 'b5',
      7: '5',
      8: 'b6',
      9: '6',
      10: 'b7',
      11: '7',
    };
    return intervals.map((i) => names[i] ?? '$i').join(' - ');
  }
}
