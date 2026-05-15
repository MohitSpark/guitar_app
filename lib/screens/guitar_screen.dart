import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Capo drag state
  // _dragLeft holds the raw pixel position ONLY while finger is down.
  // When null, the capo snaps to its provider fret position.
  double? _dragLeft;
  final GlobalKey _neckKey = GlobalKey(); // Used for accurate local offset

  static const double _bodyWidth = 120.0;

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

  // Returns the pixel left edge for a given capo fret, centred in that fret slot.
  double _fretToLeft(int fret, double neckWidth) {
    final fretWidth = neckWidth / 12;
    return _bodyWidth + (fret * fretWidth) - (fretWidth / 2);
  }

  Widget _buildDraggableCapo(double neckWidth) {
    return Consumer<GuitarProvider>(
      builder: (context, provider, _) {
        final bool isOff = provider.capoFret == 0;

        // The logical (snapped) position comes from the provider.
        final double snappedLeft = _fretToLeft(provider.capoFret, neckWidth);

        // While dragging we use _dragLeft for pixel-perfect tracking.
        // Once the finger lifts, _dragLeft is null and we animate to snappedLeft.
        final double displayLeft = _dragLeft ?? snappedLeft;

        // Separate durations: instant while dragging, slow for toggle, fast for fret-snap
        final Duration animDuration = _dragLeft != null
            ? Duration.zero          // finger down  → no interpolation
            : isOff
            ? const Duration(milliseconds: 700)  // sliding OFF  → slow fall
            : const Duration(milliseconds: 700); // sliding ON   → slow rise

        final Curve animCurve = isOff
            ? Curves.easeInCubic     // accelerates as it falls away
            : Curves.easeOutBack;    // slight bounce when landing

        return AnimatedPositioned(
          duration: animDuration,
          curve: animCurve,
          left: displayLeft,
          // Slide in from below when ON, slide down off-screen when OFF
          top: isOff ? neckWidth + 400 : 40,   // neckWidth is always large enough to be off-screen
          bottom: isOff ? -(neckWidth + 400) : 20,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              if (isOff) return;
              // Initialise drag at the current snapped position so there's no jump.
              setState(() => _dragLeft = snappedLeft);
            },
            onPanUpdate: (details) {
              if (isOff) return;

              // Use the Stack's RenderBox so coordinates are relative to the
              // same origin that AnimatedPositioned uses.
              final RenderBox? stackBox =
              context.findAncestorRenderObjectOfType<RenderBox>();
              if (stackBox == null) return;

              final localPos =
              stackBox.globalToLocal(details.globalPosition);

              final double clampedLeft = localPos.dx.clamp(
                _bodyWidth,
                _bodyWidth + neckWidth,
              );

              setState(() => _dragLeft = clampedLeft);

              // Update logical fret in provider (drives audio, highlights, etc.)
              provider.updateCapoOffset(
                  clampedLeft - _bodyWidth, neckWidth);
            },
            onPanEnd: (_) {
              // Drop _dragLeft → triggers the snap-to-fret animation.
              setState(() => _dragLeft = null);
              HapticFeedback.mediumImpact();
            },
            child: _capoVisual(isDragging: _dragLeft != null),
          ),
        );
      },
    );
  }

  Widget _capoVisual({bool isDragging = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 36,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDAA520), Color(0xFF8B4513), Color(0xFFDAA520)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDragging ? 0.85 : 0.5),
            blurRadius: isDragging ? 24 : 10,
            offset: Offset(isDragging ? 10 : 4, 0),
          ),
        ],
      ),
      child: Center(
        child: Container(width: 4, color: Colors.black45),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double neckWidth =
              constraints.maxWidth - _bodyWidth - (_showSidePanel ? 280 : 70);

          return Stack(
            children: [
              // 1. Background
              Container(color: const Color(0xFF1a0a00)),

              // 2. Main Guitar Row
              Row(
                children: [
                  _buildBodyWidget(),
                  Expanded(
                    key: _neckKey,
                    child: const GuitarNeckWidget(),
                  ),
                  _buildControlPanel(),
                ],
              ),

              // 3. Capo — single, clean implementation
              _buildDraggableCapo(neckWidth),

              // 4. Top bar overlay
              Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildTopBar()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBodyWidget() {
    return SizedBox(
      width: _bodyWidth,
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
    );
  }

  Widget _buildControlPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _showSidePanel ? 280 : 70,
      child: _showSidePanel
          ? _buildSidePanel()
          : ControlPanelWidget(
        onChordsTap: () =>
            _openPanel('Chords', const ChordPanelWidget()),
        onScalesTap: () =>
            _openPanel('Scales', const ScalePanelWidget()),
        onTunerTap: () =>
            _openPanel('Tuner', const TunerWidget()),
        onSettingsTap: () =>
            _openPanel('Settings', const SettingsPanelWidget()),
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
          Container(
            padding: const EdgeInsets.only(
                left: 12, right: 12, top: 40, bottom: 10),
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
                  child: const Icon(Icons.close,
                      color: Colors.white70, size: 24),
                ),
              ],
            ),
          ),
          Expanded(child: _activeSidePanel ?? const SizedBox()),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Consumer<GuitarProvider>(
      builder: (context, provider, _) {
        return Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              const Text('🎸 Guitar Pro',
                  style: TextStyle(
                      color: Color(0xFFDAA520),
                      fontWeight: FontWeight.bold)),
              const Spacer(),
              Row(
                children: [
                  Text(
                    provider.capoFret > 0
                        ? "Fret ${provider.capoFret}"
                        : "OFF",
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  const Text("CAPO",
                      style: TextStyle(
                          color: Colors.white, fontSize: 10)),
                  Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: provider.capoFret > 0,
                      activeColor: const Color(0xFFDAA520),
                      onChanged: (isOn) =>
                          provider.setCapo(isOn ? 1 : 0),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}