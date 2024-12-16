import SwiftUI

struct OpenAI {

    static func callCompletionsAPI(message: String) async -> String {
        if ApplicationState.openAiApiKey == "" {
            print("No OpenAI key found")
            return ""
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        //api key
        //http request headers
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(ApplicationState.openAiApiKey)",
        ]
        //http request body
        let body: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "system",
                    "content":
                        "Translate the given \(ApplicationState.selectedLanguage == "zh_CN" ? "Mandarin" : "Cantonese") text into English: \(message). ONLY output the translation, no other text.",
                ]
            ],
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []),
                let responseDict = responseJSON as? [String: Any],
                let choices = responseDict["choices"] as? [[String: Any]],
                let message = choices.first?["message"] as? [String: Any],
                let content = message["content"] as? String
            {
                return content
            }
        } catch {
            print("Error: \(error.localizedDescription)")
        }

        return ""
    }

}
