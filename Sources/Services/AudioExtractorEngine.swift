@preconcurrency import AVFoundation
import AppKit
import QuickLookThumbnailing

public final class AudioExtractorEngine: @unchecked Sendable {
    public static let shared = AudioExtractorEngine()
    
    private var activeExportSession: AVAssetExportSession?
    private var activeReader: AVAssetReader?
    private var activeWriter: AVAssetWriter?
    private var isCancelled = false
    
    private init() {}
    
    public func inspectVideo(url: URL) async throws -> VideoMetadata {
        let asset = AVURLAsset(url: url)
        
        let duration = try await asset.load(.duration)
        let durationSeconds = CMTimeGetSeconds(duration)
        
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        let videoTracks = try await asset.loadTracks(withMediaType: .video)
        
        var resolution = CGSize.zero
        if let videoTrack = videoTracks.first {
            let naturalSize = try await videoTrack.load(.naturalSize)
            let transform = try await videoTrack.load(.preferredTransform)
            if transform.b != 0 || transform.c != 0 {
                // Rotated video (e.g. portrait iPhone video)
                resolution = CGSize(width: naturalSize.height, height: naturalSize.width)
            } else {
                resolution = naturalSize
            }
        }
        
        let fileSize: Int64 = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize).map(Int64.init) ?? 0
        
        // Multi-tiered robust video thumbnail generation
        let thumbnail = await generateThumbnail(for: asset, durationSeconds: durationSeconds, fileURL: url)
        
