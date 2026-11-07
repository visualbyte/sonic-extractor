<div align="center">
  <img src="assets/icon.png" width="128" height="128" alt="SonicExtractor Icon" />
  <h1>SonicExtractor</h1>
  <p><strong>A sleek, high-fidelity macOS desktop utility to extract audio tracks from any video.</strong></p>

  <p>
    <a href="https://github.com/visualbyte/sonic-extractor/releases/latest">
      <img src="https://img.shields.io/github/v/release/visualbyte/sonic-extractor?color=1487FF&label=Latest%20Release" alt="Latest Release" />
    </a>
    <img src="https://img.shields.io/badge/Platform-macOS%2014.0%2B-black" alt="Platform: macOS 14.0+" />
    <img src="https://img.shields.io/badge/Architecture-Universal%20(arm64%20%7C%20x86__64)-blue" alt="Architecture" />
    <img src="https://img.shields.io/badge/License-Proprietary-gray" alt="License" />
  </p>

  <p>
    <a href="https://github.com/visualbyte/sonic-extractor/releases/latest/download/SonicExtractor.dmg">
      <img src="https://img.shields.io/badge/⬇%20Download-SonicExtractor.dmg%20(Universal)-1487FF?style=for-the-badge" height="42" alt="Download SonicExtractor Universal DMG" />
    </a>
  </p>
  <p>
    <small>Runs natively on both Apple Silicon (M1/M2/M3/M4) & Intel Macs</small>
  </p>
</div>

<br/>

---

## ✨ Features

- **⚡️ Zero-Friction Workflow**: Drag and drop any video file onto the canvas, or select via the native macOS file picker.
- **🎬 Wide Format Support**: Compatible with MP4, MOV, MKV, AVI, WebM, and all common video containers.
- **🌊 Interactive Waveform & Scrubbing**: Live audio waveform visualization with scrubbing and instant playback transport ring.
- **🎵 High-Fidelity Audio**: Direct, lossless extraction to standard `M4A (AAC)` format powered natively by Apple's AVFoundation engine.
- **🎯 16:9 Unletterboxed Thumbnail**: Automatically detects and crops camera container borders (e.g., Canon EOS EXIF letterboxing) so video previews maintain exact 16:9 proportions.
- **✨ Tactile Acoustic Feedback**: Custom acoustic cues for video load, close/dismiss, and export success.
- **🪄 Seamless Window Transitions**: Fluid top-anchored window expansion between the compact drop zone and the expanded audio studio.

---

## 📸 Screenshots

<div align="center">
  <h3>Stage 1 — Minimalist Drop Zone</h3>
  <img src="assets/screen1-dropzone.jpg" width="600" alt="SonicExtractor Drop Zone" />

  <br/><br/>

  <h3>Stage 2 — Expanded Audio Studio</h3>
  <img src="assets/screen2-studio.jpg" width="600" alt="SonicExtractor Audio Studio" />
</div>

---

## 📦 Installation

### 1. Download
- **[Download SonicExtractor.dmg (Universal)](https://github.com/visualbyte/sonic-extractor/releases/latest/download/SonicExtractor.dmg)** *(Recommended: runs natively on Apple Silicon and Intel)*
- Dedicated architecture builds:
  - **[Apple Silicon (M1/M2/M3/M4/M5)](https://github.com/visualbyte/sonic-extractor/releases/latest/download/SonicExtractor-AppleSilicon-arm64.dmg)**
  - **[Intel (x86_64)](https://github.com/visualbyte/sonic-extractor/releases/latest/download/SonicExtractor-Intel-x86_64.dmg)**

### 2. Install
Open the downloaded `.dmg` and drag **AudioExtractor** into the **Applications** shortcut folder.

### 3. First-Time Launch (One-Time macOS Approval)
Because SonicExtractor is an independent application distributed directly outside the Mac App Store:

1. Double-click **AudioExtractor** in your Applications folder.
2. macOS will show a security prompt:
   > *"Apple could not verify 'AudioExtractor' is free of malware that may harm your Mac."*
3. Click **Done** *(do NOT click "Move to Bin" / "Move to Trash")*.
4. Open **System Settings** → **Privacy & Security**.
5. Scroll down to the **Security** section.
6. Under *"AudioExtractor was blocked from use because it is not from an identified developer"*, click **Open Anyway**.
7. Enter your Touch ID or Mac administrator password, then click **Open**.

> [!NOTE]
> macOS permanently remembers your approval after this single step. You will never be asked again!

For advanced users comfortable with Terminal:
```bash
xattr -dr com.apple.quarantine /Applications/AudioExtractor.app
```

---

## 💻 System Requirements

- **Operating System**: macOS 14.0 (Sonoma) or macOS 15.0 (Sequoia) and later.
- **Hardware**: Apple Silicon (All M-Series chips) or Intel Mac (x86_64).

---

<div align="center">
  <p>Crafted with precision for macOS by <a href="https://github.com/visualbyte">Vishal Gupta</a>.</p>
</div>
