# Audio Extractor (macOS Native App)

A fast, lightweight, and native macOS application built with Swift and SwiftUI that allows you to drop any video file and instantly extract and save its audio track.

## Features

- **Drag & Drop**: Drag any video file directly into the app window, or click to browse.
- **Broad Video Support**: MP4, MOV, M4V, MKV, AVI, WebM, and more.
- **Format Options**:
  - **M4A (AAC)**: High quality, compressed, ideal for iPhone/iPad/Mac, podcasts, and mobile storage.
  - **WAV**: Uncompressed 16-bit 44.1 kHz PCM, lossless studio quality for audio editors and DAWs.
- **Video Inspection & Preview**:
  - Automatically generates a video thumbnail preview.
  - Shows file size, video resolution, duration, and detected audio tracks.
- **Built-in Audio Player**: Listen to and scrub through your extracted audio immediately inside the app.
- **One-Click Reveal**: Quickly jump to the newly saved audio file in Finder.
- **Multiple Output Destinations**:
  - Same directory as the video file.
  - Downloads folder.
  - Desktop.
  - Any custom folder of your choice.

## Quick Launch & Install

### 1. Launch the App Immediately
To open the app right now:
```bash
open "/Users/visualbyte/Downloads/ai-projects/mac audio app/build/AudioExtractor.app"
```

### 2. Install to Applications Folder
To install it permanently into your `/Applications` directory so it shows up in Launchpad and Spotlight:
```bash
cp -R "/Users/visualbyte/Downloads/ai-projects/mac audio app/build/AudioExtractor.app" /Applications/
```

### 3. Rebuild from Source
If you ever make changes to the source code:
```bash
./build.sh
```
Or to build and auto-install to `/Applications`:
```bash
./build.sh --install
```

## Architecture
- **Language**: Swift 6
- **UI Framework**: SwiftUI
- **Media Engine**: AVFoundation (`AVAssetExportSession`, `AVAssetReader`, `AVAssetWriter`, `AVAudioPlayer`)
- **App Bundle**: Standard macOS `.app` bundle with high-resolution retina iconset (`.icns`) and ad-hoc code signature.