        return VideoMetadata(
            url: url,
            filename: url.lastPathComponent,
            fileSize: fileSize,
            durationSeconds: max(0, durationSeconds),
            resolution: resolution,
            audioTrackCount: audioTracks.count,
            thumbnail: thumbnail
        )
    }
    
    // MARK: - Robust Thumbnail Extraction
    private func generateThumbnail(for asset: AVURLAsset, durationSeconds: Double, fileURL: URL) async -> NSImage? {
        // Tier 1: AVAssetImageGenerator. Sample several points through the video
        // and keep the brightest frame — the first second is often a black
        // fade-in, which made the header look like an empty black box.
        let videoTracks = (try? await asset.loadTracks(withMediaType: .video)) ?? []
        if !videoTracks.isEmpty {
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.requestedTimeToleranceBefore = .positiveInfinity
            imageGenerator.requestedTimeToleranceAfter = .positiveInfinity
            imageGenerator.maximumSize = CGSize(width: 640, height: 360)
            
            let fractions: [Double] = [0.12, 0.3, 0.5, 0.7]
            var best: (image: CGImage, brightness: Double)?
            
            for fraction in fractions {
                let seconds = min(max(0, durationSeconds * fraction), max(0, durationSeconds - 0.1))
                let targetTime = CMTime(seconds: seconds, preferredTimescale: 600)
                guard let (cgImage, _) = try? await imageGenerator.image(at: targetTime) else { continue }
                
                let brightness = Self.averageBrightness(of: cgImage)
                if best == nil || brightness > best!.brightness {
                    best = (cgImage, brightness)
                }
                // Bright enough to be representative — stop early.
                if brightness > 0.18 { break }
            }
            
            if let best = best, best.brightness > 0.02 {
                return NSImage(cgImage: best.image, size: NSSize(width: best.image.width, height: best.image.height))
            }
        }
        
        // Tier 2: Search container header for embedded camera EXIF / JPEG thumbnail
        // (Canon EOS R series, Sony Alpha, Nikon, Panasonic, GoPro, DJI camera MP4/MOV)
        if let embedded = extractEmbeddedJPEG(from: fileURL) {
            return embedded
        }
        
        // Tier 3: QuickLook Thumbnailing
        if let qlImage = await generateQuickLookThumbnail(for: fileURL) {
            return qlImage
        }
        
        // Tier 4: System file icon fallback
        let icon = NSWorkspace.shared.icon(forFile: fileURL.path)
        icon.size = NSSize(width: 256, height: 256)
        return icon
    }
    
    /// Mean luminance (0…1) of a downsampled copy of the frame, used to avoid
    /// picking a black fade-in as the header thumbnail.
    private static func averageBrightness(of cgImage: CGImage) -> Double {
        let width = 24, height = 24
        var pixels = [UInt8](repeating: 0, count: width * height)
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: CGColorSpaceCreateDeviceGray(),
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return 0 }
        context.interpolationQuality = .low
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        let total = pixels.reduce(0) { $0 + Int($1) }
        return Double(total) / Double(width * height) / 255.0
    }
    
    private func extractEmbeddedJPEG(from fileURL: URL) -> NSImage? {
        guard let fileHandle = try? FileHandle(forReadingFrom: fileURL) else { return nil }
        defer { try? fileHandle.close() }
        
        // Read up to 4 MB from start of file
        let maxSearchBytes = 4 * 1024 * 1024
        let data = fileHandle.readData(ofLength: maxSearchBytes)
        guard data.count > 1000 else { return nil }
        
        let bytes = [UInt8](data)
        let len = bytes.count
        
        var searchIdx = 0
        while searchIdx < len - 4 {
            if bytes[searchIdx] == 0xFF && bytes[searchIdx + 1] == 0xD8 && bytes[searchIdx + 2] == 0xFF {
                let start = searchIdx
                var end = -1
                var i = start + 3
                while i < len - 1 {
                    if bytes[i] == 0xFF && bytes[i + 1] == 0xD9 {
                        end = i + 2
                        break
                    }
                    i += 1
                }
                if end > start && (end - start) > 2000 {
                    let subdata = data.subdata(in: start..<end)
                    if let bitmapRep = NSBitmapImageRep(data: subdata) {
                        let img = NSImage(size: NSSize(width: bitmapRep.pixelsWide, height: bitmapRep.pixelsHigh))
                        img.addRepresentation(bitmapRep)
                        return cropBlackBorders(from: img)
                    } else if let img = NSImage(data: subdata) {
                        return cropBlackBorders(from: img)
                    }
                }
                searchIdx = max(searchIdx + 1, i)
            } else {
                searchIdx += 1
            }
        }
        return nil
    }
    
    private func cropBlackBorders(from image: NSImage) -> NSImage {
        guard let rep = image.representations.first as? NSBitmapImageRep ?? (NSBitmapImageRep(data: image.tiffRepresentation ?? Data())) else {
            return image
        }
        let w = rep.pixelsWide
        let h = rep.pixelsHigh
        guard w > 10 && h > 10 else { return image }
        
        func isRowBlack(_ y: Int) -> Bool {
            for x in stride(from: 5, to: w - 5, by: 5) {
                if let c = rep.colorAt(x: x, y: y) {
                    if c.redComponent > 0.08 || c.greenComponent > 0.08 || c.blueComponent > 0.08 {
                        return false
                    }
                }
            }
            return true
        }
        
        var top = 0
        while top < h / 3 && isRowBlack(top) {
            top += 1
        }
        
        var bottom = h - 1
        while bottom > (h * 2) / 3 && isRowBlack(bottom) {
            bottom -= 1
        }
        
        let activeHeight = bottom - top + 1
        if top > 2 && activeHeight > 10 {
            let cropRect = CGRect(x: 0, y: top, width: w, height: activeHeight)
            if let cg = rep.cgImage?.cropping(to: cropRect) {
                let croppedRep = NSBitmapImageRep(cgImage: cg)
                let result = NSImage(size: NSSize(width: croppedRep.pixelsWide, height: croppedRep.pixelsHigh))
                result.addRepresentation(croppedRep)
                return result
            }
        }
        return image
    }
    
    private func generateQuickLookThumbnail(for fileURL: URL) async -> NSImage? {
        await withCheckedContinuation { continuation in
            let request = QLThumbnailGenerator.Request(
                fileAt: fileURL,
                size: CGSize(width: 320, height: 240),
                scale: 2.0,
                representationTypes: .all
            )
            QLThumbnailGenerator.shared.generateBestRepresentation(for: request) { rep, _ in
                continuation.resume(returning: rep?.nsImage)
            }
        }
    }
    
    public func cancel() {
        isCancelled = true
        activeExportSession?.cancelExport()
        activeReader?.cancelReading()
        activeWriter?.cancelWriting()
    }
    
    public func extractAudio(
        from sourceURL: URL,
        to destinationURL: URL,
        format: AudioFormat,
        progressHandler: @escaping (Double) -> Void
    ) async throws {
        isCancelled = false
        
        // Remove destination if it already exists
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        
        switch format {
        case .m4a:
            try await extractM4A(sourceURL: sourceURL, destinationURL: destinationURL, progressHandler: progressHandler)
        case .wav:
            try await extractWAV(sourceURL: sourceURL, destinationURL: destinationURL, progressHandler: progressHandler)
        }
    }
    
    // MARK: - M4A Extraction
    private func extractM4A(
        sourceURL: URL,
        destinationURL: URL,
        progressHandler: @escaping (Double) -> Void
    ) async throws {
        let asset = AVURLAsset(url: sourceURL)
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard !audioTracks.isEmpty else {
            throw NSError(domain: "AudioExtractor", code: 101, userInfo: [
                NSLocalizedDescriptionKey: "The selected video does not contain any audio tracks."
            ])
        }
        
        guard let session = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(domain: "AudioExtractor", code: 102, userInfo: [
                NSLocalizedDescriptionKey: "Failed to create M4A export session."
            ])
        }
        
        self.activeExportSession = session
        session.outputURL = destinationURL
        session.outputFileType = .m4a
        
        // Progress monitoring task that stays alive through waiting and exporting
        let progressTask = Task {
            while !Task.isCancelled {
                let status = session.status
                if status == .completed || status == .failed || status == .cancelled {
                    break
                }
                let progress = Double(session.progress)
                await MainActor.run {
                    progressHandler(progress)
                }
                try? await Task.sleep(nanoseconds: 80_000_000) // 80ms for responsive updates
            }
        }
        
        await withCheckedContinuation { continuation in
            session.exportAsynchronously {
                continuation.resume()
            }
        }
        
        progressTask.cancel()
        
        if isCancelled {
            try? FileManager.default.removeItem(at: destinationURL)
            throw NSError(domain: "AudioExtractor", code: 103, userInfo: [
                NSLocalizedDescriptionKey: "Extraction was cancelled."
            ])
        }
        
        if session.status == .completed {
            await MainActor.run { progressHandler(1.0) }
        } else if let error = session.error {
            throw error
        } else {
            throw NSError(domain: "AudioExtractor", code: 104, userInfo: [
                NSLocalizedDescriptionKey: "Export completed with unknown status: \(session.status.rawValue)"
            ])
        }
    }
    
    // MARK: - WAV Extraction
    private func extractWAV(
        sourceURL: URL,
        destinationURL: URL,
        progressHandler: @escaping (Double) -> Void
    ) async throws {
        let asset = AVURLAsset(url: sourceURL)
        let audioTracks = try await asset.loadTracks(withMediaType: .audio)
        guard let audioTrack = audioTracks.first else {
            throw NSError(domain: "AudioExtractor", code: 201, userInfo: [
                NSLocalizedDescriptionKey: "The selected video does not contain any audio tracks."
            ])
        }
        
        let totalDuration = CMTimeGetSeconds(try await asset.load(.duration))
        
        let reader = try AVAssetReader(asset: asset)
        self.activeReader = reader
        
        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 2,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsNonInterleaved: false,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        
        let trackOutput = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: outputSettings)
        trackOutput.alwaysCopiesSampleData = false
        guard reader.canAdd(trackOutput) else {
            throw NSError(domain: "AudioExtractor", code: 202, userInfo: [
                NSLocalizedDescriptionKey: "Cannot configure audio track reader."
            ])
        }
        reader.add(trackOutput)
        
        let writer = try AVAssetWriter(outputURL: destinationURL, fileType: .wav)
        self.activeWriter = writer
        
        let writerInput = AVAssetWriterInput(mediaType: .audio, outputSettings: outputSettings)
        writerInput.expectsMediaDataInRealTime = false
        guard writer.canAdd(writerInput) else {
            throw NSError(domain: "AudioExtractor", code: 203, userInfo: [
                NSLocalizedDescriptionKey: "Cannot configure audio track writer."
            ])
        }
        writer.add(writerInput)
        
        guard reader.startReading() else {
            throw reader.error ?? NSError(domain: "AudioExtractor", code: 204, userInfo: [
                NSLocalizedDescriptionKey: "Failed to begin reading audio data."
            ])
        }
        
        guard writer.startWriting() else {
            throw writer.error ?? NSError(domain: "AudioExtractor", code: 205, userInfo: [
                NSLocalizedDescriptionKey: "Failed to begin writing WAV file."
            ])
        }
        
        writer.startSession(atSourceTime: .zero)
        
        let queue = DispatchQueue(label: "com.audioextractor.wavwriter", qos: .userInitiated)
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            writerInput.requestMediaDataWhenReady(on: queue) { [weak self] in
                guard let self = self else { return }
                
                while writerInput.isReadyForMoreMediaData {
                    if self.isCancelled {
                        reader.cancelReading()
                        writer.cancelWriting()
                        continuation.resume(throwing: NSError(domain: "AudioExtractor", code: 206, userInfo: [
                            NSLocalizedDescriptionKey: "Extraction was cancelled."
                        ]))
                        return
                    }
                    
                    if let sampleBuffer = trackOutput.copyNextSampleBuffer() {
                        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                        let seconds = CMTimeGetSeconds(timestamp)
                        if totalDuration > 0 {
                            let prog = min(0.99, max(0.0, seconds / totalDuration))
                            DispatchQueue.main.async {
                                progressHandler(prog)
                            }
                        }
                        
                        if !writerInput.append(sampleBuffer) {
                            writerInput.markAsFinished()
                            continuation.resume(throwing: writer.error ?? NSError(domain: "AudioExtractor", code: 207, userInfo: [
                                NSLocalizedDescriptionKey: "Failed to write audio sample buffer."
                            ]))
                            return
                        }
                    } else {
                        // Finished reading all samples
                        writerInput.markAsFinished()
                        writer.finishWriting {
                            if writer.status == .completed {
                                DispatchQueue.main.async {
                                    progressHandler(1.0)
                                }
                                continuation.resume()
                            } else {
                                continuation.resume(throwing: writer.error ?? NSError(domain: "AudioExtractor", code: 208, userInfo: [
                                    NSLocalizedDescriptionKey: "Failed to complete WAV writing."
                                ]))
                            }
                        }
                        return
                    }
                }
            }
        }
    }
    
    // MARK: - Fast Accurate Audio Waveform Sampling
    public func generateWaveform(from url: URL, count: Int = 48) async -> [CGFloat] {
        return await Task.detached(priority: .userInitiated) { () -> [CGFloat] in
            do {
                let file = try AVAudioFile(forReading: url)
                let totalFrames = file.length
                guard totalFrames > 0 else {
                    return Array(repeating: 0.16, count: count)
                }
                
                let windowSize: AVAudioFrameCount = 4096
                guard let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: windowSize) else {
                    return Array(repeating: 0.16, count: count)
                }
                
                let channelCount = Int(file.processingFormat.channelCount)
                var rawAmplitudes: [Float] = []
                
                for i in 0..<count {
                    let targetFrame = max(0, min(totalFrames - Int64(windowSize), Int64(Double(i) / Double(count) * Double(totalFrames))))
                    file.framePosition = targetFrame
                    try file.read(into: buffer, frameCount: windowSize)
                    
                    if let channelData = buffer.floatChannelData {
                        let frameLength = Int(buffer.frameLength)
                        if frameLength > 0 {
                            var sum: Float = 0
                            for c in 0..<channelCount {
                                let samples = channelData[c]
                                for s in 0..<frameLength {
                                    let val = samples[s]
                                    sum += val * val
                                }
                            }
                            let rms = sqrt(sum / Float(frameLength * channelCount))
                            rawAmplitudes.append(rms)
                        } else {
                            rawAmplitudes.append(0)
                        }
                    } else {
                        rawAmplitudes.append(0)
                    }
                }
                
                let maxAmp = rawAmplitudes.max() ?? 1.0
                let minBarHeight: CGFloat = 0.16
                
                if maxAmp > 0.0001 {
                    return rawAmplitudes.map { amp in
                        let normalized = CGFloat(amp / maxAmp)
                        let perceptual = sqrt(normalized) // Natural acoustic scaling
                        return max(minBarHeight, min(1.0, perceptual))
                    }
                } else {
                    return Array(repeating: minBarHeight, count: count)
                }
            } catch {
                return Array(repeating: 0.16, count: count)
            }
        }.value
    }
}
