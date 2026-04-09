import SwiftUI
import AppKit

extension Notification.Name {
    static let alwaysOnTopChanged = Notification.Name("alwaysOnTopChanged")
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.configureWindow()
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applyWindowLevel),
            name: .alwaysOnTopChanged,
            object: nil
        )
    }

    private func configureWindow() {
        guard let window = NSApplication.shared.windows.first else { return }

        // Match the dark gradient colour so the title bar blends in seamlessly
        window.backgroundColor = NSColor(calibratedRed: 0.13, green: 0.10, blue: 0.22, alpha: 1.0)
        window.titlebarAppearsTransparent = true
        window.title = "Dachsy"

        window.isMovableByWindowBackground = true

        // All three traffic-light buttons fully enabled
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = false
        window.standardWindowButton(.zoomButton)?.isHidden = false

        // Position top-right on first launch
        if let screen = NSScreen.main {
            let x = screen.visibleFrame.maxX - 300
            let y = screen.visibleFrame.maxY - 440
            window.setFrameOrigin(NSPoint(x: x, y: y))
        }

        applyWindowLevel()
    }

    @objc private func applyWindowLevel() {
        guard let window = NSApplication.shared.windows.first else { return }
        let alwaysOnTop = UserDefaults.standard.bool(forKey: "alwaysOnTop")
        window.level = alwaysOnTop ? .floating : .normal
    }

    // Close button quits the app
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

// MARK: - Main App

@main
struct PetWidgetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .windowStyle(.titleBar)          // real, clickable title bar
        .windowResizability(.contentSize)
        .defaultSize(width: 280, height: 380)
    }
}
