import SwiftUI

@main
struct AudioExtractorApp: App {
    var body: some Scene {
        WindowGroup("SonicExtractor") {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 440, height: 300)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("File") {
                Button("Open Video...") {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenVideoFile"), object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
        }
    }
}
