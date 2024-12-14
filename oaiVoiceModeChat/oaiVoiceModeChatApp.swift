import AppKit
import SwiftUI

@main
struct oaiVoiceModeChatApp: App {
    @State private var globalHotkeyMonitor: Any?
    @State private var localHotkeyMonitor: Any?
    @State private var isWindowVisible = true
    @State private var statusItem: NSStatusItem?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modifier(TranslucentWindowModifier())
                .onAppear {
                    registerShortcut()
                    setupStatusBarItem()
                }
                .onDisappear {
                    unregisterShortcut()
                }
        }
    }

    private func registerShortcut() {
        globalHotkeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown, .flagsChanged])
        { event in
            print("Global event captured:", event.type, event.keyCode, event.modifierFlags)
            handleHotkey(event: event)
        }

        localHotkeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) {
            event in
            print("Local event captured:", event.type, event.keyCode, event.modifierFlags)
            handleHotkey(event: event)
            return event
        }
    }

    private func handleHotkey(event: NSEvent) {
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains([
            .command, .option, .control,
        ]) {
            print("Toggle shortcut detected")
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
    }

    private func unregisterShortcut() {
        if let monitor = globalHotkeyMonitor {
            NSEvent.removeMonitor(monitor)
            globalHotkeyMonitor = nil
        }
        if let monitor = localHotkeyMonitor {
            NSEvent.removeMonitor(monitor)
            localHotkeyMonitor = nil
        }
    }

    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: 16)
        if let button: NSStatusBarButton = statusItem?.button {
            statusItem?.button?.image = NSImage(named: NSImage.Name("icon"))
            statusItem?.button?.image?.size = NSSize(width: 24.0, height: 24.0)
            statusItem?.button?.imagePosition = .imageOnly
            button.target = ToolbarDelegate.shared
            button.action = #selector(ToolbarDelegate.shared.toggleWindow)
            button.sendAction(on: [.leftMouseUp])
        }

    }
}

struct TranslucentWindowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                WindowAccessor { window in
                    guard let window = window else { return }
                    window.level = .floating
                    let customToolbar: NSToolbar = NSToolbar(identifier: "MainToolbar")
                    window.setContentSize(NSSize(width: 400, height: 200))
                    window.appearance = NSAppearance(named: .vibrantDark)
                    window.titlebarAppearsTransparent = true
                    window.isMovableByWindowBackground = true
                    window.toolbar = customToolbar
                }
            )
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

class ToolbarDelegate: NSObject, NSToolbarDelegate {
    static let shared = ToolbarDelegate()
    var items: [NSToolbarItem] = []
    func toolbar(
        _ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        switch itemIdentifier.rawValue {
        case "CustomTitle":
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "ChatGPT Voice Mode Chat"
            return item

        default:
            return nil
        }
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            NSToolbarItem.Identifier("CustomTitle"),
            .flexibleSpace,
        ]
    }
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    @objc func toggleWindow() {
        if NSApp.isActive {
            NSApp.hide(nil)
        } else {
            NSApp.unhide(nil)
            NSApp.activate(ignoringOtherApps: true)
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
