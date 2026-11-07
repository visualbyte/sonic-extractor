import SwiftUI

struct AudioPlayerView: View {
    @ObservedObject var playerManager: AudioPlayerManager
    
    var body: some View {
        VStack(spacing: 12) {
            // Interactive Waveform Scrubber
            WaveformVisualizerView(
                audioURL: playerManager.currentURL,
                progress: playerManager.duration > 0 ? (playerManager.currentTime / playerManager.duration) : 0.0
            ) { targetPercent in
                playerManager.seek(to: targetPercent * playerManager.duration)
            }
            .padding(.horizontal, 4)
            
            // Playback Controls & Timers
            HStack(spacing: 14) {
                Button(action: {
                    playerManager.togglePlayPause()
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.cyan, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 38, height: 38)
                            .shadow(color: .purple.opacity(playerManager.isPlaying ? 0.5 : 0.2), radius: 6, x: 0, y: 2)
                        
                        Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .offset(x: playerManager.isPlaying ? 0 : 1)
                    }
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(playerManager.currentURL?.lastPathComponent ?? "Audio Preview")
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text(formatTime(playerManager.currentTime))
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundStyle(Color.accentColor)
                        
                        Text("/")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                        
                        Text(formatTime(playerManager.duration))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if let ext = playerManager.currentURL?.pathExtension.uppercased() {
                    Text(ext)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 16)
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let total = Int(seconds)
        let mins = total / 60
        let secs = total % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
