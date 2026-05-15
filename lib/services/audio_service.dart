import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final List<AudioPlayer> _pool = [];
  static const int _poolSize = 8;
  int _poolIndex = 0;

  double _volume = 0.8;
  bool _isMuted = false;
  bool _isInitialized = false;

  double get volume => _volume;
  bool get isMuted => _isMuted;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initializing AudioService...');

      for (int i = 0; i < _poolSize; i++) {
        final player = AudioPlayer();
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.setReleaseMode(ReleaseMode.release);
        await player.setVolume(_volume);
        _pool.add(player);
      }

      // Warm up: play a silent note so the audio engine is awake
      await _pool[0].setVolume(0.0);
      await _pool[0].play(AssetSource(_noteAssetPath(64)));
      await _pool[0].setVolume(_volume);

      _isInitialized = true;
      debugPrint('AudioService ready with $_poolSize players');
    } catch (e) {
      debugPrint('AudioService init error: $e');
      rethrow;
    }
  }

  Future<void> playNote(int stringIndex, int fret) async {
    if (_isMuted || !_isInitialized) return;

    // Base MIDI for open strings: E2=40 A2=45 D3=50 G3=55 B3=59 E4=64
    const openMidi = [40, 45, 50, 55, 59, 64];
    final midi = (openMidi[stringIndex] + fret).clamp(40, 88);
    final asset = _noteAssetPath(midi);

    try {
      // Round-robin pool — grab next player, DON'T stop it first
      // (stopping causes the audible gap/click)
      final player = _pool[_poolIndex % _poolSize];
      _poolIndex++;

      await player.setVolume(_volume);
      await player.play(AssetSource(asset));
    } catch (e) {
      debugPrint('playNote error (string $stringIndex fret $fret): $e');
    }
  }

  String _noteAssetPath(int midi) => 'sounds/note_$midi.mp3';

  Future<void> playChord(List<int> stringFrets) async {
    for (int i = 0; i < stringFrets.length; i++) {
      if (stringFrets[i] >= 0) {
        Future.delayed(Duration(milliseconds: i * 25), () {
          playNote(i, stringFrets[i]);
        });
      }
    }
  }

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    for (final p in _pool) {
      p.setVolume(_volume);
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    final target = _isMuted ? 0.0 : _volume;
    for (final p in _pool) {
      p.setVolume(target);
    }
  }

  void dispose() {
    for (final p in _pool) {
      p.dispose();
    }
    _isInitialized = false;
  }
}