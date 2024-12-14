import AVFoundation
import CoreText
import SwiftUI

struct ConversationItem: Decodable {
    let id: String?
    let title: String?
    let create_time: String
    let update_time: String
    let mapping: String?
    let current_node: String?
    let conversation_template_id: String?
    let gizmo_id: String?
    let is_archived: Bool
    let is_starred: Bool?
    let is_unread: Bool?
    let workspace_id: String?
    let async_status: String?
    let safe_urls: [String]?
    let conversation_origin: String?
    let snippet: String?
}

struct ConversationHistory: Decodable {
    let items: [ConversationItem]
}
struct Message: Decodable {
    let title: String?
    let create_time: Double?
    let update_time: Double?
    let mapping: [String: MessageNode]?
}

struct MessageNode: Decodable {
    let id: String
    let message: MessageContent?
    let parent: String?
    let children: [String]
}

struct MessageContent: Decodable {
    let id: String?
    let author: Author?
    let create_time: Double?
    let update_time: Double?
    let content: InnerContent?
    let status: String?
    let end_turn: Bool?
    let weight: Double?
    let metadata: MessageMetadata?
    let recipient: String?
    let channel: String?
}

struct Author: Decodable {
    let role: String
    let name: String?
    let metadata: [String: String]
}

struct InnerContent: Decodable {
    let content_type: String
    let parts: [ContentPartEnum?]?
}

enum ContentPartEnum: Decodable {
    case contentPart(ContentPart)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let contentPart = try? container.decode(ContentPart.self) {
            self = .contentPart(contentPart)
        } else {
            throw DecodingError.typeMismatch(
                ContentPartEnum.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected String or ContentPart"
                )
            )
        }
    }
}

struct ContentPart: Decodable {
    let content_type: String?
    let text: String?
    let direction: String?
    let decoding_id: String?
    let expiry_datetime: String?
    let frames_asset_pointers: [String]?
    let video_container_asset_pointer: String?
    let audio_asset_pointer: AudioAssetPointer?
    let audio_start_timestamp: Double?
}

struct AudioAssetPointer: Decodable {
    let expiry_datetime: String?
    let content_type: String
    let asset_pointer: String
    let size_bytes: Int
    let format: String
    let metadata: AudioMetadata
}

struct AudioMetadata: Decodable {
    let start_timestamp: Double?
    let end_timestamp: Double?
    let pretokenized_vq: String?
    let interruptions: String?
    let original_audio_source: String?
    let transcription: String?
    let start: Double?
    let end: Double?
}

struct MessageMetadata: Decodable {
    let voice_mode_message: Bool?
    let request_id: String?
    let message_source: String?
    let timestamp_: String?
    let message_type: String?
    let real_time_audio_has_video: Bool?
    let is_visually_hidden_from_conversation: Bool?
    let citations: [String]?
    let content_references: [String]?
    let is_complete: Bool?
    let parent_id: String?
    let model_switcher_deny: [ModelSwitcherDeny]?
}

struct ModelSwitcherDeny: Decodable {
    let slug: String
    let context: String
    let reason: String
    let description: String
}

struct AppMessage {
    let text: String
    let isUser: Bool
    let id: String
}

struct ContentView: View {

    @State private var messages: [AppMessage] = []

    @State private var authToken: String =
        UserDefaults.standard.string(forKey: "authToken") ?? ""
    @State private var isListening: Bool = false
    @State private var onLatestConversation: Bool = false
    @State private var retrievalSpeed: Int = 3

    func userMessage(message: AppMessage) -> some View {
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

    func oaiMessage(message: AppMessage) -> some View {
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
        // retrieveLatestConversation()
        retrieveMessagesFromConversation()
        // timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(retrievalSpeed), repeats: true)
        // { _ in
        //     print("Still listening...")
        //     retrieveLatestConversation()
        // }
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
                        print("Conversation id: \(String(describing: conversationId))")
                    }

                }

            } catch {
                print("Failed to decode conversation: \(error)")
            }
        }
        task.resume()
    }

    func retrieveMessagesFromConversation(
        conversationId: String = "675d127e-77dc-8004-99b8-bf077cd7876b"
    ) {
        if authToken == "" {
            print("No OpenAI key found")
            return
        }

        let url = URL(
            string: "https://chatgpt.com/backend-api/conversation/\(conversationId)")!

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
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 {
                    print("Unauthorized")
                    return
                }
            }
            do {
                let decoder = JSONDecoder()
                let message: Message = try decoder.decode(Message.self, from: data)
                print("message: \(String(describing: message.mapping?.first?.value.id)) retrieved")
                if let mapping = message.mapping {

                    for (_, value) in mapping {
                        let messageId = value.message?.id
                        let author = value.message?.author
                        let content = value.message?.content?.parts?.first

                        print(
                            "\(String(describing: messageId)), \(String(describing: author))  \(String(describing: content))"
                        )
                        if author?.role != "system" {
                            if case .string(let messageText) = content {
                                let isUser = author?.role == "user"
                                messages.append(
                                    AppMessage(
                                        text: messageText, isUser: isUser, id: messageId ?? ""))
                            } else if case .contentPart(let contentPart) = content,
                                let messageText = contentPart.text
                            {
                                let isUser = author?.role == "user"
                                messages.append(
                                    AppMessage(
                                        text: messageText, isUser: isUser, id: messageId ?? ""))
                            }
                        }

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
                        .onChange(of: authToken) { oldValue, newValue in
                            //save to app settings
                            UserDefaults.standard.set(newValue, forKey: "authToken")
                        }
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
