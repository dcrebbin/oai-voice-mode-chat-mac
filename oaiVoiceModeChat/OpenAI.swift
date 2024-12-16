import SwiftUI

struct OpenAI {

    func callCompletionsAPI(message: String) -> String {
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

        var translatedContent = ""
        let semaphore = DispatchSemaphore(value: 0)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }

            guard let data = data, error == nil else {
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            if let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []),
                let responseDict = responseJSON as? [String: Any],
                let choices = responseDict["choices"] as? [[String: Any]],
                let message = choices.first?["message"] as? [String: Any],
                let content = message["content"] as? String
            {
                translatedContent = content
            }
        }
        task.resume()

        _ = semaphore.wait(timeout: .now() + 10)
        return translatedContent
    }

}
