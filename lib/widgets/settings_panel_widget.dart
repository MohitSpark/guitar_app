import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/guitar_provider.dart';

class SettingsPanelWidget extends StatelessWidget {
  const SettingsPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GuitarProvider>(
      builder: (context, provider, _) {
        return ListView(
          padding: const EdgeInsets.all(10),
          children: [
            _buildSection('DISPLAY'),
            _buildToggleTile(
              title: 'Show Fret Numbers',
              subtitle: 'Display numbers above each fret',
              icon: Icons.format_list_numbered,
              value: provider.showFretNumbers,
              onChanged: (_) => provider.toggleFretNumbers(),
            ),
            _buildToggleTile(
              title: 'Show Note Names',
              subtitle: 'Display note names on the neck',
              icon: Icons.text_fields,
              value: provider.showNoteNames,
              onChanged: (_) => provider.toggleNoteNames(),
            ),
            _buildToggleTile(
              title: 'Left-Handed Mode',
              subtitle: 'Mirror the guitar for left-handed players',
              icon: Icons.swap_horiz,
              value: provider.leftHanded,
              onChanged: (_) => provider.toggleLeftHanded(),
            ),

            _buildSection('AUDIO'),
            _buildSliderTile(
              title: 'Volume',
              icon: Icons.volume_up,
              value: provider.volume,
              onChanged: (v) => provider.setVolume(v),
            ),
            _buildToggleTile(
              title: 'Mute',
              subtitle: 'Silence all guitar sounds',
              icon: Icons.volume_off,
              value: provider.isMuted,
              onChanged: (_) => provider.toggleMute(),
              activeColor: const Color(0xFFDAA520),
            ),

            _buildSection('FEEDBACK'),
            _buildToggleTile(
              title: 'Vibration',
              subtitle: 'Haptic feedback when playing notes',
              icon: Icons.vibration,
              value: provider.vibrateOnPlay,
              onChanged: (_) => provider.toggleVibrate(),
            ),

            _buildSection('ABOUT'),
            _buildInfoTile(
              title: 'Guitar Pro',
              subtitle: 'Version 1.0.0',
              icon: Icons.info_outline,
            ),
            _buildInfoTile(
              title: 'Standard Tuning',
              subtitle: 'E A D G B e (440 Hz)',
              icon: Icons.music_note,
            ),
            _buildInfoTile(
              title: '12 Frets Visible',
              subtitle: 'Swipe neck to navigate',
              icon: Icons.swipe,
            ),

            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _showResetDialog(context, provider),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.refresh, color: Colors.red, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Reset to Defaults',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFFDAA520),
          fontSize: 10,
          letterSpacing: 2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? activeColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: value
            ? (activeColor ?? const Color(0xFFDAA520)).withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value
              ? (activeColor ?? const Color(0xFFDAA520)).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
       child: Row(
         children: [
           Icon(icon,
               color: value
                   ? (activeColor ?? const Color(0xFFDAA520))
                   : Colors.white38,
               size: 16),
           const SizedBox(width: 8),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   title,
                   style: TextStyle(
                     color: value ? Colors.white : Colors.white54,
                     fontSize: 12,
                     fontWeight: FontWeight.w500,
                   ),
                   overflow: TextOverflow.ellipsis,
                 ),
                 Text(
                   subtitle,
                   style: const TextStyle(color: Colors.white54, fontSize: 9),
                   overflow: TextOverflow.ellipsis,
                 ),
               ],
             ),
           ),
           Switch(
             value: value,
             onChanged: onChanged,
             activeThumbColor: activeColor ?? const Color(0xFFDAA520),
             materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
           ),
         ],
       ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required IconData icon,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Row(
             children: [
               Icon(icon, color: const Color(0xFFDAA520), size: 16),
               const SizedBox(width: 8),
               Expanded(
                 child: Text(
                   title,
                   style: const TextStyle(color: Colors.white, fontSize: 12),
                   overflow: TextOverflow.ellipsis,
                 ),
               ),
               const SizedBox(width: 8),
               Text(
                 '${(value * 100).round()}%',
                 style: const TextStyle(color: Color(0xFFDAA520), fontSize: 12),
               ),
             ],
           ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              activeTrackColor: const Color(0xFFDAA520),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.15),
              thumbColor: const Color(0xFFDAA520),
            ),
            child: Slider(value: value, onChanged: onChanged),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(8),
      ),
       child: Row(
         children: [
           Icon(icon, color: Colors.white54, size: 14),
           const SizedBox(width: 10),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(title,
                     style: const TextStyle(color: Colors.white54, fontSize: 11),
                     overflow: TextOverflow.ellipsis),
                 Text(subtitle,
                     style: const TextStyle(color: Colors.white38, fontSize: 9),
                     overflow: TextOverflow.ellipsis),
               ],
             ),
           ),
         ],
       ),
    );
  }

  void _showResetDialog(BuildContext context, GuitarProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2d2d2d),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.refresh_rounded, color: Colors.redAccent, size: 20),
            SizedBox(width: 10),
            Text('Reset Settings?', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: const Text(
          'All settings will be restored to their defaults. This cannot be undone.',
          style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.6),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (provider.isMuted) provider.toggleMute();
              provider.setVolume(0.8);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
