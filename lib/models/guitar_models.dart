import 'package:flutter/material.dart';

// Guitar note model
class GuitarNote {
  final String name;
  final int octave;
  final int midiNumber;
  final String frequency;

  const GuitarNote({
    required this.name,
    required this.octave,
    required this.midiNumber,
    required this.frequency,
  });

  String get fullName => '$name$octave';
}

// Guitar string model
class GuitarString {
  final int index;
  final String openNote;
  final int openMidi;
  final Color stringColor;
  final double thickness;

  const GuitarString({
    required this.index,
    required this.openNote,
    required this.openMidi,
    required this.stringColor,
    required this.thickness,
  });

  String noteAtFret(int fret) {
    const noteNames = ['E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', 'C', 'C#', 'D', 'D#'];
    final openNoteIndex = noteNames.indexOf(openNote.replaceAll(RegExp(r'\d'), ''));
    final noteIndex = (openNoteIndex + fret) % 12;
    final octaveIncrease = (openNoteIndex + fret) ~/ 12;
    final openOctave = int.parse(openNote.substring(openNote.length - 1));
    return '${noteNames[noteIndex]}${openOctave + octaveIncrease}';
  }
}

const List<GuitarString> standardTuningStrings = [
  GuitarString(index: 0, openNote: 'E2', openMidi: 40, stringColor: Color(0xFFB8860B), thickness: 5.0),
  GuitarString(index: 1, openNote: 'A2', openMidi: 45, stringColor: Color(0xFFB8860B), thickness: 4.2),
  GuitarString(index: 2, openNote: 'D3', openMidi: 50, stringColor: Color(0xFFDAA520), thickness: 3.4),
  GuitarString(index: 3, openNote: 'G3', openMidi: 55, stringColor: Color(0xFFDAA520), thickness: 2.8),
  GuitarString(index: 4, openNote: 'B3', openMidi: 59, stringColor: Color(0xFFC0C0C0), thickness: 2.0),
  GuitarString(index: 5, openNote: 'E4', openMidi: 64, stringColor: Color(0xFFC0C0C0), thickness: 1.5),
];

// Chord model
class GuitarChord {
  final String name;
  final String fullName;
  final List<int> frets;
  final List<int?> fingers;
  final int startFret;

  const GuitarChord({
    required this.name,
    required this.fullName,
    required this.frets,
    required this.fingers,
    this.startFret = 1,
  });
}

const List<GuitarChord> commonChords = [
  GuitarChord(name: 'Em', fullName: 'E Minor', frets: [0, 2, 2, 0, 0, 0], fingers: [null, 2, 3, null, null, null]),
  GuitarChord(name: 'Am', fullName: 'A Minor', frets: [-1, 0, 2, 2, 1, 0], fingers: [null, null, 2, 3, 1, null]),
  GuitarChord(name: 'C', fullName: 'C Major', frets: [-1, 3, 2, 0, 1, 0], fingers: [null, 3, 2, null, 1, null]),
  GuitarChord(name: 'G', fullName: 'G Major', frets: [3, 2, 0, 0, 0, 3], fingers: [2, 1, null, null, null, 3]),
  GuitarChord(name: 'D', fullName: 'D Major', frets: [-1, -1, 0, 2, 3, 2], fingers: [null, null, null, 1, 3, 2]),
  GuitarChord(name: 'E', fullName: 'E Major', frets: [0, 2, 2, 1, 0, 0], fingers: [null, 2, 3, 1, null, null]),
  GuitarChord(name: 'A', fullName: 'A Major', frets: [-1, 0, 2, 2, 2, 0], fingers: [null, null, 1, 2, 3, null]),
  GuitarChord(name: 'F', fullName: 'F Major', frets: [1, 1, 2, 3, 3, 1], fingers: [1, 1, 2, 3, 4, 1]),
  GuitarChord(name: 'Dm', fullName: 'D Minor', frets: [-1, -1, 0, 2, 3, 1], fingers: [null, null, null, 2, 3, 1]),
  GuitarChord(name: 'B7', fullName: 'B Dominant 7th', frets: [-1, 2, 1, 2, 0, 2], fingers: [null, 2, 1, 3, null, 4]),
];

// Scale model
class GuitarScale {
  final String name;
  final String root;
  final List<int> intervals;

  const GuitarScale({required this.name, required this.root, required this.intervals});
}

const List<GuitarScale> commonScales = [
  GuitarScale(name: 'Major', root: 'C', intervals: [0, 2, 4, 5, 7, 9, 11]),
  GuitarScale(name: 'Natural Minor', root: 'A', intervals: [0, 2, 3, 5, 7, 8, 10]),
  GuitarScale(name: 'Pentatonic Major', root: 'G', intervals: [0, 2, 4, 7, 9]),
  GuitarScale(name: 'Pentatonic Minor', root: 'E', intervals: [0, 3, 5, 7, 10]),
  GuitarScale(name: 'Blues', root: 'A', intervals: [0, 3, 5, 6, 7, 10]),
  GuitarScale(name: 'Dorian', root: 'D', intervals: [0, 2, 3, 5, 7, 9, 10]),
];

// Tuning presets
class TuningPreset {
  final String name;
  final List<String> notes;

  const TuningPreset({required this.name, required this.notes});
}

const List<TuningPreset> tuningPresets = [
  TuningPreset(name: 'Standard (EADGBe)', notes: ['E2', 'A2', 'D3', 'G3', 'B3', 'E4']),
  TuningPreset(name: 'Drop D (DADGBe)', notes: ['D2', 'A2', 'D3', 'G3', 'B3', 'E4']),
  TuningPreset(name: 'Open G (DGDGBd)', notes: ['D2', 'G2', 'D3', 'G3', 'B3', 'D4']),
  TuningPreset(name: 'Open D (DADf#Ad)', notes: ['D2', 'A2', 'D3', 'F#3', 'A3', 'D4']),
  TuningPreset(name: 'DADGAD', notes: ['D2', 'A2', 'D3', 'G3', 'A3', 'D4']),
];
