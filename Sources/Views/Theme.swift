import SwiftUI

public enum Theme {
    // Exact color palette sampled directly from your design
    public static let bg = Color(red: 20/255, green: 20/255, blue: 20/255)               // #141414 Neutral dark canvas
    public static let panel = Color(red: 24/255, green: 24/255, blue: 24/255)            // #181818 Subtle surface
    public static let panelInset = Color(red: 16/255, green: 16/255, blue: 16/255)       // #101010 Inset dark container
    
    // Dividers & Borders
    public static let divider = Color(red: 34/255, green: 34/255, blue: 34/255)          // #222222 Thin divider line
    public static let border = Color(red: 42/255, green: 42/255, blue: 42/255)           // #2A2A2A Muted border
    public static let thumbnailBorder = Color.white.opacity(0.88)                         // Crisp white thumbnail outline
    
    // Blues
    public static let accent = Color(red: 20/255, green: 135/255, blue: 255/255)         // #1487FF Vibrant "Save Audio" blue
    public static let accentHover = Color(red: 38/255, green: 148/255, blue: 255/255)
    public static let playRing = Color(red: 61/255, green: 101/255, blue: 171/255)       // #3D65AB Circular play ring
    public static let playedWaveform = Color(red: 59/255, green: 102/255, blue: 145/255) // #3B6691 Slate blue played bar
    public static let unplayedWaveform = Color(red: 38/255, green: 38/255, blue: 38/255) // #262626 Dark gray unplayed bar
    
    // Typography
    public static let textPrimary = Color.white                                           // #FFFFFF Crisp white
    public static let textSecondary = Color(red: 130/255, green: 130/255, blue: 130/255) // #828282 Medium gray
    public static let textTertiary = Color(red: 95/255, green: 95/255, blue: 95/255)     // #5F5F5F Muted format label
}
