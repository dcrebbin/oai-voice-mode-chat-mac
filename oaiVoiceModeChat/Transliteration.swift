import SwiftUI

struct Transliteration {

    static let mandarinMap: [String: String] = {
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
    static let cantoneseMap: [String: String] = {
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

    static func getRomanizationMap() -> [String: String] {
        switch ApplicationState.selectedLanguage {
        case "zh_CN":
            return mandarinMap
        case "zh_HK":
            return cantoneseMap
        default:
            return [:]
        }
    }

    static func transliterate(message: String) -> [[String: String]] {

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

struct FlowLayout: Layout {
    var spacing: CGFloat

    init(spacing: CGFloat = 10) {
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }

        var width: CGFloat = 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0

        for size in sizes {
            if x + size.width > (proposal.width ?? .infinity) {
                x = 0
                y += maxHeight + spacing
                maxHeight = 0
            }

            x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
            width = max(width, x)
            height = max(height, y + maxHeight)
        }

        return CGSize(width: width, height: height)
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }

        var x = bounds.minX
        var y = bounds.minY
        var maxHeight: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let size = sizes[index]

            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += maxHeight + spacing
                maxHeight = 0
            }

            subview.place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(size)
            )

            x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
        }
    }
}
