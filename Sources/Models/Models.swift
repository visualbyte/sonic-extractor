import Foundation
import AppKit

public enum AudioFormat: String, CaseIterable, Identifiable {
    case m4a = "M4A"
    case wav = "WAV"
    
    public var id: String { rawValue }
    
    public var fileExtension: String {
        switch self {
        case .m4a: return "m4a"
        case .wav: return "wav"
        }
    }
    
    public var title: String {
        switch self {
        case .m4a: return "M4A (AAC)"
        case .wav: return "WAV (Lossless)"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .m4a: return "Compact size, high quality audio (Standard Apple format)"
        case .wav: return "Uncompressed 16-bit 44.1 kHz PCM (Studio quality)"
        }
    }
    
    public var badge: String {
        switch self {
        case .m4a: return "Compressed"
        case .wav: return "Lossless"
        }
    }
}

public enum OutputFolderOption: String, CaseIterable, Identifiable {
    case sameAsVideo = "Same as Video"
    case downloads = "Downloads"
    case desktop = "Desktop"
    case custom = "Custom Folder..."
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .sameAsVideo: return "folder.badge.gearshape"
        case .downloads: return "arrow.down.circle"
        case .desktop: return "menubar.dock.rectangle"
        case .custom: return "folder.badge.plus"
        }
    }
}

public struct VideoMetadata: Identifiable {
    public let id = UUID()
    public let url: URL
    public let filename: String
    public let fileSize: Int64
    public let durationSeconds: Double
    public let resolution: CGSize
    public let audioTrackCount: Int
    public let thumbnail: NSImage?
    
    public var formattedDuration: String {
        let totalSeconds = Int(durationSeconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    public var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    public var formattedResolution: String {
        if resolution.width > 0 && resolution.height > 0 {
            return "\(Int(resolution.width)) × \(Int(resolution.height))"
        }
        return "Unknown"
    }
}

public enum ExtractionState: Equatable {
    case idle
    case inspecting
    case ready
    case extracting(progress: Double)
    case completed(outputURL: URL, fileSize: Int64)
    case failed(message: String)
    
    public static func == (lhs: ExtractionState, rhs: ExtractionState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.inspecting, .inspecting), (.ready, .ready):
            return true
        case let (.extracting(p1), .extracting(p2)):
            return abs(p1 - p2) < 0.001
        case let (.completed(u1, s1), .completed(u2, s2)):
            return u1 == u2 && s1 == s2
        case let (.failed(m1), .failed(m2)):
            return m1 == m2
        default:
            return false
        }
    }
}
