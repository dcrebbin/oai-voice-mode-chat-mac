import SwiftUI

struct Transliteration {

    @State private var mandarinMap: [String: String] = {
        if let path = Bundle.main.path(
            forResource: "mandarin", ofType: "json")
        {
            print("Path found: \(path)")
            if FileManager.default.fileExists(atPath: path) {
                print("File exists at path")
            } else {
                print("File does not exist at path")
            }
        } else {
            print("Path not found")
        }
        if let path = Bundle.main.path(
            forResource: "mandarin", ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: String]
        {
            print(dict["一"] ?? "no")
            return dict
        }
        return [:]
    }()
    let cantoneseMap: [String: String] = {
        if let path = Bundle.main.path(
            forResource: "cantonese", ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: [String]]
        {
            return dict.reduce(into: [String: String]()) { result, pair in
                if let firstReading = pair.value.first {
                    result[pair.key] = firstReading
                }
            }
        }
        return [:]
    }()

    func getRomanizationMap() -> [String: String] {
        switch ApplicationState.selectedLanguage {
        case "zh_CN":
            return mandarinMap
        case "zh_HK":
            return cantoneseMap
        }
    }

    func transliterate(message: String) -> [[String: String]] {

        let romanizationMap = getRomanizationMap()
        var transliteratedChars: [[String: String]] = []
        var nonChineseBuffer = ""
        let characters = Array(message)

        for (index, char) in characters.enumerated() {
            let charString = String(char)
            if let pinyin = romanizationMap[charString] {
                if !nonChineseBuffer.isEmpty {
                    transliteratedChars.append(["char": nonChineseBuffer, "pinyin": ""])
                    nonChineseBuffer = ""
                }
                transliteratedChars.append(["char": charString, "pinyin": pinyin])
            } else {
                nonChineseBuffer += charString
                if index == characters.count - 1
                    || (index + 1 < characters.count
                        && romanizationMap[String(characters[index + 1])] != nil)
                {
                    transliteratedChars.append(["char": nonChineseBuffer, "pinyin": ""])
                    nonChineseBuffer = ""
                }
            }
        }

        return transliteratedChars
    }
}
