import SwiftUI
import AVFoundation

struct WaveformVisualizerView: View {
    let audioURL: URL?
    var externalSamples: [CGFloat]? = nil
    let progress: Double // 0.0 to 1.0
    var onSeek: (Double) -> Void
    
    @State private var internalSamples: [CGFloat] = []
    
    private let barCount = 48
    
    private var activeSamples: [CGFloat] {
        if let ext = externalSamples, !ext.isEmpty {
            return ext
        }
        if !internalSamples.isEmpty {
            return internalSamples
        }
        return Array(repeating: 0.16, count: barCount)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let currentSamples = activeSamples
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
    
    private func loadWaveform() {
        if let ext = externalSamples, !ext.isEmpty {
            return
        }
        guard let url = audioURL else { return }
        let count = self.barCount
        
        Task.detached(priority: .userInitiated) {
            let extracted = await AudioExtractorEngine.shared.generateWaveform(from: url, count: count)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.2)) {
                    self.internalSamples = extracted
                }
            }
        }
    }
}
