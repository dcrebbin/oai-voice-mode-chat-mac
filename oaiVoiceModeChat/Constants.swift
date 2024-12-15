import CoreText
import HighlightedTextEditor
import SwiftUI

struct Constants {
    static let HIGHLIGHT_RULES: [HighlightRule] = [

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

    static func convertStringToMarkdown(message: String) -> String {
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
}
