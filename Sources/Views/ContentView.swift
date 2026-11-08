import SwiftUI
import AppKit
import QuartzCore
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
    var currentTargetSize: CGSize = CGSize(width: 440, height: 370)
    private var hasCenteredInitially = false
    
    func attach(to window: NSWindow, targetSize: CGSize) {
        self.window = window
        self.currentTargetSize = targetSize
        window.delegate = self
        window.isRestorable = false
        window.setFrameAutosaveName("")
        window.styleMask.subtract([.resizable])
        window.standardWindowButton(.zoomButton)?.isEnabled = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.contentView?.layerContentsPlacement = .topLeft
        
        setSize(targetSize, center: !hasCenteredInitially)
        hasCenteredInitially = true
    }
    
    func setSize(_ size: CGSize, center: Bool = false) {
        guard let win = window else { return }
        currentTargetSize = size
        isProgrammaticResizing = true
        
        let targetFrame: NSRect
        if center, let screen = win.screen ?? NSScreen.main {
            let visible = screen.visibleFrame
            let x = visible.origin.x + (visible.width - size.width) / 2
            let y = visible.origin.y + (visible.height - size.height) / 2
            targetFrame = NSRect(x: x, y: y, width: size.width, height: size.height)
        } else {
            let currentFrame = win.frame
            let topY = currentFrame.origin.y + currentFrame.size.height
            let centerX = currentFrame.origin.x + (currentFrame.size.width / 2)
            var newOrigin = CGPoint(
                x: centerX - (size.width / 2),
                y: topY - size.height
            )
            if let screen = win.screen ?? NSScreen.main {
                let visibleMinY = screen.visibleFrame.origin.y
                if newOrigin.y < visibleMinY {
                    newOrigin.y = visibleMinY
                }
            }
            targetFrame = NSRect(origin: newOrigin, size: size)
        }
        
        win.setFrame(targetFrame, display: true, animate: false)
        isProgrammaticResizing = false
    }
    
    func animateTo(size: CGSize, duration: TimeInterval = 0.34) {
        guard let win = window else { return }
        currentTargetSize = size
        
        if abs(win.frame.size.width - size.width) < 0.5 && abs(win.frame.size.height - size.height) < 0.5 {
            return
        }
        
        let currentFrame = win.frame
        let topY = currentFrame.origin.y + currentFrame.size.height
        let centerX = currentFrame.origin.x + (currentFrame.size.width / 2)
        
        var newOrigin = CGPoint(
            x: centerX - (size.width / 2),
            y: topY - size.height
        )
        if let screen = win.screen ?? NSScreen.main {
            let visibleMinY = screen.visibleFrame.origin.y
            if newOrigin.y < visibleMinY {
                newOrigin.y = visibleMinY
            }
        }
        let targetFrame = NSRect(origin: newOrigin, size: size)
        
        // Animate the window with the exact same duration and easing curve the
        // SwiftUI content transition uses, so the two never drift apart.
        isProgrammaticResizing = true
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true
            win.animator().setFrame(targetFrame, display: true)
        }, completionHandler: { [weak self] in
            self?.isProgrammaticResizing = false
        })
    }
    
    // NSWindowDelegate: Intercept any user attempts to resize
    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        if isProgrammaticResizing {
            return frameSize
        }
        return currentTargetSize // Strictly enforce target size!
    }
    
    func windowShouldZoom(_ window: NSWindow, toFrame newFrame: NSRect) -> Bool {
        return false // Disable zoom/fullscreen button completely!
    }
}

// MARK: - Native Window Detector via Guaranteed viewDidMoveToWindow
final class WindowDetectorView: NSView {
    var targetSize: CGSize = CGSize(width: 440, height: 370)
    
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
        WindowCoordinator.shared.currentTargetSize = targetSize
    }
}

struct ContentView: View {
    @State private var videoMetadata: VideoMetadata?
    @State private var extractionProgress: Double = 0.0
    @State private var isExtracting: Bool = false
    @State private var selectedFormat: AudioFormat = .m4a
    @State private var extractedCacheURL: URL?
    @State private var waveformSamples: [CGFloat] = []
    @State private var savedURL: URL?
    @State private var isTargeted: Bool = false
    @State private var errorMessage: String?
    @State private var showErrorAlert: Bool = false
    @State private var isHoveringEject: Bool = false
    @State private var isHoveringPlay: Bool = false
    @State private var isHoveringSave: Bool = false
    @State private var showSaveConfirmation: Bool = false
    @State private var saveConfirmationTask: Task<Void, Never>? = nil
    @State private var studioShownAt: Date? = nil
    @State private var studioVisible: Bool = false
    
