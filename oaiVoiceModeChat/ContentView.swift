import AVFoundation
import CoreText
import HighlightedTextEditor
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
    let createTime: Double?
}

struct ContentView: View {

    @State private var messages: [AppMessage] = []

    @State private var authToken: String =
        UserDefaults.standard.string(forKey: "authToken") ?? ""
    @State private var isListening: Bool = false
    @State private var onLatestConversation: Bool = false
    @State private var messageIds: [String] = []
    @State private var conversationId: String = ""
    @State private var conversationTitle: String = ""
    @State private var scrollProxy: ScrollViewProxy?
    @State private var latestConversationCutoff: Double = 30
    @State private var retrievalSpeed: Double = 3

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

            if let codeBlockRange = message.text.range(
                of: "```[\\s\\S]*?```", options: .regularExpression)
            {
                let beforeCode = String(message.text[..<codeBlockRange.lowerBound])
                let code = String(message.text[codeBlockRange])
                let afterCode = String(message.text[codeBlockRange.upperBound...])

                VStack(alignment: .leading) {
                    if !beforeCode.isEmpty {
                        Text(.init(convertStringToMarkdown(message: beforeCode)))
                            .textSelection(.enabled)
                    }

                    let language = code.components(separatedBy: "\n")[0].replacingOccurrences(
                        of: "```", with: "")

                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Text(language)
                                .font(.system(size: 14))
                            Spacer()
                            Button(action: {
                                print("Copy")
                                let pasteboard = NSPasteboard.general
                                pasteboard.clearContents()
                                pasteboard.setString(
                                    code.replacingOccurrences(
                                        of: "```\\w*\\n?", with: "", options: .regularExpression),
                                    forType: .string)
                            }) {
                                Image(systemName: "doc.on.doc")
                            }
                        }
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, minHeight: 35)
                        .background(Color.gray.opacity(0.2))
                        HighlightedTextEditor(
                            text: .constant(
                                code.replacingOccurrences(
                                    of: "```\\w*\\n?", with: "", options: .regularExpression)),
                            highlightRules: [
                                //=====================================================
                                // 1) Swift Keywords
                                //=====================================================
                                HighlightRule(
                                    pattern: try! NSRegularExpression(
                                        pattern: #"""
                                                (?<!\w)(?:func|let|var|if|else|guard|switch|case|break|continue|
                                                return|while|for|in|init|deinit|throw|throws|rethrows|catch|as|
                                                Any|AnyObject|Protocol|Type|typealias|associatedtype|class|enum|
                                                extension|import|struct|subscript|where|self|Self|super|convenience|
                                                dynamic|final|indirect|lazy|mutating|nonmutating|optional|override|
                                                private|public|internal|fileprivate|open|required|static|unowned|
                                                weak|try|defer|repeat|fallthrough|operator|precedencegroup|inout|
                                                is)(?!\w)
                                            """#,
                                        options: [.allowCommentsAndWhitespace]
                                    ),
                                    formattingRules: [
                                        TextFormattingRule(fontTraits: .bold),
                                        TextFormattingRule(
                                            key: .foregroundColor, value: NSColor.systemPurple),
                                    ]
                                ),

                                //=====================================================
                                // 2) Python Keywords
                                //=====================================================
                                HighlightRule(
                                    pattern: try! NSRegularExpression(
                                        pattern: #"""
                                                (?<!\w)(?:def|class|import|from|as|if|elif|else|while|for|in|try|
                                                except|finally|raise|with|lambda|return|yield|global|nonlocal|
                                                pass|break|continue|True|False|None)(?!\w)
                                            """#,
                                        options: [.allowCommentsAndWhitespace]
                                    ),
                                    formattingRules: [
                                        TextFormattingRule(fontTraits: .bold),
                                        TextFormattingRule(
                                            key: .foregroundColor, value: NSColor.systemOrange),
                                    ]
                                ),

                                //=====================================================
                                // 3) Java / C / C++ / JavaScript-like Keywords
                                //=====================================================
                                HighlightRule(
                                    pattern: try! NSRegularExpression(
                                        pattern: #"""
                                                (?<!\w)(?:int|float|double|char|bool|void|class|public|private|
                                                protected|static|final|virtual|override|extends|implements|
                                                interface|new|return|break|continue|while|for|do|if|else|switch|
                                                case|default|try|catch|throw|null|this|package|import|function|
                                                let|var|const)(?!\w)
                                            """#,
                                        options: [.allowCommentsAndWhitespace]
                                    ),
                                    formattingRules: [
                                        TextFormattingRule(fontTraits: .bold),
                                        TextFormattingRule(
                                            key: .foregroundColor, value: NSColor.systemTeal),
                                    ]
                                ),

                                //=====================================================
                                // 4) Booleans & null-like values (multi-language)
                                //    (C/Java/JS/Python/Swift combos)
                                //=====================================================
                                HighlightRule(
                                    pattern: try! NSRegularExpression(
                                        pattern: #"""
                                                (?<!\w)(?:true|false|nil|None|null)(?!\w)
                                            """#
                                    ),
                                    formattingRules: [
                                        TextFormattingRule(fontTraits: .bold),
                                        TextFormattingRule(
                                            key: .foregroundColor, value: NSColor.systemRed),
                                    ]
                                ),

                                //=====================================================
                                // 5) Numeric literals
                                //=====================================================
                                HighlightRule(
                                    pattern: try! NSRegularExpression(
                                        pattern: #"""
                                                (?<!\w)\d+(?:\.\d+)?(?!\w)
                                            """#
                                    ),
                                    formattingRules: [
                                        TextFormattingRule(
                                            key: .foregroundColor, value: NSColor.systemBlue)
                                    ]
                                ),

                                //=====================================================
                                // 6) String literals ("double quoted")
                                //    If you want single quotes too, add pattern for '[^']*'
                                //=====================================================
                                HighlightRule(
                                    pattern: try! NSRegularExpression(
                                        pattern: #"""
                                                "[^"]*"
                                            """#
                                    ),
                                    formattingRules: [
                                        TextFormattingRule(
                                            key: .foregroundColor, value: NSColor.systemGreen)
                                    ]
                                ),

                                //=====================================================
                                // 7) Single-line comments (// or #)
                                //    - Many C-like languages use //
                                //    - Python uses #
                                //=====================================================
                                HighlightRule(
                                    pattern: try! NSRegularExpression(
                                        pattern: #"""
                                                (//.*|#.*)
                                            """#
                                    ),
                                    formattingRules: [
                                        TextFormattingRule(
                                            key: .foregroundColor, value: NSColor.gray)
                                    ]
                                ),

                                //=====================================================
                                // 8) Multi-line comments (/* ... */)
                                //    - Common in C, C++, Java, JavaScript
                                //    - We use a DOTALL-like approach to match across lines
                                //=====================================================
                                HighlightRule(
                                    pattern: try! NSRegularExpression(
                                        // (?s) allows dot to match newlines (in many regex engines).
                                        // But in NSRegularExpression, we approximate with [\s\S].
                                        pattern: #"""
                                                /\*[\s\S]*?\*/
                                            """#,
                                        options: []
                                    ),
                                    formattingRules: [
                                        TextFormattingRule(
                                            key: .foregroundColor, value: NSColor.darkGray)
                                    ]
                                ),
                            ]
                        )
                        .frame(height: CGFloat(code.components(separatedBy: .newlines).count) * 20)
                    }
                    .border(Color.gray.opacity(0.2), width: 1)
                    .cornerRadius(10)

                    if !afterCode.isEmpty {
                        Text(.init(convertStringToMarkdown(message: afterCode)))
                            .textSelection(.enabled)
                    }
                }

            } else {
                Text(.init(convertStringToMarkdown(message: message.text)))
                    .frame(minHeight: 40)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .textSelection(.enabled)
            }

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
            if conversationId != "" {
                print("Still retrieving latest messages...")
                DispatchQueue.main.async {
                    retrieveMessagesFromConversation()
                }
            } else {
                print("Retrieving latest conversation...")
                DispatchQueue.main.async {
                    retrieveLatestConversation()
                }
            }
        }
    }

    func convertStringToMarkdown(message: String) -> String {
        var markdown = message

        // Convert bold: **text** or __text__
        markdown = markdown.replacingOccurrences(
            of: "(\\*\\*|__)(.+?)(\\*\\*|__)",
            with: "**$2**",
            options: .regularExpression
        )

        // Convert italic: *text* or _text_
        markdown = markdown.replacingOccurrences(
            of: "(?<!\\*)(\\*|_)(?!\\*)(.*?)(?<!\\*)(\\*|_)(?!\\*)",
            with: "*$2*",
            options: .regularExpression
        )

        // Convert code blocks: ```text```
        markdown = markdown.replacingOccurrences(
            of: "```([\\s\\S]*?)```",
            with: "```\n$1\n```",
            options: .regularExpression
        )

        // Convert inline code: `text`
        markdown = markdown.replacingOccurrences(
            of: "`([^`]+)`",
            with: "`$1`",
            options: .regularExpression
        )

        // Convert links: [text](url)
        markdown = markdown.replacingOccurrences(
            of: "\\[([^\\]]+)\\]\\(([^\\)]+)\\)",
            with: "[$1]($2)",
            options: .regularExpression
        )

        // Convert bullet lists: * text or - text
        markdown = markdown.replacingOccurrences(
            of: "^[\\s]*(\\*|-)[\\s]+(.+)$",
            with: "• $2",
            options: [.regularExpression]
        )

        // Convert numbered lists: 1. text
        markdown = markdown.replacingOccurrences(
            of: "^[\\s]*\\d+\\.[\\s]+(.+)$",
            with: "1. $1",
            options: [.regularExpression]
        )

        return markdown
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
                    _ = firstItem.snippet ?? ""
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    guard let utcTime = formatter.date(from: firstItem.update_time) else {
                        print("Failed to parse conversation time")
                        return
                    }

                    // Both times in UTC for accurate comparison
                    let currentTimeUTC = Date()

                    print(currentTimeUTC)
                    print(utcTime)

                    print(
                        "Time since last conversation: \(currentTimeUTC.timeIntervalSince(utcTime)) seconds"
                    )

                    print(firstItem.title)
                    if currentTimeUTC.timeIntervalSince(utcTime) > Double(latestConversationCutoff)
                    {
                        print("Conversation is too old")
                    } else {
                        print("Conversation is new")
                        conversationId = firstItem.id ?? ""
                        DispatchQueue.main.async {
                            retrieveMessagesFromConversation()
                        }
                    }
                }

            } catch {
                print("Failed to decode conversation: \(error)")
            }
        }
        task.resume()
    }

    func retrieveMessagesFromConversation() {
        if authToken == "" {
            print("No OpenAI key found")
            return
        }

        print("Retrieving messages from conversation: \(conversationId)")

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
                conversationTitle = message.title ?? "New Conversation"
                if let mapping = message.mapping {

                    for (_, value) in mapping {
                        let messageId = value.message?.id
                        let author = value.message?.author
                        let content = value.message?.content?.parts?.first

                        if author?.role != "system" && messageId != nil
                            && !messageIds.contains(messageId ?? "") && content != nil
                        {
                            let isUser = author?.role == "user"
                            if case .string(let messageText) = content {
                                messages.insert(
                                    AppMessage(
                                        text: messageText, isUser: isUser, id: messageId ?? "",
                                        createTime: value.message?.create_time),
                                    at: 0)
                            }
                            if case .contentPart(let contentPart) = content {
                                let text = contentPart.text ?? "N/A"
                                messages.insert(
                                    AppMessage(
                                        text: text, isUser: isUser, id: messageId ?? "",
                                        createTime: value.message?.create_time),
                                    at: 0)
                            }
                            messageIds.append(messageId ?? "")
                        }

                    }
                }
            } catch {
                print("Failed to decode conversation: \(error)")
            }

            DispatchQueue.main.async {
                scrollProxy?.scrollTo("bottom", anchor: .bottom)
            }
        }
        task.resume()
    }

    func stopListening() {
        print("Stopping listening")
        timer?.invalidate()
        timer = nil
    }

    func saveAuthToken() {
        UserDefaults.standard.set(authToken, forKey: "authToken")
    }

    var settingsView: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Auth Token*").bold().font(.system(size: 12)).padding(.leading, 10).padding(
                    .top, 10)
                HStack {
                    SecureField("", text: $authToken)
                        .padding(.horizontal, 10)
                        .textFieldStyle(.roundedBorder)
                }
                HStack {
                    Text("Retrieval Speed").bold().font(.system(size: 12))
                    Button {
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .help(
                        "This is the speed at which the app will check for new messages in the conversation. Lower values will check more frequently, but may use more CPU."
                    )
                }
                .padding(.leading, 10)
                HStack {
                    Slider(value: $retrievalSpeed, in: 3...10, step: 0.25)
                        .padding(.horizontal, 10)
                    Text(String(format: "%.2f", retrievalSpeed))
                }
                HStack {
                    Text("Latest Conversation Cutoff").bold().font(.system(size: 12)).padding(
                        .leading, 10)
                    Button {
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .help(
                        "This is the cutoff time for a conversation to be considered 'new'. Lower values will ensure newer conversations are retrieved and older conversations will be ignored."
                    )
                }
                HStack {
                    Slider(value: $latestConversationCutoff, in: 1...3600)
                        .padding(.horizontal, 10)
                    Text(String(format: "%.2f", latestConversationCutoff))
                }
                Text("*Auth Token Tutorial").padding(.top, 10).padding(.leading, 10)
                Text(
                    "Note: this isn't just your OpenAI API key: this is your user auth token which is used to perform elevated actions for your account (dangerous)."
                ).bold().font(.system(size: 10)).padding(.leading, 10)
                Text("1. (Whilst logged in) head to: https://chatgpt.com").padding(.leading, 10)
                Text("2. Open your browser's developer tools and view the Network tab").padding(
                    .leading, 10)
                Text("3. Find the request to: https://chatgpt.com/backend-api/conversations").padding(
                    .leading, 10)
                Text(
                    "4. Copy & paste the Authorization header value (eyJhbGci...) into the field above"
                ).padding(.leading, 10)
                Image("AuthTokenTutorial")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 700, alignment: .center)
                    .padding(.leading, 10)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    var body: some View {
        ZStack(alignment: .top) {
            TranslucentView(material: .hudWindow)
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading, spacing: 0) {
                TabView {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Listen for latest conversation")
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
                                .font(.system(size: 20))
                                .scaledToFill()
                                .padding(isListening ? 0 : 4)
                            }
                            .buttonStyle(.borderless)
                            if !conversationId.isEmpty {
                                Text("Clear Conversation")
                                Button(action: {
                                    print("Clear conversation")
                                    messages = []
                                    conversationId = ""
                                    conversationTitle = ""
                                }) {
                                    Image(systemName: "clear")
                                }
                            }
                        }.frame(height: 40)
                        Divider()
                        if !conversationId.isEmpty {
                            VStack(alignment: .leading) {
                                Text("ID").font(.system(size: 12)).bold()
                                Text(conversationId).padding(.bottom, 4)
                                Text("Title").font(.system(size: 12)).bold()
                                Text(conversationTitle)
                            }.padding(.all, 4)
                            Divider()
                        } else if isListening {
                            VStack(alignment: .center) {
                                Text(
                                    "Searching for conversation created in the last 30 seconds..."
                                ).padding(.all, 4)
                            }
                        }
                        ScrollView {
                            ScrollViewReader { proxy in
                                LazyVStack {
                                    if messages.isEmpty {
                                        Text("No conversation selected").padding(.all, 4)
                                    }
                                    ForEach(
                                        messages.sorted(by: {
                                            ($0.createTime ?? 0) < ($1.createTime ?? 0)
                                        }
                                        ),
                                        id: \.text
                                    ) { message in
                                        if message.isUser {
                                            userMessage(message: message)
                                        } else {
                                            oaiMessage(message: message)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    Color.clear
                                        .frame(height: 1)
                                        .id("bottom")
                                }
                                .onAppear {
                                    print("onAppear")
                                    scrollProxy = proxy
                                }
                            }
                        }
                    }
                    .background(Color(.clear))
                    .tabItem {
                        Label("Conversation", systemImage: "message")
                    }
                    settingsView.tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                }.tabViewStyle(.sidebarAdaptable).frame(maxWidth: .infinity, maxHeight: .infinity)
                    .edgesIgnoringSafeArea(.all).padding(.all, 0)
            }
            .frame(maxWidth: .infinity, minHeight: 250, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
