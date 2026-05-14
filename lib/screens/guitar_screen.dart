import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/guitar_provider.dart';
import '../widgets/guitar_body_widget.dart';
import '../widgets/guitar_neck_widget.dart';
import '../widgets/control_panel_widget.dart';
import '../widgets/chord_panel_widget.dart';
import '../widgets/scale_panel_widget.dart';
import '../widgets/settings_panel_widget.dart';
import '../widgets/tuner_widget.dart';

class GuitarScreen extends StatefulWidget {
  const GuitarScreen({super.key});

  @override
  State<GuitarScreen> createState() => _GuitarScreenState();
}

class _GuitarScreenState extends State<GuitarScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  bool _showSidePanel = false;
  Widget? _activeSidePanel;
  String _sidePanelTitle = '';

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  void _openPanel(String title, Widget panel) {
    setState(() {
      _showSidePanel = true;
      _sidePanelTitle = title;
      _activeSidePanel = panel;
    });
  }

  void _closePanel() {
    setState(() {
      _showSidePanel = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a0a00),
                  Color(0xFF2d1500),
                  Color(0xFF1a0a00),
                ],
              ),
            ),
          ),

          // Main guitar layout
          Row(
            children: [
              // Guitar body (left)
              SizedBox(
                width: 120,
                child: GuitarBodyWidget(
                  onStrumDown: () {
                    final provider = context.read<GuitarProvider>();
                    if (provider.selectedChord != null) {
                      provider.strumChord(provider.selectedChord!);
                    }
                  },
                  onStrumUp: () {
                    final provider = context.read<GuitarProvider>();
                    if (provider.selectedChord != null) {
                      provider.strumChord(provider.selectedChord!, downStrum: false);
                    }
                  },
                ),
              ),

              // Guitar neck (center/main)
              Expanded(
                child: const GuitarNeckWidget(),
              ),

              // Control panel (right)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: _showSidePanel ? 280 : 70,
                child: _showSidePanel
                    ? _buildSidePanel()
                    : ControlPanelWidget(
                        onChordsTap: () => _openPanel('Chords', const ChordPanelWidget()),
                        onScalesTap: () => _openPanel('Scales', const ScalePanelWidget()),
                        onTunerTap: () => _openPanel('Tuner', const TunerWidget()),
                        onSettingsTap: () => _openPanel('Settings', const SettingsPanelWidget()),
                      ),
              ),
            ],
          ),

          // Top status bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidePanel() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1a0a00).withOpacity(0.95),
        border: const Border(
          left: BorderSide(color: Color(0xFF8B4513), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Panel header
          Container(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 40, bottom: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B4513), Color(0xFF5C2A00)],
              ),
            ),
            child: Row(
              children: [
                Text(
                  _sidePanelTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _closePanel,
                  child: const Icon(Icons.close, color: Colors.white70, size: 24),
                ),
              ],
            ),
          ),
          // Panel content
          Expanded(child: _activeSidePanel ?? const SizedBox()),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Consumer<GuitarProvider>(
      builder: (context, provider, _) {
        return Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.transparent,
              ],
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              // App name
              const Text(
                '🎸 Guitar Pro',
                style: TextStyle(
                  color: Color(0xFFDAA520),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 16),
              // Current tuning
              Text(
                provider.currentTuning.name.split(' ').first,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              // Capo indicator
              if (provider.capoFret > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B4513).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Capo: ${provider.capoFret}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              const SizedBox(width: 8),
              // Recording indicator
              if (provider.isRecording)
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'REC',
                      style: TextStyle(color: Colors.red, fontSize: 11),
                    ),
                  ],
                ),
              const SizedBox(width: 8),
              // Mute indicator
              if (provider.isMuted)
                const Icon(Icons.volume_off, color: Colors.orange, size: 16),
              // Mode label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  provider.mode.name.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFFDAA520),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
