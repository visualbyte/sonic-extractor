import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Native Persistent Custom Cursor View
final class CustomCursorAreaView: NSView {
    var cursor: NSCursor = .arrow
    var onClick: (() -> Void)?
    var onHoverChange: ((Bool) -> Void)?
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.invalidateCursorRects(for: self)
    }
    
    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        window?.invalidateCursorRects(for: self)
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.cursorUpdate, .activeInKeyWindow, .inVisibleRect, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
    }
    
    override func cursorUpdate(with event: NSEvent) {
        cursor.set()
    }
    
    override func resetCursorRects() {
        discardCursorRects()
        addCursorRect(bounds, cursor: cursor)
    }
    
    override func mouseEntered(with event: NSEvent) {
        cursor.set()
        onHoverChange?(true)
    }
    
    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
        onHoverChange?(false)
    }
    
    override func mouseDown(with event: NSEvent) {
        onClick?()
    }
}

struct CustomCursorArea: NSViewRepresentable {
    let cursor: NSCursor
    var onHover: ((Bool) -> Void)? = nil
    var onClick: (() -> Void)? = nil
    
    func makeNSView(context: Context) -> CustomCursorAreaView {
        let view = CustomCursorAreaView()
        view.cursor = cursor
        view.onClick = onClick
        view.onHoverChange = onHover
        return view
    }
    
    func updateNSView(_ nsView: CustomCursorAreaView, context: Context) {
        nsView.cursor = cursor
        nsView.onClick = onClick
        nsView.onHoverChange = onHover
    }
}

// MARK: - Custom Close Cursor Definition
enum CustomCursor {
    static let close: NSCursor = {
        let size = NSSize(width: 24, height: 24)
        let img = NSImage(size: size, flipped: false) { rect in
            // Outer semi-transparent dark circle
            let bgCircle = NSBezierPath(ovalIn: NSRect(x: 2, y: 2, width: 20, height: 20))
            NSColor(red: 0.10, green: 0.10, blue: 0.12, alpha: 0.90).setFill()
            bgCircle.fill()
            
            // White outline
            NSColor.white.withAlphaComponent(0.92).setStroke()
            bgCircle.lineWidth = 1.3
            bgCircle.stroke()
            
            // Crisp White X
            let xPath = NSBezierPath()
            let inset: CGFloat = 8.0
            xPath.move(to: NSPoint(x: inset, y: inset))
            xPath.line(to: NSPoint(x: size.width - inset, y: size.height - inset))
            xPath.move(to: NSPoint(x: inset, y: size.height - inset))
            xPath.line(to: NSPoint(x: size.width - inset, y: inset))
            NSColor.white.setStroke()
            xPath.lineWidth = 1.8
            xPath.lineCapStyle = .round
            xPath.stroke()
            
            return true
        }
        return NSCursor(image: img, hotSpot: NSPoint(x: 12, y: 12))
    }()
}

// MARK: - App Audio Feedback
enum AppSound {
    private static var popSound: NSSound? = {
        if let url = Bundle.main.url(forResource: "pop", withExtension: "wav") {
            return NSSound(contentsOf: url, byReference: true)
        }
        return NSSound(named: "pop")
    }()
    
    private static var removeSound: NSSound? = {
        if let url = Bundle.main.url(forResource: "remove", withExtension: "wav") {
            return NSSound(contentsOf: url, byReference: true)
        }
        return NSSound(named: "remove")
    }()
    
    private static var saveSound: NSSound? = {
        if let url = Bundle.main.url(forResource: "save", withExtension: "wav") {
            return NSSound(contentsOf: url, byReference: true)
        }
        return NSSound(named: "save")
    }()
    
    static func playPop() {
        popSound?.stop()
        popSound?.play()
    }
    
    static func playRemove() {
        removeSound?.stop()
        removeSound?.play()
    }
    
    static func playSave() {
        saveSound?.stop()
        saveSound?.play()
    }
}

