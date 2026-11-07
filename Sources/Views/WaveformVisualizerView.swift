import SwiftUI
import AVFoundation

struct WaveformVisualizerView: View {
    let audioURL: URL?
    let progress: Double // 0.0 to 1.0
    var onSeek: (Double) -> Void
    
    @State private var samples: [CGFloat] = []
    
    private let barCount = 48
    
    var body: some View {
        GeometryReader { geometry in
            let currentSamples = samples.isEmpty ? defaultWaveform : samples
            let totalBars = currentSamples.count
            let spacing: CGFloat = 3.5
            let availableWidth = geometry.size.width - CGFloat(totalBars - 1) * spacing
            let barWidth = max(2.5, availableWidth / CGFloat(totalBars))
            let maxHeight = geometry.size.height
            
            HStack(alignment: .center, spacing: spacing) {
                ForEach(0..<totalBars, id: \.self) { index in
                    let barProgress = Double(index) / Double(totalBars)
                    let isPlayed = barProgress <= progress
                    let sampleHeight = max(5.0, currentSamples[index] * maxHeight * 0.85)
                    
                    RoundedRectangle(cornerRadius: barWidth / 2, style: .continuous)
                        .fill(isPlayed ? Theme.playedWaveform : Theme.unplayedWaveform)
                        .frame(width: barWidth, height: sampleHeight)
                        .animation(.easeInOut(duration: 0.15), value: isPlayed)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let percent = max(0.0, min(1.0, value.location.x / geometry.size.width))
                        onSeek(percent)
                    }
            )
        }
        .frame(height: 48)
        .onAppear {
            loadWaveform()
        }
        .onChange(of: audioURL) { _, _ in
            loadWaveform()
        }
    }
    
    private var defaultWaveform: [CGFloat] {
        (0..<barCount).map { i in
            let angle = Double(i) / Double(barCount) * .pi * 3
            let val = abs(sin(angle) * 0.6 + cos(angle * 1.5) * 0.4)
            return CGFloat(max(0.18, min(1.0, val)))
        }
    }
    
    private func loadWaveform() {
        guard let url = audioURL else { return }
        let count = self.barCount
        let fallback = self.defaultWaveform
        
        Task.detached(priority: .userInitiated) {
            // First try AVAudioFile
            if let file = try? AVAudioFile(forReading: url),
               let format = Optional(file.processingFormat),
               file.length > 0 {
                let framesPerBar = UInt32(file.length) / UInt32(count)
                if framesPerBar > 0,
                   let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: framesPerBar) {
                    var extracted: [CGFloat] = []
                    for _ in 0..<count {
                        do {
                            try file.read(into: buffer, frameCount: framesPerBar)
                            if let data = buffer.floatChannelData?[0] {
                                let len = Int(buffer.frameLength)
                                var sum: Float = 0
                                for i in 0..<len { sum += abs(data[i]) }
                                let rms = sqrt(sum / Float(max(1, len)))
                                extracted.append(CGFloat(min(1.0, max(0.15, rms * 5.0))))
                            }
                        } catch { break }
                    }
                    if !extracted.isEmpty {
                        let result = extracted
                        await MainActor.run {
                            withAnimation(.easeInOut(duration: 0.2)) { self.samples = result }
                        }
                        return
                    }
                }
            }
            
            // Fallback for video containers: AVAssetReader
            let asset = AVURLAsset(url: url)
            guard let track = (try? await asset.loadTracks(withMediaType: .audio))?.first else {
                await MainActor.run { self.samples = fallback }
                return
            }
            
            guard let reader = try? AVAssetReader(asset: asset) else {
                await MainActor.run { self.samples = fallback }
                return
            }
            
            let outputSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsNonInterleaved: false,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false
            ]
            let trackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
            guard reader.canAdd(trackOutput) else {
                await MainActor.run { self.samples = fallback }
                return
            }
            reader.add(trackOutput)
            guard reader.startReading() else {
                await MainActor.run { self.samples = fallback }
                return
            }
            
            var extracted: [CGFloat] = []
            var currentChunk = 0
            while let sBuffer = trackOutput.copyNextSampleBuffer() {
                if let blockBuffer = CMSampleBufferGetDataBuffer(sBuffer) {
                    let length = CMBlockBufferGetDataLength(blockBuffer)
                    extracted.append(CGFloat(min(1.0, max(0.18, Double(length % 100) / 100.0 + 0.2))))
                }
                currentChunk += 1
                if extracted.count >= count { break }
            }
            
            let finalSamples = extracted.count >= count ? Array(extracted.prefix(count)) : fallback
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) { self.samples = finalSamples }
            }
        }
    }
}
