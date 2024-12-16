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
    @State private var isListening: Bool = false
    @State private var messageIds: [String] = []
    @State private var conversationId: String = ""
    @State private var conversationTitle: String = ""
    @State private var scrollProxy: ScrollViewProxy?
    @State private var errorText: String?

    func userMessage(message: AppMessage) -> some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(message.text)
                .font(.system(size: 14))
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(20)
                .textSelection(.enabled)
        }
        .frame(minWidth: 40, maxWidth: .infinity, minHeight: 40, alignment: .trailing)
    }

    func oaiMessage(message: AppMessage) -> some View {
        HStack(spacing: 2) {
            Image(nsImage: NSImage(named: "OAI")!)
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
                            .textSelection(.enabled).font(.system(size: 14))
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
                            .textSelection(.enabled).font(.system(size: 14))
                    }
                }

            } else {
                Text(.init(Constants.convertStringToMarkdown(message: message.text)))
                    .font(.system(size: 14))
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
        isListening = true
        retrieveLatestConversation()
        timer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(ApplicationState.retrievalSpeed), repeats: true
        ) { _ in
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
        if ApplicationState.authToken == "" {
            logError(
                error: NSError(
                    domain: "", code: 0,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "No OpenAI auth token found: please set one in settings"
                    ]))
            return
        }

        let url = URL(
            string: "https://chatgpt.com/backend-api/conversations?offset=0&limit=1&order=updated")!

        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(ApplicationState.authToken)",
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                logError(error: error)
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 {
                    logError(
                        error: NSError(
                            domain: "", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "Unauthorized"]))
                    return
                }
            }
            do {
                let decoder = JSONDecoder()
                let conversationHistory = try decoder.decode(ConversationHistory.self, from: data)

                if let firstItem = conversationHistory.items.first {
                    _ = firstItem.snippet ?? ""
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    guard let utcTime = formatter.date(from: firstItem.update_time) else {
                        logError(error: error)
                        return
                    }
                    let currentTimeUTC = Date()
                    print(currentTimeUTC)
                    print(utcTime)

                    print(
                        "Time since last conversation: \(currentTimeUTC.timeIntervalSince(utcTime)) seconds"
                    )

                    if currentTimeUTC.timeIntervalSince(utcTime)
                        > ApplicationState.latestConversationCutoff
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
                logError(error: error)
                return
            }
        }
        task.resume()
    }

    func logError(error: Error?) {
        print("Error: \(error?.localizedDescription ?? "Unknown error")")
        errorText = "Error: \(error?.localizedDescription ?? "Unknown error")"
        stopListening()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            errorText = nil
        }
    }

    func retrieveMessagesFromConversation() {
        if ApplicationState.authToken == "" {
            print("No OpenAI key found")
            return
        }

        print("Retrieving messages from conversation: \(conversationId)")

        let url = URL(
            string: "https://chatgpt.com/backend-api/conversation/\(conversationId)")!

        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(ApplicationState.authToken)",
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                logError(error: error)
                return
            }
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 401 {
                    logError(
                        error: NSError(
                            domain: "", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "Unauthorized"]))
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
                return
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
        isListening = false
    }

    @State private var isHoveringClearButton: Bool = false
    @State private var isHoveringRetrieveLatestChatButton: Bool = false

    var body: some View {
        ZStack(alignment: .top) {
            TranslucentView(material: .hudWindow)
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading, spacing: 0) {
                TabView {
                    VStack(alignment: .leading) {
                        HStack(alignment: .center) {
                            Text("Retrieve latest chat").padding(.leading, 10)
                            Button(action: toggleListening) {
                                Image(
                                    systemName: {
                                        if isListening {
                                            return "waveform"
                                        } else {
                                            return "waveform.slash"
                                        }
                                    }()
                                )
                                .font(.system(size: 20))
                                .scaledToFit()
                                .padding(.all, 4)
                                .padding(.vertical, isListening ? 1 : 0)
                            }
                            .background(
                                isHoveringRetrieveLatestChatButton
                                    ? Color.gray.opacity(0.2) : Color.clear
                            )
                            .cornerRadius(8)
                            .onHover { hovering in
                                if hovering {
                                    isHoveringRetrieveLatestChatButton = true
                                } else {
                                    isHoveringRetrieveLatestChatButton = false
                                }
                            }

                            .buttonStyle(.borderless)
                            if !conversationId.isEmpty {
                                Text("Clear")
                                Button(action: {
                                    print("Clear conversation")
                                    messages = []
                                    conversationId = ""
                                    conversationTitle = ""
                                }) {
                                    Image(systemName: "trash").font(.system(size: 20))
                                        .scaledToFit()
                                        .padding(.all, 4)
                                }.onHover { hovering in
                                    if hovering {
                                        isHoveringClearButton = true
                                    } else {
                                        isHoveringClearButton = false
                                    }
                                }
                                .background(
                                    isHoveringClearButton
                                        ? Color.gray.opacity(0.2) : Color.clear
                                )
                                .buttonStyle(.borderless)
                            }
                        }.frame(
                            maxWidth: .infinity,
                            minHeight: 40
                        )
                        .padding(.all, 4)
                        .background(.gray.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.5), lineWidth: 1)
                        )
                        .cornerRadius(10)
                        .frame(maxWidth: .infinity, maxHeight: 40)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 10)
                        .padding(.horizontal, 10)
                        if !conversationId.isEmpty {
                            VStack(alignment: .leading) {
                                Text("ID").font(.system(size: 12)).bold()
                                Text(conversationId).padding(.bottom, 2).textSelection(.enabled)
                                Text("Title").font(.system(size: 12)).bold()
                                Text(conversationTitle).textSelection(.enabled)
                            }.padding(.all, 2)
                            Divider()
                        }
                        ScrollView {
                            ScrollViewReader { proxy in
                                LazyVStack {
                                    if messages.isEmpty {
                                        if isListening {
                                            Text(
                                                "Searching for chats created in the last \(Int(ApplicationState.latestConversationCutoff)) seconds..."
                                            )
                                            .multilineTextAlignment(.center)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                            .padding(.all, 4)
                                        } else {
                                            Text("No chat selected")
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
                        if let errorText = errorText {
                            Text(errorText)
                                .foregroundColor(.red)
                                .padding(.all, 4)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .background(Color(.clear))
                    .tabItem {
                        Label("Conversation", systemImage: "message")
                    }
                    Settings().tabItem {
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