    @StateObject private var playerManager = AudioPlayerManager()
    
    // Window dimensions for the three lifecycle states.
    //  drop zone   440×370  small, near-square
    //  extracting  580×370  same height as the drop zone, studio width
    //  studio      580×480  height expands once the player is ready
    private let compactSize = CGSize(width: 440, height: 370)
    private let extractingSize = CGSize(width: 580, height: 370)
    private let expandedSize = CGSize(width: 580, height: 480)
    
    // One shared timing for the window resize and the SwiftUI content swap, so
    // the frame and the views animate in lock-step instead of stepping on
    // each other.
    private let transitionDuration: TimeInterval = 0.34
    private var transitionAnimation: Animation { .easeInOut(duration: transitionDuration) }
    
    private var currentSize: CGSize {
        guard videoMetadata != nil else { return compactSize }
        return isExtracting ? extractingSize : expandedSize
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            Theme.bg.ignoresSafeArea()
            
            // Both states stay mounted and cross-fade through explicit opacity
            // values. Conditional `if/else` + `.transition` was swapping the
            // views instantly, which is what made the layout look like it was
            // jumping.
            dropZoneView
                .opacity(studioVisible ? 0 : 1)
                .allowsHitTesting(!studioVisible)
                .animation(transitionAnimation, value: studioVisible)
            
            if let metadata = videoMetadata {
                videoLoadedWorkspace(metadata: metadata)
                    .opacity(studioVisible ? 1 : 0)
                    .allowsHitTesting(studioVisible)
                    .animation(transitionAnimation, value: studioVisible)
            }
        }
        // `minHeight: 0` keeps the window's minimum size decoupled from the
        // (tall) studio layout. Without it, `.windowResizability(.contentSize)`
        // forces the window to snap to the new content height instead of
        // letting our coordinated animation resize it.
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .top)
        .background(Theme.bg)
        .background(WindowAccessor(targetSize: currentSize))
        .preferredColorScheme(.dark)
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "An unknown error occurred.")
        }
        .onReceive(NotificationCenter.default.publisher(for: .openFileRequested)) { _ in
            chooseFile()
        }
        .onReceive(NotificationCenter.default.publisher(for: .resetFileRequested)) { _ in
            if videoMetadata != nil {
                resetToNewFile()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .saveAudioRequested)) { _ in
            if !isExtracting && extractedCacheURL != nil {
                promptNativeSaveDialog()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenVideoFile"))) { _ in
            chooseFile()
        }
        .toolbar {
            toolbarContent
        }
    }
    
    // MARK: - Native Unified Toolbar (Matching EXIF Reader)
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button(action: chooseFile) {
                Label("Open", systemImage: "folder")
            }
            .keyboardShortcut("o", modifiers: .command)
            .help("Open video file (⌘O)")
        }
        
        ToolbarItem(placement: .navigation) {
            Button(action: resetToNewFile) {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }
            .keyboardShortcut("r", modifiers: .command)
            .help("Close video (⌘R)")
            // Keep the item mounted so the toolbar never re-lays-out (and the
            // centered title never shifts) when a video is loaded or closed.
            .opacity(videoMetadata != nil ? 1 : 0)
            .disabled(videoMetadata == nil)
        }
        
        ToolbarItem(placement: .principal) {
            // Keep the app identity pinned across the drop zone, extraction and
            // studio states. The current file's details already live in the
            // studio header, so the toolbar never needs to change.
            HStack(spacing: 6) {
                Image(systemName: "waveform")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                Text("SonicExtractor")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        
        ToolbarItemGroup(placement: .primaryAction) {
            Button(action: promptNativeSaveDialog) {
                HStack(spacing: 5) {
                    Image(systemName: showSaveConfirmation ? "checkmark" : "square.and.arrow.down")
                        .font(.system(size: 12))
                    Text(showSaveConfirmation ? "Saved" : "Save")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundStyle(
                    showSaveConfirmation ? Color(red: 16/255, green: 185/255, blue: 129/255) :
                    (isExtracting ? Theme.textTertiary : Theme.accent)
                )
            }
            .keyboardShortcut("s", modifiers: .command)
            .help("Save extracted audio (⌘S)")
            .opacity(videoMetadata != nil && !isExtracting ? 1 : 0)
            .disabled(videoMetadata == nil || isExtracting || extractedCacheURL == nil)
        }
    }
    
    // MARK: - Initial State: Compact Drop Zone (Faithful to Mockup)
    private var dropZoneView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // 1. Film Strip Icon
            ZStack {
                Image(systemName: "film")
                    .font(.system(size: 38, weight: .regular))
                    .foregroundStyle(isTargeted ? Theme.accent : Color.white)
                    .scaleEffect(isTargeted ? 1.08 : 1.0)
            }
            .frame(width: 48, height: 48)
            .animation(.easeInOut(duration: 0.15), value: isTargeted)
            
            Spacer().frame(height: 26)
            
            // 2. Headline
            Text("Drag and drop video here...")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.textPrimary)
            
            Spacer().frame(height: 7)
            
            // 3. Subtitle
            Text("Supports MP4, MOV, MKV, AVI, and most famous video formats")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 300)
            
            Spacer().frame(height: 28)
            
            // 4. "OR" Separator
            Text("OR")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color(white: 0.45))
                .tracking(0.5)
            
            Spacer().frame(height: 16)
            
            // 5. Choose Video File Button
            PrimaryActionButton(
                title: "Choose Video File...",
                icon: "folder.fill",
                width: 250,
                height: 38,
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
            // TOP BAR: Selected File Header (Strictly pinned to the top of the window, fixed height: 102)
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
            .frame(height: 102)
            .frame(maxWidth: .infinity)
            .clipped()
            
            // Thin horizontal divider (#222222)
            Divider()
                .overlay(Theme.divider)
                .frame(height: 1)
            
            // 3. DYNAMIC CONTENT AREA
            // A transparent base owns the layout height, so the hidden player
            // (which is taller than the extracting window) can't push the
            // progress indicator around. Both states are overlays and cross-fade
            // in place.
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .top) {
                    // Audio Studio Ready: player and action controls
                    VStack(spacing: 0) {
                        // Waveform Visualizer
                        WaveformVisualizerView(
                            audioURL: extractedCacheURL,
                            externalSamples: waveformSamples,
                            progress: playerManager.duration > 0 ? (playerManager.currentTime / playerManager.duration) : 0.0
                        ) { targetPercent in
                            playerManager.seek(to: targetPercent * playerManager.duration)
                        }
                        .frame(height: 52)
                        .padding(.horizontal, 24)
                        .padding(.top, 28)
                        
                        // Play/Pause Button
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
                        .padding(.top, 18)
                        
                        // Monospaced Timecode
                        Text("\(formatSeconds(playerManager.currentTime)) / \(formatSeconds(playerManager.duration))")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(Theme.textSecondary)
                            .padding(.top, 12)
                        
                        // Save CTA Button
                        PrimaryActionButton(
                            title: showSaveConfirmation ? "Audio Saved!" : "Save Audio",
                            icon: showSaveConfirmation ? "checkmark" : nil,
                            width: 196,
                            height: 38,
                            isEnabled: extractedCacheURL != nil,
                            isSuccess: showSaveConfirmation,
                            action: promptNativeSaveDialog
                        )
                        .keyboardShortcut(.defaultAction)
                        // Deliberately larger gap than the spacing inside the
                        // transport group, so the export section reads as a
                        // separate block (law of proximity).
                        .padding(.top, 44)
                        
                        // Muted Format Label
                        Text("M4A (AAC)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.textTertiary)
                            .padding(.top, 8)
                        
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .top)
                    .frame(height: 376)
                    .opacity(isExtracting ? 0 : 1)
                    .allowsHitTesting(!isExtracting)
                    .animation(transitionAnimation, value: isExtracting)
                }
                .overlay {
                    // Extraction In-Progress
                    VStack(spacing: 12) {
                        ProgressView(value: extractionProgress, total: 1.0)
                            .progressViewStyle(.linear)
                            .frame(width: 280)
                            .tint(Theme.accent)
                            .animation(.linear(duration: 0.12), value: extractionProgress)
                        
                        Text(extractionProgress > 0 ? "Extracting audio track (\(Int(extractionProgress * 100))%)..." : "Preparing audio track...")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(Theme.textSecondary)
                    }
                    .opacity(isExtracting ? 1 : 0)
                    .allowsHitTesting(isExtracting)
                    .animation(transitionAnimation, value: isExtracting)
                }
                .clipped()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
        waveformSamples = []
        isExtracting = true
        extractionProgress = 0.0
        
        Task {
            do {
                let metadata = try await AudioExtractorEngine.shared.inspectVideo(url: url)
                await MainActor.run {
                    AppSound.playPop()
                    self.studioShownAt = Date()
                    self.videoMetadata = metadata
                    // Insert the studio at 0 opacity first, then widen the
                    // window to the extracting size and fade it in on the next
                    // runloop so both start on the same animation beat.
                    DispatchQueue.main.async {
                        guard self.videoMetadata?.url == metadata.url else { return }
                        WindowCoordinator.shared.animateTo(size: self.extractingSize, duration: self.transitionDuration)
                        self.studioVisible = true
                    }
                }
                extractToCache(metadata: metadata, format: selectedFormat)
            } catch {
                await MainActor.run {
                    WindowCoordinator.shared.animateTo(size: self.compactSize, duration: self.transitionDuration)
                    self.studioVisible = false
                    self.videoMetadata = nil
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
        let shownAt = self.studioShownAt
        
        Task {
            do {
                try await AudioExtractorEngine.shared.extractAudio(
                    from: metadata.url,
                    to: targetCacheURL,
                    format: format
                ) { progress in
                    self.extractionProgress = progress
                }
                
                // Fast authentic waveform analysis directly from the extracted audio
                let samples = await AudioExtractorEngine.shared.generateWaveform(from: targetCacheURL, count: 48)
                
                // Never start the window expansion while the drop-zone → studio
                // dissolve is still running. Instant extractions used to fire
                // both transitions on top of each other, which is what made the
                // layout look like it was jumping around.
                if let shownAt = shownAt {
                    let minimumOnScreen: TimeInterval = 0.55
                    let elapsed = Date().timeIntervalSince(shownAt)
                    if elapsed < minimumOnScreen {
                        try? await Task.sleep(nanoseconds: UInt64((minimumOnScreen - elapsed) * 1_000_000_000))
                    }
                }
                
                await MainActor.run {
                    // Ignore completions that belong to a file we already closed
                    // or replaced.
                    guard let current = self.videoMetadata, current.url == metadata.url else { return }
                    
                    self.extractedCacheURL = targetCacheURL
                    self.waveformSamples = samples
                    
                    // Grow the window (height only) and cross-fade the
                    // progress into the player on the same beat.
                    WindowCoordinator.shared.animateTo(size: self.expandedSize, duration: self.transitionDuration)
                    self.isExtracting = false
                    self.playerManager.load(url: targetCacheURL)
                }
            } catch {
                await MainActor.run {
                    guard let current = self.videoMetadata, current.url == metadata.url else { return }
                    
                    WindowCoordinator.shared.animateTo(size: self.compactSize, duration: self.transitionDuration)
                    self.isExtracting = false
                    self.studioVisible = false
                    self.videoMetadata = nil
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
        AudioExtractorEngine.shared.cancel()
        AppSound.playRemove()
        isHoveringEject = false
        playerManager.stop()
        saveConfirmationTask?.cancel()
        showSaveConfirmation = false
        studioShownAt = nil
        isExtracting = false
        
        // Phase 1: cross-fade the studio back to the drop zone without
        // touching the window. Shrinking the window while the (larger) studio
        // is still visible clips its content mid-fade, which is what made the
        // return feel jerky.
        studioVisible = false
        
        let closingURL = videoMetadata?.url
        DispatchQueue.main.asyncAfter(deadline: .now() + transitionDuration) {
            guard !studioVisible, videoMetadata?.url == closingURL else { return }
            videoMetadata = nil
            extractedCacheURL = nil
            waveformSamples = []
            savedURL = nil
            
            // Phase 2: only now shrink the window, with just the drop zone
            // visible. Nothing gets clipped, so the resize stays smooth.
            WindowCoordinator.shared.animateTo(size: compactSize, duration: transitionDuration)
        }
    }
    
    private func formatSeconds(_ seconds: Double) -> String {
        let total = Int(seconds)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
