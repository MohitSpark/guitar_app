#!/usr/bin/env python3
"""
Generate placeholder silent MP3 files for guitar notes.
For real guitar sounds, replace these with actual guitar note recordings.

MIDI note range for guitar: E2 (40) to E6 (88)
"""

import os
import struct

def create_silent_mp3(filename, duration_ms=500):
    """Create a minimal silent MP3 file."""
    # Minimal valid MP3 header (silent frame)
    # ID3 header
    id3 = b'ID3\x03\x00\x00\x00\x00\x00\x00'
    
    # MP3 frame header for 128kbps, 44100Hz, stereo
    # 0xFF 0xFB = sync + MPEG1 Layer3
    frame_header = bytes([0xFF, 0xFB, 0x90, 0x00])
    
    # Silent frame data (144 bytes of zeros)
    frame_data = bytes(144)
    
    num_frames = max(1, duration_ms // 26)  # ~26ms per frame at 128kbps
    
    with open(filename, 'wb') as f:
        f.write(id3)
        for _ in range(num_frames):
            f.write(frame_header)
            f.write(frame_data)

def main():
    sounds_dir = os.path.join(os.path.dirname(__file__), 'assets', 'sounds')
    os.makedirs(sounds_dir, exist_ok=True)
    
    print("Generating placeholder guitar note files...")
    
    # Guitar range: MIDI 40 (E2) to 88 (E6)
    for midi in range(40, 89):
        filename = os.path.join(sounds_dir, f'note_{midi}.mp3')
        if not os.path.exists(filename):
            create_silent_mp3(filename)
            print(f"  Created: note_{midi}.mp3")
    
    print(f"\nCreated {88-40+1} placeholder files in assets/sounds/")
    print("\nTo add real guitar sounds:")
    print("1. Download guitar note samples from freesound.org")
    print("2. Name them note_40.mp3 through note_88.mp3")
    print("3. Place in assets/sounds/")

if __name__ == '__main__':
    main()
