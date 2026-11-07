import SwiftUI

struct ExtractionOptionsView: View {
    @Binding var selectedFormat: AudioFormat
    @Binding var outputOption: OutputFolderOption
    @Binding var customFolderURL: URL?
    var onChooseCustomFolder: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Export Configuration")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            
            // Format Selection Cards
            HStack(spacing: 12) {
                ForEach(AudioFormat.allCases) { format in
                    ModernFormatCard(
                        format: format,
                        isSelected: selectedFormat == format
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFormat = format
                        }
                    }
                }
            }
            
            Divider()
                .opacity(0.4)
            
            // Destination
            VStack(alignment: .leading, spacing: 10) {
                Text("Save To")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                
                Picker("Destination", selection: $outputOption) {
                    ForEach(OutputFolderOption.allCases) { option in
                        Label(option.rawValue, systemImage: option.iconName)
                            .tag(option)
                    }
                }
                .pickerStyle(.segmented)
                
                if outputOption == .custom {
                    HStack {
                        Image(systemName: "folder")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(customFolderURL?.path ?? "No folder chosen yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        Spacer()
                        
                        Button("Browse...", action: onChooseCustomFolder)
                            .font(.caption.weight(.medium))
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                    }
                    .padding(.top, 2)
                }
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 18)
    }
}

struct ModernFormatCard: View {
    let format: AudioFormat
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(accentGradient.opacity(isSelected ? 0.25 : 0.1))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: format == .m4a ? "music.note" : "waveform.path")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
                    }
                    
                    Spacer()
                    
                    Text(format.badge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(isSelected ? Color.white : Color.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            isSelected ? AnyShapeStyle(accentGradient) : AnyShapeStyle(Color.primary.opacity(0.08))
                        )
                        .clipShape(Capsule())
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(format.title)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text(format.subtitle)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.10) : Color.primary.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        isSelected
                            ? AnyShapeStyle(accentGradient)
                            : AnyShapeStyle(Color.white.opacity(isHovered ? 0.25 : 0.1)),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .shadow(color: isSelected ? Color.accentColor.opacity(0.18) : .clear, radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        .onHover { isHovered = $0 }
    }
    
    private var accentGradient: LinearGradient {
        if format == .m4a {
            return LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
