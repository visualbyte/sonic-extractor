import SwiftUI

struct GlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var isHovered: Bool = false
    var glowColor: Color = .clear
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(isHovered ? 0.35 : 0.20), location: 0),
                                .init(color: .white.opacity(0.05), location: 0.5),
                                .init(color: .black.opacity(0.15), location: 1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: glowColor.opacity(glowColor == .clear ? 0 : 0.3),
                radius: 12,
                x: 0,
                y: 0
            )
            .shadow(
                color: Color.black.opacity(isHovered ? 0.18 : 0.08),
                radius: isHovered ? 14 : 8,
                x: 0,
                y: isHovered ? 6 : 3
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 16, isHovered: Bool = false, glowColor: Color = .clear) -> some View {
        self.modifier(GlassModifier(cornerRadius: cornerRadius, isHovered: isHovered, glowColor: glowColor))
    }
}
