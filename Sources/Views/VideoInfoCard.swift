import SwiftUI

struct VideoInfoCard: View {
    let metadata: VideoMetadata
    var onChangeFile: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail Preview
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.2))
                    .frame(width: 120, height: 78)
                
                if let thumbnail = metadata.thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 78)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    Image(systemName: "film")
                        .font(.system(size: 30))
                        .foregroundStyle(.secondary)
                        .frame(width: 120, height: 78)
                }
                
                // Duration Tag
                Text(metadata.formattedDuration)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(.white.opacity(0.2), lineWidth: 0.5)
                    )
                    .padding(6)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
            
            // Video Details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(metadata.filename)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    Button(action: onChangeFile) {
                        Text("Change")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                    }
                    .buttonStyle(.plain)
                    .glassCard(cornerRadius: 8)
                }
                
                // Tag Pills
                HStack(spacing: 6) {
                    MetaPill(text: metadata.formattedFileSize, icon: "internaldrive")
                    
                    if metadata.resolution != .zero {
                        MetaPill(text: metadata.formattedResolution, icon: "aspectratio")
                    }
                    
                    if metadata.audioTrackCount > 0 {
                        MetaPill(
                            text: "\(metadata.audioTrackCount) track\(metadata.audioTrackCount > 1 ? "s" : "")",
                            icon: "waveform",
                            tint: .green
                        )
                    } else {
                        MetaPill(
                            text: "No Audio",
                            icon: "exclamationmark.triangle",
                            tint: .orange
                        )
                    }
                }
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 16, isHovered: isHovered)
        .onHover { isHovered = $0 }
    }
}

struct MetaPill: View {
    let text: String
    let icon: String
    var tint: Color? = nil
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(tint ?? .secondary)
            
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(tint ?? .secondary)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            (tint?.opacity(0.1) ?? Color.primary.opacity(0.05))
        )
        .clipShape(Capsule())
    }
}