// MARK: - Unified Primary Action Button Component (Identical Design & Assets Across All Screens)
struct PrimaryActionButton: View {
    let title: String
    var icon: String? = nil
    var width: CGFloat = 196
    var height: CGFloat = 38
    var isEnabled: Bool = true
    var isSuccess: Bool = false
    let action: () -> Void
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    !isEnabled ? Theme.accent.opacity(0.4) :
                    (isSuccess ? Color(red: 16/255, green: 185/255, blue: 129/255) :
                    (isHovering ? Theme.accentHover : Theme.accent))
                )
                .animation(.easeInOut(duration: 0.2), value: isSuccess)
            
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(Color.white)
            
            if isEnabled {
                CustomCursorArea(
                    cursor: .pointingHand,
                    onHover: { hovering in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isHovering = hovering
                        }
                    },
                    onClick: {
                        action()
                    }
                )
            }
        }
        .frame(width: width, height: height)
        .opacity(isEnabled ? 1.0 : 0.5)
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Dedicated Window Coordinator & Non-Resizable Delegate
final class WindowCoordinator: NSObject, NSWindowDelegate {
    static let shared = WindowCoordinator()
    
    weak var window: NSWindow?
    var isProgrammaticResizing = false
    var currentTargetSize: CGSize = CGSize(width: 440, height: 300)
    private var hasCenteredInitially = false
    
    func attach(to window: NSWindow, targetSize: CGSize) {
        self.window = window
        self.currentTargetSize = targetSize
        window.delegate = self
        
        if !hasCenteredInitially {
            hasCenteredInitially = true
            centerOnScreen(window, size: targetSize)
        }
        
        applyLock(size: targetSize)
    }
    
    private func centerOnScreen(_ win: NSWindow, size: CGSize) {
        if let screen = win.screen ?? NSScreen.main {
            let visible = screen.visibleFrame
            let x = visible.origin.x + (visible.width - size.width) / 2
            let y = visible.origin.y + (visible.height - size.height) / 2
            win.setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
        } else {
            win.center()
        }
    }
    
    func applyLock(size: CGSize) {
        guard let win = window else { return }
        win.styleMask.subtract([.resizable])
        win.standardWindowButton(.zoomButton)?.isEnabled = false
        win.minSize = size
        win.maxSize = size
        if let cv = win.contentView {
            win.invalidateCursorRects(for: cv)
        }
        win.resetCursorRects()
    }
    
    func animateTo(size: CGSize) {
        guard let win = window else { return }
        if win.frame.size == size { return }
        currentTargetSize = size
        
        let currentFrame = win.frame
        let topY = currentFrame.origin.y + currentFrame.size.height
        let centerX = currentFrame.origin.x + (currentFrame.size.width / 2)
        
        let newOrigin = CGPoint(
            x: centerX - (size.width / 2),
            y: topY - size.height
        )
        let newFrame = CGRect(origin: newOrigin, size: size)
        
        // Temporarily allow animation bounds
        win.minSize = NSSize(width: min(currentFrame.width, size.width) - 50, height: min(currentFrame.height, size.height) - 50)
        win.maxSize = NSSize(width: max(currentFrame.width, size.width) + 50, height: max(currentFrame.height, size.height) + 50)
        
        isProgrammaticResizing = true
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.32
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true
            win.animator().setFrame(newFrame, display: true)
        }, completionHandler: { [weak self] in
            self?.isProgrammaticResizing = false
            self?.applyLock(size: size)
        })
    }
    
    // NSWindowDelegate: Intercept any user attempts to resize
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        if isProgrammaticResizing {
            return frameSize
        }
        return sender.frame.size // User drags edge? Return current size -> ZERO resizing allowed!
    }
    
    func windowShouldZoom(_ window: NSWindow, toFrame newFrame: NSRect) -> Bool {
        return false // Disable zoom/fullscreen button completely!
    }
}

// MARK: - Native Window Detector via Guaranteed viewDidMoveToWindow
final class WindowDetectorView: NSView {
    var targetSize: CGSize = CGSize(width: 440, height: 290)
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let win = self.window else { return }
        WindowCoordinator.shared.attach(to: win, targetSize: targetSize)
    }
}

struct WindowAccessor: NSViewRepresentable {
    let targetSize: CGSize
    
