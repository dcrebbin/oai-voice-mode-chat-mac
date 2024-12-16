import AppKit
import SwiftUI

class StatusBarController {
    private var statusItem: NSStatusItem?

    @objc func toggleWindow() {
        print("toggleWindow")
        if NSApp.isActive {
            print("App is active, hiding")
            NSApp.hide(nil)
        } else {
            print("App is not active, showing")
            NSApp.unhide(nil)
            NSApp.activate(ignoringOtherApps: true)
            if let window = NSApp.windows.first {
                if window.isMiniaturized {
                    window.deminiaturize(nil)
                    window.center()
                }
                window.makeKeyAndOrderFront(nil)
                window.level = .floating
            }
        }
    }

    func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: 16)
        if let button: NSStatusBarButton = statusItem?.button {
            statusItem?.button?.image = NSImage(named: NSImage.Name("MenuIcon"))
            statusItem?.button?.image?.size = NSSize(width: 18.0, height: 18.0)
            statusItem?.button?.imagePosition = .imageOnly

            button.action = #selector(toggleWindow)
            button.sendAction(on: [.leftMouseDown])
        }
    }
}

@main
struct oaiVoiceModeChatApp: App {
    private let statusBarController = StatusBarController()

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

struct KeyCombo {
    let key: Key
    let modifiers: NSEvent.ModifierFlags

    enum Key {
        case t
        case o

        var carbonKeyCode: UInt16 {
            switch self {
            case .t: return 0x11
            case .o: return 0x1F
            }
        }
    }
}

extension NSStatusBarButton {
    func rightMouseDown(handler: @escaping (NSEvent) -> Void) {
        self.sendAction(on: [.rightMouseDown])

        NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown]) { event in
            if event.window == self.window {
                handler(event)
                return nil
            }
            return event
        }
    }
}
