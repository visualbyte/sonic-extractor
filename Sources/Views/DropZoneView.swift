import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @Binding var isTargeted: Bool
    var onFileSelected: (URL) -> Void
    var onBrowseClicked: () -> Void
    
    @State private var isHovered = false
    @State private var borderPhase: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Glass background
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
            
            // Animated stroke when targeted
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    isTargeted
                        ? AnyShapeStyle(
                            AngularGradient(
                                colors: [.cyan, .purple, .pink, .cyan],
                                center: .center,
                                startAngle: .degrees(borderPhase), endAngle: .degrees(borderPhase + 360)
                            )
                        )
                        : AnyShapeStyle(
                            LinearGradient(
                                colors: [
                                    .white.opacity(isHovered ? 0.35 : 0.20),
                                    .white.opacity(0.05),
                                    .black.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        ),
                    lineWidth: isTargeted ? 2.5 : 1
                )
                .animation(.easeInOut(duration: 0.2), value: isTargeted)
            
            VStack(spacing: 18) {
                // Floating Glowing Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isTargeted
                                    ? [.cyan.opacity(0.4), .purple.opacity(0.4)]
                                    : [.blue.opacity(0.18), .purple.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: isTargeted ? 8 : 4)
                    
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 68, height: 68)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.25), lineWidth: 1)
                        )
                    
                    Image(systemName: isTargeted ? "arrow.down.doc.fill" : "waveform.badge.plus")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(isTargeted ? 1.15 : (isHovered ? 1.05 : 1.0))
                }
                .shadow(color: .purple.opacity(0.3), radius: isTargeted ? 14 : 6, x: 0, y: 4)
                
                VStack(spacing: 6) {
                    Text("Drop video file here")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Text("MP4, MOV, MKV, AVI, WebM supported")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Button(action: onBrowseClicked) {
                    HStack(spacing: 6) {
                        Image(systemName: "folder.badge.plus")
                        Text("Browse Video...")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: .purple.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(.plain)
            }
            .padding(36)
        }
        .frame(maxWidth: .infinity, minHeight: 250)
        .scaleEffect(isTargeted ? 1.015 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isTargeted)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .dropDestination(for: URL.self) { items, _ in
            if let first = items.first {
                onFileSelected(first)
                return true
            }
            return false
        } isTargeted: { targeted in
            isTargeted = targeted
            if targeted {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    borderPhase = 360
                }
            } else {
                borderPhase = 0
            }
        }
    }
}