    func makeNSView(context: Context) -> WindowDetectorView {
        let view = WindowDetectorView()
        view.targetSize = targetSize
        return view
    }
    
    func updateNSView(_ nsView: WindowDetectorView, context: Context) {
        nsView.targetSize = targetSize
    }
}

struct ContentView: View {
    @State private var videoMetadata: VideoMetadata?
    @State private var extractionProgress: Double = 0.0
    @State private var isExtracting: Bool = false
    @State private var selectedFormat: AudioFormat = .m4a
    @State private var extractedCacheURL: URL?
    @State private var savedURL: URL?
    @State private var isTargeted: Bool = false
    @State private var errorMessage: String?
    @State private var showErrorAlert: Bool = false
    @State private var isHoveringEject: Bool = false
    @State private var isHoveringPlay: Bool = false
    @State private var isHoveringSave: Bool = false
    @State private var showSaveConfirmation: Bool = false
    @State private var saveConfirmationTask: Task<Void, Never>? = nil
    
    @StateObject private var playerManager = AudioPlayerManager()
    
    // Window dimensions for the two distinct states
    private let compactSize = CGSize(width: 440, height: 300)
    private let expandedSize = CGSize(width: 580, height: 460)
    
    private var currentSize: CGSize {
        videoMetadata != nil ? expandedSize : compactSize
    }
    
    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            
            if let metadata = videoMetadata {
                videoLoadedWorkspace(metadata: metadata)
                    .transition(.opacity)
            } else {
                dropZoneView
                    .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.bg)
        .background(WindowAccessor(targetSize: currentSize))
        .preferredColorScheme(.dark)
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenVideoFile"))) { _ in
            chooseFile()
        }
    }
    
    // MARK: - Initial State: Compact Drop Zone (Faithful to Mockup)
    private var dropZoneView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // 1. Film Strip Icon (Fixed container bounds so height never shifts on drag)
            ZStack {
                Image(systemName: "film")
                    .font(.system(size: 42, weight: .regular))
                    .foregroundStyle(isTargeted ? Theme.accent : Color.white)
                    .scaleEffect(isTargeted ? 1.08 : 1.0)
            }
            .frame(width: 56, height: 56)
            .animation(.easeInOut(duration: 0.15), value: isTargeted)
            
            Spacer().frame(height: 18)
            
            // 2. Headline
            Text("Drag and drop video here...")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            
            Spacer().frame(height: 7)
            
            // 3. Subtitle (Exact 2-line phrasing from mockup)
            Text("Supports MP4, MOV, MKV, AVI, and most famous\nvideo formats")
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            
            Spacer().frame(height: 22)
            
            // 4. "OR" Separator
            Text("OR")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(white: 0.45))
                .tracking(0.5)
            
            Spacer().frame(height: 20)
            
            // 5. Choose Video File Button
            PrimaryActionButton(
                title: "Choose Video File...",
                icon: "folder.fill",
                width: 236,
                height: 40,
                action: chooseFile
            )
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            isTargeted ? Theme.accent.opacity(0.08) : Color.clear
        )
        .dropDestination(for: URL.self) { items, _ in
            if let first = items.first {
                handleUploadedFile(first)
                return true
            }
            return false
        } isTargeted: { isTargeted = $0 }
    }
    
    // MARK: - Video Loaded State: Expanded Audio Studio
    private func videoLoadedWorkspace(metadata: VideoMetadata) -> some View {
        VStack(spacing: 0) {
            // TOP BAR: Selected File Header (entire top section is highlighted and clickable with persistent close cursor)
            ZStack {
                // Background highlight spanning the full top section down to the divider
                (isHoveringEject ? Color.white.opacity(0.05) : Color.clear)
                    .contentShape(Rectangle())
                
                HStack(alignment: .center, spacing: 14) {
                    // Video Thumbnail matching 16:9 ratio exactly without letterbox distortion
                    ZStack {
                        if let thumb = metadata.thumbnail {
                            Image(nsImage: thumb)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 110, height: 62)
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(Theme.panelInset)
                                .overlay(
                                    Image(systemName: "film")
                                        .font(.system(size: 22))
                                        .foregroundStyle(Theme.textSecondary)
                                )
                        }
                    }
                    .frame(width: 110, height: 62)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Theme.thumbnailBorder, lineWidth: 1)
                    )
                    
                    // Filename & specs
                    VStack(alignment: .leading, spacing: 5) {
                        Text(metadata.filename)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.textPrimary)
                            .lineLimit(2)
                            .truncationMode(.middle)
                        
                        HStack(spacing: 6) {
                            Text(metadata.formattedDuration)
                            Text("•")
                            Text(metadata.formattedFileSize)
                            if metadata.resolution != .zero {
                                Text("•")
                                Text(metadata.formattedResolution)
                            }
                        }
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Eject / Remove indicator (⊝ icon)
                    Image(systemName: isHoveringEject ? "xmark.circle.fill" : "minus.circle")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(isHoveringEject ? Color.white : Theme.textSecondary)
                        .frame(width: 32, height: 32)
                }
                .padding(.horizontal, 22)
                .padding(.top, 20)
                .padding(.bottom, 20)
                
                // Interactive cursor & click overlay covering the entire top section completely
                CustomCursorArea(
                    cursor: CustomCursor.close,
                    onHover: { hovering in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            isHoveringEject = hovering
                        }
                    },
                    onClick: {
                        resetToNewFile()
                    }
                )
            }
            .frame(maxWidth: .infinity)
            .clipped()
            
            // Thin horizontal divider (#222222)
            Divider()
                .overlay(Theme.divider)
            
            // MIDDLE STAGE: Audio Waveform & Transport (Strictly locked height so it never shifts or scales)
            VStack(spacing: 20) {
                Spacer()
                
                if isExtracting {
                    VStack(spacing: 12) {
                        ProgressView(value: extractionProgress, total: 1.0)
                            .progressViewStyle(.linear)
                            .frame(width: 280)
                            .tint(Theme.accent)
                        
                        Text("Extracting audio track (\(Int(extractionProgress * 100))%)...")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .frame(height: 120)
                } else {
                    // 1. Waveform visualizer
                    WaveformVisualizerView(
                        audioURL: extractedCacheURL,
                        progress: playerManager.duration > 0 ? (playerManager.currentTime / playerManager.duration) : 0.0
                    ) { targetPercent in
                        playerManager.seek(to: targetPercent * playerManager.duration)
                    }
                    .frame(height: 52)
                    .padding(.horizontal, 24)
                    
                    // 2. Play/Pause Button with #3D65AB Blue Accent Ring
                    ZStack {
                        Circle()
                            .fill(isHoveringPlay ? Color.white.opacity(0.08) : Color.black.opacity(0.4))
                            .frame(width: 52, height: 52)
                        
                        Circle()
                            .stroke(Theme.playRing, lineWidth: 2)
                            .frame(width: 52, height: 52)
                        
                        Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .offset(x: playerManager.isPlaying ? 0 : 1.5)
                        
                        CustomCursorArea(
                            cursor: .pointingHand,
                            onHover: { hovering in
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    isHoveringPlay = hovering
                                }
                            },
                            onClick: {
                                playerManager.togglePlayPause()
                            }
                        )
                    }
                    .frame(width: 52, height: 52)
                    
                    // 3. Subtle Monospaced Timecode
                    Text("\(formatSeconds(playerManager.currentTime)) / \(formatSeconds(playerManager.duration))")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.textSecondary)
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // BOTTOM SECTION: Primary Action Button & Muted Format Info
            VStack(spacing: 8) {
                PrimaryActionButton(
                    title: showSaveConfirmation ? "Audio Saved!" : "Save Audio",
                    icon: showSaveConfirmation ? "checkmark" : nil,
                    width: 196,
                    height: 38,
                    isEnabled: !isExtracting && extractedCacheURL != nil,
                    isSuccess: showSaveConfirmation,
                    action: promptNativeSaveDialog
                )
                .keyboardShortcut(.defaultAction)
                
                // Muted format label
                Text("M4A (AAC)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Theme.textTertiary)
                    .padding(.bottom, 6)
            }
            .padding(.bottom, 22)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - File & Extraction Handling
    private func chooseFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [
            .movie, .video, .quickTimeMovie, .mpeg4Movie,
            UTType("public.avi") ?? .movie,
            UTType("org.matroska.mkv") ?? .movie,
            UTType("org.webmproject.webm") ?? .movie
        ]
        panel.prompt = "Choose Video"
        if panel.runModal() == .OK, let url = panel.url {
            handleUploadedFile(url)
        }
    }
    
    private func handleUploadedFile(_ url: URL) {
        playerManager.stop()
        saveConfirmationTask?.cancel()
        showSaveConfirmation = false
        savedURL = nil
        isExtracting = true
        extractionProgress = 0.0
        
        Task {
            do {
                let metadata = try await AudioExtractorEngine.shared.inspectVideo(url: url)
                await MainActor.run {
                    AppSound.playPop()
                    WindowCoordinator.shared.animateTo(size: expandedSize)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.videoMetadata = metadata
                    }
                }
                extractToCache(metadata: metadata, format: selectedFormat)
            } catch {
                await MainActor.run {
                    WindowCoordinator.shared.animateTo(size: compactSize)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        self.videoMetadata = nil
                    }
                    self.isExtracting = false
                    self.errorMessage = "Failed to inspect video: \(error.localizedDescription)"
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    private func extractToCache(metadata: VideoMetadata, format: AudioFormat) {
        playerManager.stop()
        isExtracting = true
        extractionProgress = 0.0
        savedURL = nil
        
        let tempDir = FileManager.default.temporaryDirectory
        let cacheFilename = "audio_extracted_\(UUID().uuidString).\(format.fileExtension)"
        let targetCacheURL = tempDir.appendingPathComponent(cacheFilename)
        
        Task {
            do {
                try await AudioExtractorEngine.shared.extractAudio(
                    from: metadata.url,
                    to: targetCacheURL,
                    format: format
                ) { progress in
                    self.extractionProgress = progress
                }
                
                await MainActor.run {
                    self.extractedCacheURL = targetCacheURL
                    self.isExtracting = false
                    self.playerManager.load(url: targetCacheURL)
                }
            } catch {
                await MainActor.run {
                    self.isExtracting = false
                    self.errorMessage = "Failed to extract audio: \(error.localizedDescription)"
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    // MARK: - Native macOS Save Dialog Flow
    private func promptNativeSaveDialog() {
        guard let metadata = videoMetadata, let cacheURL = extractedCacheURL else { return }
        
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        let defaultName = metadata.url.deletingPathExtension().lastPathComponent
        savePanel.nameFieldStringValue = "\(defaultName).\(selectedFormat.fileExtension)"
        savePanel.allowedContentTypes = [selectedFormat == .m4a ? (UTType.mpeg4Audio) : (UTType.wav)]
        savePanel.prompt = "Save Audio"
        savePanel.message = "Choose destination to save the extracted audio file:"
        
        if savePanel.runModal() == .OK, let destinationURL = savePanel.url {
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: cacheURL, to: destinationURL)
                AppSound.playSave()
                self.savedURL = destinationURL
                
                withAnimation(.easeInOut(duration: 0.25)) {
                    self.showSaveConfirmation = true
                }
                
                // Auto-dismiss confirmation after 2.5 seconds
                self.saveConfirmationTask?.cancel()
                self.saveConfirmationTask = Task {
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    if !Task.isCancelled {
                        await MainActor.run {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                self.showSaveConfirmation = false
                            }
                        }
                    }
                }
            } catch {
                self.errorMessage = "Failed to save file: \(error.localizedDescription)"
                self.showErrorAlert = true
            }
        }
    }
    
    private func resetToNewFile() {
        AppSound.playRemove()
        isHoveringEject = false
        playerManager.stop()
        saveConfirmationTask?.cancel()
        showSaveConfirmation = false
        WindowCoordinator.shared.animateTo(size: compactSize)
        withAnimation(.easeInOut(duration: 0.3)) {
            videoMetadata = nil
            extractedCacheURL = nil
            savedURL = nil
            isExtracting = false
        }
    }
    
    private func formatSeconds(_ seconds: Double) -> String {
        let total = Int(seconds)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
