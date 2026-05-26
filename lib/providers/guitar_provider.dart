import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/guitar_models.dart';
import '../services/audio_service.dart';

enum GuitarMode { play, chord, scale, tuner }
enum PickingStyle { strum, fingerpick, tap }

class GuitarProvider extends ChangeNotifier {
  final AudioService _audioService = AudioService();
  bool _isInitialized = false;

  // Current state
  GuitarMode _mode = GuitarMode.play;
  PickingStyle _pickingStyle = PickingStyle.strum;
  GuitarChord? _selectedChord;
  GuitarScale? _selectedScale;
  TuningPreset _currentTuning = tuningPresets[0];
  bool _showFretNumbers = true;
  bool _showNoteNames = false;
  bool _leftHanded = false;
  double _volume = 0.8;
  bool _isMuted = false;
  bool _vibrateOnPlay = true;
  int _capoFret = 0;
  bool _isRecording = false;
  List<_RecordedNote> _recordedNotes = [];
  DateTime? _recordingStart;

  // Highlighted frets (for scale/chord display)
  final Map<int, Set<int>> _highlightedFrets = {}; // stringIndex -> Set<fret>
  final Map<int, int> _pressedFrets = {}; // stringIndex -> fret

  // Active string being played
  int? _activeString;
  int? _activeFret;

  // Getters
  GuitarMode get mode => _mode;
  PickingStyle get pickingStyle => _pickingStyle;
  GuitarChord? get selectedChord => _selectedChord;
  GuitarScale? get selectedScale => _selectedScale;
  TuningPreset get currentTuning => _currentTuning;
  bool get showFretNumbers => _showFretNumbers;
  bool get showNoteNames => _showNoteNames;
  bool get leftHanded => _leftHanded;
  double get volume => _volume;
  bool get isMuted => _isMuted;
  bool get vibrateOnPlay => _vibrateOnPlay;
  int get capoFret => _capoFret;
  bool get isRecording => _isRecording;
  bool get isInitialized => _isInitialized;
  Map<int, Set<int>> get highlightedFrets => _highlightedFrets;
  Map<int, int> get pressedFrets => _pressedFrets;
  int? get activeString => _activeString;
  int? get activeFret => _activeFret;

// --- Add these variables to your existing GuitarProvider properties ---
  bool _isTunerActive = false;
  double _tuningCents = 0.0;
  String _autoDetectedNote = 'E2';
  bool _isProcessingVirtualNote = false;

// Getters so your Tuner UI can read them
  bool get isTunerActive => _isTunerActive;
  double get tuningCents => _tuningCents;
  String get autoDetectedNote => _autoDetectedNote;
  bool get isProcessingVirtualNote => _isProcessingVirtualNote;

// Toggle listening state
  void toggleTunerListening() {
    _isTunerActive = !_isTunerActive;
    if (!_isTunerActive) {
      _tuningCents = 0.0;
      _isProcessingVirtualNote = false;
    }
    notifyListeners();
  }

