import AVFoundation
import CoreText
import SwiftUI

struct Message {
    let text: String
    let isUser: Bool
}

struct ContentView: View {

    @State private var messages: [Message] = [
        Message(text: "hey", isUser: true),
        Message(text: "Hey, Devon! How’s it going?", isUser: false),
    ]

    @State private var authToken: String = ""

    func userMessage(message: Message) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(message.text)
                .font(.system(size: 16))
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(20)
        }
        .frame(minWidth: 40, maxWidth: .infinity, minHeight: 40, alignment: .trailing)
    }

    func oaiMessage(message: Message) -> some View {
        HStack(spacing: 2) {
            Image(nsImage: NSImage(named: "oai")!)
                .resizable()
                .frame(width: 18, height: 18)
                .padding(.all, 4)
                .background(Color.black)
                .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 2))
                .clipShape(Circle())
            Text(message.text)
                .font(.system(size: 16))
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
        }
        .frame(minWidth: 40, maxWidth: .infinity, minHeight: 40, alignment: .leading)
    }

    var body: some View {
        ZStack(alignment: .top) {
            VisualEffectView(material: .hudWindow)
                .edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading, spacing: 0) {
                Text("Auth Token").bold().padding(.all, 4)
                SecureField("", text: $authToken)
                    .padding(.all, 4)
                    .textFieldStyle(.roundedBorder)

                ScrollView {
                    ForEach(messages, id: \.text) { message in
                        if message.isUser {
                            userMessage(message: message)
                        } else {
                            oaiMessage(message: message)
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .padding(.all, 4)
            }
            .padding(.all, 6)
            .frame(maxWidth: .infinity, minHeight: 250, maxHeight: .infinity)
            .background(Color.clear)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}

struct VisualEffectView: NSViewRepresentable {
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

#Preview {
    ContentView()
}
