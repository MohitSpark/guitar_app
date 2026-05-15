import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final List<AudioPlayer> _stringPlayers = [];
  static const int _numStrings = 6;

  double _volume = 0.8;
  bool _isMuted = false;
  bool _isInitialized = false;

  double get volume => _volume;
  bool get isMuted => _isMuted;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await rootBundle.load('assets/sounds/note_64.mp3');
      debugPrint('✅ Asset check passed');
    } catch (e) {
      debugPrint('❌ Asset check FAILED: $e');
      return;
    }

    try {
      // In v5.x, set global audio context ONCE before creating players
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.media,
            audioFocus: AndroidAudioFocus.gain,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: [
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions.defaultToSpeaker
            ],
          ),
        ),
      );

      for (int i = 0; i < _numStrings; i++) {
        final player = AudioPlayer();
        // Ensure player is stopped when finished and has correct volume
        await player.setReleaseMode(ReleaseMode.stop);
        await player.setVolume(_volume);
        _stringPlayers.add(player);
      }

      _isInitialized = true;
      debugPrint('AudioService ready with $_numStrings string players');
    } catch (e) {
      debugPrint('AudioService init error: $e');
      rethrow;
    }
  }

  Future<void> playNote(int stringIndex, int fret) async {
    if (_isMuted || !_isInitialized) {
      if (!_isInitialized) debugPrint('playNote: AudioService not initialized');
      return;
    }

    const openMidi = [40, 45, 50, 55, 59, 64];
    final midi = (openMidi[stringIndex] + fret).clamp(40, 88);
    final asset = _noteAssetPath(midi);

    try {
      final player = _stringPlayers[stringIndex % _numStrings];
      
      // For reliable rapid triggering, we stop and then play.
      // We don't await stop here to keep the UI thread moving, 
      // but play() will handle the interruption internally in most cases.
      player.stop().then((_) {
        player.play(AssetSource(asset), volume: _volume);
      });

      debugPrint('Playing string $stringIndex fret $fret -> $asset');
    } catch (e) {
      debugPrint('playNote error: $e');
    }
  }

  String _noteAssetPath(int midi) => 'sounds/note_$midi.mp3';

  Future<void> playChord(List<int> stringFrets) async {
    for (int i = 0; i < stringFrets.length; i++) {
      if (stringFrets[i] >= 0) {
        final si = i;
        final fret = stringFrets[i];
        Future.delayed(Duration(milliseconds: si * 30), () {
          playNote(si, fret);
        });
      }
    }
  }

  void setVolume(double vol) {
    _volume = vol.clamp(0.0, 1.0);
    if (!_isMuted) {
      for (final p in _stringPlayers) {
        p.setVolume(_volume);
      }
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    final target = _isMuted ? 0.0 : _volume;
    for (final p in _stringPlayers) {
      p.setVolume(target);
    }
  }

  void dispose() {
    for (final p in _stringPlayers) {
      p.dispose();
    }
    _stringPlayers.clear();
    _isInitialized = false;
  }
}