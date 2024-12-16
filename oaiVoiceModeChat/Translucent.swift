import AppKit
import SwiftUI

struct TranslucentView: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .active

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}

struct TranslucentWindowModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                WindowAccessor { window in
                    guard let window = window else { return }
                    window.level = .floating
                    window.setContentSize(NSSize(width: 450, height: 440))
                    window.appearance = NSAppearance(named: .vibrantDark)
                    window.titlebarAppearsTransparent = false
                    window.isMovableByWindowBackground = true
                }
            )
    }
}
