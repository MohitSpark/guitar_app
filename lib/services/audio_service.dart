import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final List<AudioPlayer> _players = [];
  final int _maxPlayers = 12;
  int _currentPlayerIndex = 0;
  double _volume = 0.8;
  bool _isMuted = false;
  bool _isInitialized = false;

  double get volume => _volume;
  bool get isMuted => _isMuted;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    try {
      if (_isInitialized) {
        debugPrint('Audio service already initialized');
        return;
      }

      debugPrint('Initializing audio service...');
      for (int i = 0; i < _maxPlayers; i++) {
        final player = AudioPlayer();
        // Use low latency for responsive guitar playing
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setVolume(_volume);
        _players.add(player);
      }
      _isInitialized = true;
      debugPrint('Audio service initialized successfully with $_maxPlayers players');
    } catch (e) {
      debugPrint('Error initializing audio service: $e');
      rethrow;
    }
  }

  Future<void> playNote(int stringIndex, int fret) async {
    if (_isMuted) {
      debugPrint('Audio is muted');
      return;
    }

    if (!_isInitialized) {
      debugPrint('Audio service not initialized yet');
      return;
    }

    try {
      final player = _players[_currentPlayerIndex % _maxPlayers];
      _currentPlayerIndex++;

      // Map string + fret to a MIDI-like note index
      // Base MIDI notes for open strings: E2=40, A2=45, D3=50, G3=55, B3=59, E4=64
      const openMidi = [40, 45, 50, 55, 59, 64];
      final midiNote = openMidi[stringIndex] + fret;

      final effectiveVolume = _isMuted ? 0.0 : _volume;
      await player.setVolume(effectiveVolume);

      // Play a note from assets
      final noteFile = _getNoteAssetPath(midiNote);
      debugPrint('Playing note: $noteFile (String: $stringIndex, Fret: $fret, MIDI: $midiNote, Volume: $effectiveVolume)');

      // Release any previous audio first to ensure clean playback
      await player.stop();
      await Future.delayed(const Duration(milliseconds: 10));

      await player.play(AssetSource(noteFile));
      debugPrint('Audio playback started for note $midiNote');
    } catch (e) {
      debugPrint('Audio error playing note: $e');
    }
  }

  String _getNoteAssetPath(int midiNote) {
    // Map MIDI notes to bundled asset files
    // Standard guitar range: ~E2 (40) to ~E6 (88)
    final clampedNote = midiNote.clamp(40, 88);
    return 'sounds/note_$clampedNote.mp3';
  }

  Future<void> playChord(List<int> stringFrets) async {
    for (int i = 0; i < stringFrets.length; i++) {
      if (stringFrets[i] >= 0) {
        await Future.delayed(Duration(milliseconds: i * 30));
        await playNote(i, stringFrets[i]);
      }
    }
  }

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    debugPrint('Setting volume to $_volume');
    for (final player in _players) {
      player.setVolume(_volume);
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    debugPrint('Mute toggled: $_isMuted');
    if (_isMuted) {
      for (final player in _players) {
        player.setVolume(0.0);
      }
    } else {
      setVolume(_volume);
    }
  }

  void dispose() {
    for (final player in _players) {
      player.dispose();
    }
    _isInitialized = false;
  }
}


