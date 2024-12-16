import AppKit
import SwiftUI

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem?

    @objc func toggleWindow() {
        if NSApp.isActive {
            NSApp.hide(nil)
        } else {
            NSApp.unhide(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: 16)
        if let button: NSStatusBarButton = statusItem?.button {
            print("button: \(button)")
            statusItem?.button?.image = NSImage(named: NSImage.Name("MenuIcon"))
            statusItem?.button?.image?.size = NSSize(width: 18.0, height: 18.0)
            statusItem?.button?.imagePosition = .imageOnly
            button.target = self
            button.action = #selector(toggleWindow)
            button.sendAction(on: [.leftMouseDown, .rightMouseDown, .leftMouseUp, .rightMouseUp])
        }
    }
}

@main
struct oaiVoiceModeChatApp: App {
    private var statusBarController = StatusBarController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modifier(TranslucentWindowModifier())
                .onAppear {
                    statusBarController.setupStatusBarItem()
                }
        }
    }
}

struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [weak view] in
            self.callback(view?.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
    }
}
