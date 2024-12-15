import AVFoundation
import CoreText
import HighlightedTextEditor
import SwiftUI

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
    @State private var messageIds: [String] = []
    @State private var conversationId: String = ""
    @State private var conversationTitle: String = ""
    @State private var scrollProxy: ScrollViewProxy?
    @State private var latestConversationCutoff: Double =
        UserDefaults.standard.double(forKey: "latestConversationCutoff") ?? 30
    @State private var retrievalSpeed: Double =
        UserDefaults.standard.double(forKey: "retrievalSpeed") ?? 3

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
                        Text(.init(Constants.convertStringToMarkdown(message: beforeCode)))
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
                            highlightRules:
                            Constants.HIGHLIGHT_RULES
                            
                        )
                        .frame(height: CGFloat(code.components(separatedBy: .newlines).count) * 20)
                    }
                    .border(Color.gray.opacity(0.2), width: 1)
                    .cornerRadius(10)

                    if !afterCode.isEmpty {
                        Text(.init(Constants.convertStringToMarkdown(message: afterCode)))
                            .textSelection(.enabled)
                    }
                }

            } else {
                Text(.init(Constants.convertStringToMarkdown(message: message.text)))
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
                Text("Retrieval Speed").bold().font(.system(size: 12)).padding(.leading, 10)
                Text(
                    "This is the speed at which the app will check for new messages in the conversation. Lower values will check more frequently: used for rate limiting mitigation."
                ).font(.system(size: 10)).padding(.leading, 10).textSelection(.enabled)
                HStack {
                    Slider(value: $retrievalSpeed, in: 0.25...10, step: 0.25)
                        .onChange(of: retrievalSpeed) {
                            UserDefaults.standard.set(retrievalSpeed, forKey: "retrievalSpeed")
                        }
                        .padding(.horizontal, 10)
                    Text(String(format: "%.2f", retrievalSpeed) + "s")
                }
                Text("Latest Conversation Cutoff").bold().font(.system(size: 12)).padding(
                    .leading, 10)
                Text(
                    "This is the cutoff time for a conversation to be considered 'new'. Lower values will ensure newer conversations are retrieved and older conversations will be ignored."
                ).padding(.leading, 10).font(.system(size: 10)).textSelection(.enabled)
                HStack {
                    Slider(value: $latestConversationCutoff, in: 1...300)
                        .padding(.horizontal, 10)
                        .onChange(of: latestConversationCutoff) {
                            UserDefaults.standard.set(
                                latestConversationCutoff, forKey: "latestConversationCutoff")
                        }
                    Text(String(format: "%.2f", latestConversationCutoff) + "s")
                }
                Text("*Auth Token Tutorial").bold().padding(.top, 10).padding(.leading, 10)
                Text(
                    "Note: this isn't just your OpenAI API key: this is your user auth token which is used to perform elevated actions for your account (dangerous)."
                ).font(.system(size: 10)).padding(.leading, 10).textSelection(.enabled)
                Spacer()
                Text("1. (Whilst logged in) head to: https://chatgpt.com").padding(.leading, 10)
                    .textSelection(.enabled)
                Text("2. Open your browser's developer tools and view the Network tab").padding(
                    .leading, 10
                ).textSelection(.enabled)
                Text("3. Find the request to: https://chatgpt.com/backend-api/conversations")
                    .padding(.leading, 10).textSelection(.enabled)
                Text(
                    "4. Copy & paste the Authorization header value (eyJhbGci...) into the field above"
                ).padding(.leading, 10).textSelection(.enabled)
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
                            Text("Retrieve latest conversations:").padding(.leading, 10)
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
                        }
                        ScrollView {
                            ScrollViewReader { proxy in
                                LazyVStack {
                                    if messages.isEmpty {
                                        if isListening {
                                            Text(
                                                "Searching for conversations..."
                                            )
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .padding(.all, 4)
                                        } else {
                                            Text("No conversation selected")
                                        }
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
