import AVFoundation
import CoreText
import SwiftUI

struct Message {
    let text: String
    let isUser: Bool
}

struct ConversationItem: Decodable {
    let id: String
    let title: String
    let create_time: String
    let update_time: String
    let mapping: String?
    let current_node: String?
    let conversation_template_id: String?
    let gizmo_id: String?
    let is_archived: Bool
    let is_starred: Bool?
    let is_unread: Bool
    let workspace_id: String?
    let async_status: String?
    let safe_urls: [String]
    let conversation_origin: String?
    let snippet: String?
}

struct ConversationHistory: Decodable {
    let items: [ConversationItem]
}

struct ContentView: View {

    @State private var messages: [Message] = [
        Message(text: "hey", isUser: true),
        Message(text: "Hey, Devon! How’s it going?", isUser: false),
    ]

    @State private var authToken: String = ""
    @State private var isListening: Bool = false
    @State private var onLatestConversation: Bool = false
    @State private var retrievalSpeed: Int = 3

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

    func toggleListening() {
        isListening.toggle()
        if isListening {
            startListening()
        } else {
            stopListening()
        }
    }

    @State private var timer: Timer?

    func startListening() {
        print("Starting listening")
        retrieveLatestConversation()
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(retrievalSpeed), repeats: true)
        { _ in
            print("Still listening...")
            retrieveLatestConversation()
        }
    }

    func retrieveLatestConversation() {
        if authToken == "" {
            print("No OpenAI key found")
            return
        }

        let url = URL(
            string: "https://chatgpt.com/backend-api/conversations?offset=0&limit=1&order=updated")!

        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(authToken)",
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            do {
                let decoder = JSONDecoder()
                let conversationHistory = try decoder.decode(ConversationHistory.self, from: data)

                if let firstItem = conversationHistory.items.first {
                    let conversationId = firstItem.id
                    let content = firstItem.snippet ?? ""
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    let conversationCreatedTime = formatter.date(from: firstItem.create_time)
                    let currentTime = Date()
                    print(
                        "Time since last conversation: \(currentTime.timeIntervalSince(conversationCreatedTime!)) seconds"
                    )

                    if currentTime.timeIntervalSince(conversationCreatedTime!) > 30 {
                        print("Conversation is too old")
                    } else {
                        print("Conversation is new")
                        print("Conversation content: \(content)")
                        print("Conversation id: \(conversationId)")
                    }

                }

            } catch {
                print("Failed to decode conversation: \(error)")
            }
        }
        task.resume()
    }

    func stopListening() {
        print("Stopping listening")
        timer?.invalidate()
        timer = nil
    }

    var body: some View {
        ZStack(alignment: .top) {
            VisualEffectView(material: .hudWindow)
                .edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading, spacing: 0) {
                Text("Auth Token").bold().padding(.all, 4)
                HStack {
                    SecureField("", text: $authToken)
                        .padding(.all, 4)
                        .textFieldStyle(.roundedBorder)
                    Button(action: toggleListening) {
                        Image(
                            systemName: {
                                if isListening {
                                    return "speaker.wave.2.fill"
                                } else {
                                    return "speaker.slash.fill"
                                }
                            }()
                        )
                        .font(.system(size: 20))  // Made icon bigger
                        .scaledToFill()
                        .padding(isListening ? 0 : 4)
                    }
                    .buttonStyle(.borderless)
                }.frame(height: 40)
                Divider()
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
