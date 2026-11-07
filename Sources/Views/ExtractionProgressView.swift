import SwiftUI

struct ExtractionProgressView: View {
    let progress: Double
    var onCancel: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated Header Icon with pulsing gradient halo
            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.cyan, .purple, .pink, .cyan]),
                            center: .center
                        ),
                        lineWidth: 4
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: isAnimating)
                    .blur(radius: 2)
                    .opacity(0.8)
                
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 72, height: 72)
                
                // Equalizer wave bars animating
                HStack(spacing: 3) {
                    ForEach(0..<5) { i in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [.cyan, .purple],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 4, height: isAnimating ? CGFloat([28, 14, 34, 18, 24][i]) : 8)
                            .animation(
                                .easeInOut(duration: 0.45)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.1),
                                value: isAnimating
                            )
                    }
                }
            }
            .padding(.top, 8)
            
            VStack(spacing: 6) {
                Text("Extracting High-Fidelity Audio...")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("\(Int(progress * 100))% completed")
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            // Sleek Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 8)
                    
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * CGFloat(progress)), height: 8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: progress)
                        .shadow(color: .purple.opacity(0.4), radius: 6, x: 0, y: 0)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 20)
            
            Button(action: onCancel) {
                Label("Cancel Extraction", systemImage: "xmark")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.plain)
            .glassCard(cornerRadius: 12)
        }
        .padding(24)
        .glassCard(cornerRadius: 20, glowColor: .purple)
        .onAppear {
            isAnimating = true
        }
    }
}
