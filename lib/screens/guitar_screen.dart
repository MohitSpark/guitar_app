import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
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

  // --- Swipe hint ---
  bool _showSwipeHint = true;
  late AnimationController _hintFadeController;
  late Animation<double> _hintFadeAnimation;

  // Capo drag state
  double? _dragLeft;
  final GlobalKey _neckKey = GlobalKey();

  static const double _bodyWidth = 120.0;

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _hintFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _hintFadeAnimation = CurvedAnimation(
      parent: _hintFadeController,
      curve: Curves.easeOut,
    );
  }

  // Called from strum callbacks AND the hint overlay GestureDetector
  void _dismissHint() {
    if (!_showSwipeHint) return;
    _hintFadeController.forward().then((_) {
      if (mounted) {
        setState(() => _showSwipeHint = false);
      }
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _hintFadeController.dispose();
    super.dispose();
  }

  // ── Swipe hint overlay ────────────────────────────────────────────────────
  Widget _buildSwipeHint() {
    if (!_showSwipeHint) return const SizedBox.shrink();

    return Positioned.fill(
      child: FadeTransition(
        opacity: ReverseAnimation(_hintFadeAnimation),
        child: GestureDetector(
          // ANY touch anywhere on screen dismisses the hint
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _dismissHint(),
          onVerticalDragStart: (_) => _dismissHint(),
          onHorizontalDragStart: (_) => _dismissHint(),
          child: Container(
            color: Colors.black.withValues(alpha: 0.7),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rotated 90° so swipe-left reads as top↔bottom strum
                  Transform.rotate(
                    angle: 1.5708, // π/2 radians = 90°
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcATop,
                      ),
                      child: Lottie.asset(
                        'assets/animations/SwipeLeft.json',
                        width: 200,
                        height: 200,
                        repeat: true,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color:
                        const Color(0xFFDAA520).withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFDAA520)
                              .withValues(alpha: 0.2),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Text(
                      'Strum up or down to play',
                      style: TextStyle(
                        color: Color(0xFFDAA520),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tap anywhere to dismiss',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Panel helpers ─────────────────────────────────────────────────────────
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

  // ── Capo helpers ──────────────────────────────────────────────────────────
  double _fretToLeft(int fret, double neckWidth) {
    final fretWidth = neckWidth / 12;
    return _bodyWidth + (fret * fretWidth) - (fretWidth / 2);
  }

  Widget _buildDraggableCapo(double neckWidth) {
    return Consumer<GuitarProvider>(
      builder: (context, provider, _) {
        final bool isOff = provider.capoFret == 0;
        final double snappedLeft = _fretToLeft(provider.capoFret, neckWidth);
        final double displayLeft = _dragLeft ?? snappedLeft;

        final Duration animDuration = _dragLeft != null
            ? Duration.zero
            : const Duration(milliseconds: 700);

        final Curve animCurve =
        isOff ? Curves.easeInCubic : Curves.easeOutBack;

        return AnimatedPositioned(
          duration: animDuration,
          curve: animCurve,
          left: displayLeft,
          top: isOff ? neckWidth + 400 : 40,
          bottom: isOff ? -(neckWidth + 400) : 20,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (details) {
              if (isOff) return;
              setState(() => _dragLeft = snappedLeft);
            },
            onPanUpdate: (details) {
              if (isOff) return;
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
              provider.updateCapoOffset(
                  clampedLeft - _bodyWidth, neckWidth);
            },
            onPanEnd: (_) {
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
      width: 28,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDragging
              ? [
            const Color(0xFFFFE87C),
            const Color(0xFFDAA520),
            const Color(0xFFB8860B),
            const Color(0xFFDAA520),
            const Color(0xFFFFE87C)
          ]
              : [
            const Color(0xFFDAA520),
            const Color(0xFF8B6914),
            const Color(0xFFDAA520),
            const Color(0xFF8B6914),
            const Color(0xFFDAA520)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDragging ? Colors.white54 : Colors.white24,
          width: isDragging ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDAA520)
                .withValues(alpha: isDragging ? 0.6 : 0.25),
            blurRadius: isDragging ? 16 : 8,
            spreadRadius: isDragging ? 2 : 0,
          ),
          BoxShadow(
            color:
            Colors.black.withValues(alpha: isDragging ? 0.7 : 0.4),
            blurRadius: isDragging ? 12 : 6,
            offset: Offset(isDragging ? 6 : 3, 0),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _capoBolt(),
          ...List.generate(5, (i) => _capoRidge()),
          _capoBolt(),
        ],
      ),
    );
  }

  Widget _capoRidge() {
    return Container(
      height: 3,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _capoBolt() {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFFFFFFAA), Color(0xFFB8860B)],
          center: Alignment(-0.3, -0.3),
        ),
        border: Border.all(color: Colors.black45, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final double neckWidth = constraints.maxWidth -
              _bodyWidth -
              (_showSidePanel ? 280 : 70);

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

              // 3. Capo
              _buildDraggableCapo(neckWidth),

              // 4. Top bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildTopBar(),
              ),

              // 5. Swipe hint — on top, dismisses on ANY touch
              _buildSwipeHint(),
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
          _dismissHint();
          final provider = context.read<GuitarProvider>();
          if (provider.selectedChord != null) {
            provider.strumChord(provider.selectedChord!);
          }
        },
        onStrumUp: () {
          _dismissHint();
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
        color: const Color(0xFF1a0a00).withValues(alpha: 0.95),
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
                Expanded(
                  child: Text(
                    _sidePanelTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
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
          height: 35,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.8),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              const Text(
                '🎸 Guitar Pro',
                style: TextStyle(
                    color: Color(0xFFDAA520),
                    fontWeight: FontWeight.bold),
              ),
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
                  const Text(
                    "CAPO",
                    style:
                    TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: provider.capoFret > 0,
                      activeThumbColor: const Color(0xFFDAA520),
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