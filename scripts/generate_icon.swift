import AppKit

func renderIcon(size: CGFloat) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let inset = size * 0.08
    let iconRect = rect.insetBy(dx: inset, dy: inset)
    let cornerRadius = size * 0.22
    
    // Background squircle path
    let path = NSBezierPath(roundedRect: iconRect, xRadius: cornerRadius, yRadius: cornerRadius)
    
    // Background gradient (Deep modern violet / indigo / cyan)
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.10, green: 0.12, blue: 0.25, alpha: 1.0),
        NSColor(calibratedRed: 0.22, green: 0.12, blue: 0.38, alpha: 1.0),
        NSColor(calibratedRed: 0.38, green: 0.14, blue: 0.50, alpha: 1.0)
    ])
    gradient?.draw(in: path, angle: -45)
    
    // Border highlight
    NSColor(calibratedWhite: 1.0, alpha: 0.18).setStroke()
    path.lineWidth = max(1.0, size * 0.015)
    path.stroke()
    
    // Draw glowing waveform bars
    let barCount = 7
    let barWidth = size * 0.05
    let spacing = size * 0.035
    let totalWidth = CGFloat(barCount) * barWidth + CGFloat(barCount - 1) * spacing
    let startX = (size - totalWidth) / 2
    let centerY = size * 0.48
    let heights: [CGFloat] = [0.22, 0.45, 0.32, 0.65, 0.42, 0.52, 0.26]
    
    for i in 0..<barCount {
        let h = size * heights[i]
        let barRect = NSRect(
            x: startX + CGFloat(i) * (barWidth + spacing),
            y: centerY - h / 2,
            width: barWidth,
            height: h
        )
        let barPath = NSBezierPath(roundedRect: barRect, xRadius: barWidth/2, yRadius: barWidth/2)
        
        let barColor = NSColor(
            calibratedRed: 0.25 + CGFloat(i) * 0.09,
            green: 0.75 + CGFloat(i) * 0.03,
            blue: 1.0,
            alpha: 0.95
        )
        barColor.setFill()
        barPath.fill()
    }
    
    // Small musical note or emblem near bottom right
    let emblemRadius = size * 0.12
    let emblemCenter = NSPoint(x: iconRect.maxX - size * 0.18, y: iconRect.minY + size * 0.18)
    let emblemPath = NSBezierPath(ovalIn: NSRect(x: emblemCenter.x - emblemRadius, y: emblemCenter.y - emblemRadius, width: emblemRadius * 2, height: emblemRadius * 2))
    NSColor(calibratedRed: 1.0, green: 0.3, blue: 0.5, alpha: 0.9).setFill()
    emblemPath.fill()
    
    img.unlockFocus()
    return img
}

func savePNG(image: NSImage, to url: URL) {
    if let tiff = image.tiffRepresentation,
       let rep = NSBitmapImageRep(data: tiff),
       let png = rep.representation(using: .png, properties: [:]) {
        try? png.write(to: url)
    }
}

let fm = FileManager.default
let iconsetPath = "/tmp/AppIcon.iconset"
try? fm.removeItem(atPath: iconsetPath)
try? fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

let sizes: [(String, CGFloat)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

for (name, size) in sizes {
    let img = renderIcon(size: size)
    let fileURL = URL(fileURLWithPath: "\(iconsetPath)/\(name)")
    savePNG(image: img, to: fileURL)
}

print("Generated iconset successfully.")
