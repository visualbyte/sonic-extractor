import SwiftUI
import AppKit

extension Notification.Name {
    static let openFileRequested = Notification.Name("openFileRequested")
    static let resetFileRequested = Notification.Name("resetFileRequested")
    static let saveAudioRequested = Notification.Name("saveAudioRequested")
}

@main
struct AudioExtractorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .windowToolbarStyle(.unified(showsTitle: false))
        .windowResizability(.contentSize)
        .defaultSize(width: 440, height: 370)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Video...") {
                    NotificationCenter.default.post(name: .openFileRequested, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("Close Video") {
                    NotificationCenter.default.post(name: .resetFileRequested, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Button("Save Audio...") {
                    NotificationCenter.default.post(name: .saveAudioRequested, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

