# Audio Extractor (macOS Native App)

A fast, lightweight, and native macOS application built with Swift and SwiftUI that allows you to drop any video file and instantly extract and save its audio track.

## Features

- **Modern macOS Unified Toolbar**: Blends seamlessly into macOS with centered document title, file specifications, format & resolution badges, and native keyboard shortcuts (`⌘O`, `⌘R`, `⌘S`).
- **Drag & Drop**: Drag any video file directly into the app window, or click to browse.
- **Broad Video Support**: MP4, MOV, M4V, MKV, AVI, WebM, and more.
- **Format Options**:
  - **M4A (AAC)**: High quality, compressed, ideal for iPhone/iPad/Mac, podcasts, and mobile storage.
  - **WAV**: Uncompressed 16-bit 44.1 kHz PCM, lossless studio quality for audio editors and DAWs.
- **Video Inspection & Preview**:
  - Automatically generates an unletterboxed 16:9 video thumbnail preview.
  - Shows file size, video resolution, duration, and detected audio tracks.
- **Built-in Audio Player**: Listen to and scrub through your extracted audio immediately inside the app with live waveform visualization.
- **Tactile Sound Effects**: Custom acoustic cues on video load, file ejection, and export completion.
- **Consistent Window Geometry**: Guaranteed launch size and smooth animated transition when inspecting media.

## Installation & First-Time Launch (macOS Gatekeeper)

### Option 1: Install via DMG (Recommended)
1. Download the disk image matching your Mac architecture:
   - **Apple Silicon (M1/M2/M3/M4)**: `SonicExtractor-AppleSilicon-arm64.dmg`
   - **Intel Macs (x86_64)**: `SonicExtractor-Intel-x86_64.dmg`
2. Double-click the DMG to open it, and drag **AudioExtractor** into the **Applications** folder shortcut.
3. Unmount/eject the DMG.

### First-Time Launch (One-Time macOS Security Approval)
Because AudioExtractor is a standalone open-source app distributed directly outside the Mac App Store:

1. Double-click **AudioExtractor** in your Applications folder.
2. macOS will show an alert:
   > **"Apple could not verify 'AudioExtractor' is free of malware that may harm your Mac."**
3. Click **Done** *(do NOT click "Move to Bin" / "Move to Trash")*.
4. Open **System Settings** $\to$ **Privacy & Security**.
5. Scroll down to the **Security** section.
6. Under *"AudioExtractor was blocked from use because it is not from an identified developer"*, click **Open Anyway**.
7. Enter your Mac password or Touch ID, then click **Open** when prompted.

> [!NOTE]
> You only need to do this once. macOS permanently remembers the approval and AudioExtractor will open normally from then on.

For power users who prefer Terminal:
```bash
xattr -dr com.apple.quarantine /Applications/AudioExtractor.app
```

---

## Building from Source

AudioExtractor builds as a **Universal Fat Binary** (`arm64` + `x86_64`), running natively on both Apple Silicon and Intel Macs with zero emulation overhead.

### 1. Build Universal App Bundle
```bash
./build.sh
```
*(Optionally specify architecture: `./build.sh arm64` or `./build.sh x86_64`)*

### 2. Build Distributable DMG
```bash
./scripts/create_dmg.sh
```
This generates a compressed, signed `dist/SonicExtractor.dmg` containing the application, `/Applications` drag-and-drop symlink, and `First-Time Launch Guide.txt`.

---

## Architecture & Tech Stack
- **Language**: Swift 6
- **UI Framework**: SwiftUI
- **Media Engine**: AVFoundation (`AVAssetExportSession`, `AVAssetReader`, `AVAssetWriter`, `AVAudioPlayer`)
- **Binary Architecture**: Universal 2 (`arm64` Apple Silicon + `x86_64` Intel) via `lipo`
- **Minimum Target**: macOS 14.0 (Sonoma) and macOS 15.0+ (Sequoia)
- **App Bundle**: Standard macOS `.app` bundle with high-resolution retina iconset (`.icns`) and ad-hoc code signature.
