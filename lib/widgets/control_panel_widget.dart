import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/guitar_provider.dart';

class ControlPanelWidget extends StatelessWidget {
  final VoidCallback onChordsTap;
  final VoidCallback onScalesTap;
  final VoidCallback onTunerTap;
  final VoidCallback onSettingsTap;

  const ControlPanelWidget({
    super.key,
    required this.onChordsTap,
    required this.onScalesTap,
    required this.onTunerTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<GuitarProvider>(
      builder: (context, provider, _) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1a0a00), Color(0xFF2d1500)],
            ),
            border: Border(
              left: BorderSide(color: Color(0xFF5C2A00), width: 1),
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,  // change from spaceEvenly
              children: [
                const SizedBox(height: 36),

                _buildControlButton(
                  icon: Icons.music_note,
                  label: 'Chords',
                  color: const Color(0xFF4CAF50),
                  onTap: onChordsTap,
                  isActive: provider.selectedChord != null,
                ),
                _buildControlButton(
                  icon: Icons.piano,
                  label: 'Scales',
                  color: const Color(0xFF2196F3),
                  onTap: onScalesTap,
                  isActive: provider.selectedScale != null,
                ),
                _buildControlButton(
                  icon: Icons.tune,
                  label: 'Tuner',
                  color: const Color(0xFFFF9800),
                  onTap: onTunerTap,
                ),

                const Divider(color: Color(0xFF5C2A00), height: 1),

                _buildSmallButton(
                  icon: provider.showFretNumbers ? Icons.grid_on : Icons.grid_off,
                  label: 'Frets',
                  onTap: () => provider.toggleFretNumbers(),
                  isActive: provider.showFretNumbers,
                ),
                _buildSmallButton(
                  icon: Icons.text_fields,
                  label: 'Notes',
                  onTap: () => provider.toggleNoteNames(),
                  isActive: provider.showNoteNames,
                ),
                _buildSmallButton(
                  icon: Icons.swap_horiz,
                  label: provider.leftHanded ? 'Left' : 'Right',
                  onTap: () => provider.toggleLeftHanded(),
                  isActive: provider.leftHanded,
                ),

                const Divider(color: Color(0xFF5C2A00), height: 1),

                _buildSmallButton(
                  icon: Icons.play_arrow,
                  label: 'Play',
                  onTap: () => provider.playRecording(),
                  isActive: false,
                  color: const Color(0xFFDAA520),
                ),

                _buildControlButton(
                  icon: Icons.settings,
                  label: 'Settings',
                  color: Colors.white54,
                  onTap: onSettingsTap,
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.25) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? color.withOpacity(0.7) : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? color : Colors.white60, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : Colors.white38,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isActive,
    Color? color,
  }) {
    final activeColor = color ?? const Color(0xFFDAA520);
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : Colors.white30,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : Colors.white30,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