  void processVirtualNote(int stringIndex, double artificialDeviationCents) {
    _isProcessingVirtualNote = true;
    _autoDetectedNote = currentTuning.notes[stringIndex];
    _tuningCents = artificialDeviationCents;
    notifyListeners();

    // Reset the needle slowly back to center after 1.5 seconds of silence
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (_isTunerActive && _autoDetectedNote == currentTuning.notes[stringIndex]) {
        _tuningCents = 0.0;
        _isProcessingVirtualNote = false;
        notifyListeners();
      }
    });
  }

  GuitarProvider() {
    _init();
  }

  Future<void> _init() async {
    try {
      await _audioService.init();
      _isInitialized = true;
      await _loadPreferences();
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing audio service: $e');
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _volume = prefs.getDouble('volume') ?? 0.8;
    _showFretNumbers = prefs.getBool('showFretNumbers') ?? true;
    _showNoteNames = prefs.getBool('showNoteNames') ?? false;
    _leftHanded = prefs.getBool('leftHanded') ?? false;
    _vibrateOnPlay = prefs.getBool('vibrateOnPlay') ?? true;
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('volume', _volume);
    await prefs.setBool('showFretNumbers', _showFretNumbers);
    await prefs.setBool('showNoteNames', _showNoteNames);
    await prefs.setBool('leftHanded', _leftHanded);
    await prefs.setBool('vibrateOnPlay', _vibrateOnPlay);
  }

  void setMode(GuitarMode mode) {
    _mode = mode;
    _highlightedFrets.clear();
    _selectedChord = null;
    _selectedScale = null;
    notifyListeners();
  }

  void setPickingStyle(PickingStyle style) {
    _pickingStyle = style;
    notifyListeners();
  }

  Future<void> playString(int stringIndex, int fret) async {
    _activeString = stringIndex;
    _activeFret = fret;
    notifyListeners();

    // Haptic feedback
    if (_vibrateOnPlay) {
      HapticFeedback.lightImpact();
    }

    // --- Only calculate tuning values if the user turned the tuner on ---
    if (_isTunerActive) {
      final randomDeviation = (math.Random().nextDouble() * 20 - 10); // -10 to +10 cents
      processVirtualNote(stringIndex, randomDeviation);
    }

    // Play audio only if initialized
    if (_isInitialized) {
      await _audioService.playNote(stringIndex, fret);
    } else {
      debugPrint('Warning: Audio service not yet initialized, skipping audio');
    }

    // Record if in recording mode
    if (_isRecording && _recordingStart != null) {
      final elapsed = DateTime.now().difference(_recordingStart!).inMilliseconds;
      _recordedNotes.add(_RecordedNote(
        stringIndex: stringIndex,
        fret: fret,
        timestamp: elapsed,
      ));
    }

    // Reset active after a brief moment
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_activeString == stringIndex) {
        _activeString = null;
        _activeFret = null;
        notifyListeners();
      }
    });
  }

  Future<void> strumChord(GuitarChord chord, {bool downStrum = true}) async {
    final frets = chord.frets;
    if (_vibrateOnPlay) HapticFeedback.mediumImpact();

    for (int i = 0; i < frets.length; i++) {
      final stringIndex = downStrum ? i : (frets.length - 1 - i);
      if (frets[stringIndex] >= 0) {
        Future.delayed(Duration(milliseconds: i * 25), () {
          playString(stringIndex, frets[stringIndex] + _capoFret);
        });
      }
    }
  }

  void selectChord(GuitarChord chord) {
    _selectedChord = chord;
    _highlightChord(chord);
    notifyListeners();
  }

  void _highlightChord(GuitarChord chord) {
    _highlightedFrets.clear();
    for (int i = 0; i < chord.frets.length; i++) {
      if (chord.frets[i] > 0) {
        _highlightedFrets[i] = {chord.frets[i]};
      }
    }
    notifyListeners();
  }

  void selectScale(GuitarScale scale) {
    _selectedScale = scale;
    _highlightScale(scale);
    notifyListeners();
  }

  void _highlightScale(GuitarScale scale) {
    _highlightedFrets.clear();
    const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    final rootIndex = noteNames.indexOf(scale.root);

    for (int s = 0; s < 6; s++) {
      final openNote = currentTuning.notes[s].replaceAll(RegExp(r'\d'), '');
      final openIndex = noteNames.indexOf(openNote);

      _highlightedFrets[s] = {};
      for (int fret = 0; fret <= 12; fret++) {
        final noteIndex = (openIndex + fret) % 12;
        final relativeToRoot = (noteIndex - rootIndex + 12) % 12;
        if (scale.intervals.contains(relativeToRoot)) {
          _highlightedFrets[s]!.add(fret);
        }
      }
    }
    notifyListeners();
  }

  void setCapo(int fret) {
    _capoFret = fret;
    notifyListeners();
  }

  void setVolume(double vol) {
    _volume = vol;
    _audioService.setVolume(vol);
    _savePreferences();
    notifyListeners();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    _audioService.toggleMute();
    notifyListeners();
  }

  void toggleFretNumbers() {
    _showFretNumbers = !_showFretNumbers;
    _savePreferences();
    notifyListeners();
  }

  void toggleNoteNames() {
    _showNoteNames = !_showNoteNames;
    _savePreferences();
    notifyListeners();
  }

  void toggleLeftHanded() {
    _leftHanded = !_leftHanded;
    _savePreferences();
    notifyListeners();
  }

  void toggleVibrate() {
    _vibrateOnPlay = !_vibrateOnPlay;
    _savePreferences();
    notifyListeners();
  }

  void setTuning(TuningPreset tuning) {
    _currentTuning = tuning;
    if (_selectedScale != null) _highlightScale(_selectedScale!);
    notifyListeners();
  }

  void startRecording() {
    _isRecording = true;
    _recordedNotes.clear();
    _recordingStart = DateTime.now();
    notifyListeners();
  }

  void stopRecording() {
    _isRecording = false;
    notifyListeners();
  }

  Future<void> playRecording() async {
    if (_recordedNotes.isEmpty) return;
    for (final note in _recordedNotes) {
      Future.delayed(Duration(milliseconds: note.timestamp), () {
        playString(note.stringIndex, note.fret);
      });
    }
  }

  // Inside GuitarProvider class
  void updateCapoOffset(double localX, double totalNeckWidth) {
    double fretWidth = totalNeckWidth / 12;
    int newFret = (localX / fretWidth).round().clamp(1, 12);

    // ONLY notify if the fret actually changes
    if (newFret != _capoFret) {
      _capoFret = newFret;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}

class _RecordedNote {
  final int stringIndex;
  final int fret;
  final int timestamp;

  _RecordedNote({
    required this.stringIndex,
    required this.fret,
    required this.timestamp,
  });
}
