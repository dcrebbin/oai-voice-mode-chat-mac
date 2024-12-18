HIGHLIGHT_RULES = [
    {
        "pattern": r"(?<!\w)(?:func|let|var|if|else|guard|switch|case|break|continue|return|while|for|in|init|deinit|throw|throws|rethrows|catch|as|Any|AnyObject|Protocol|Type|typealias|associatedtype|class|enum|extension|import|struct|subscript|where|self|Self|super|convenience|dynamic|final|indirect|lazy|mutating|nonmutating|optional|override|private|public|internal|fileprivate|open|required|static|unowned|weak|try|defer|repeat|fallthrough|operator|precedencegroup|inout|is)(?!\w)",
        "formatting_rules": {
            "font_weight": "bold",
            "color": "purple"
        }
    },
    {
        "pattern": r"(?<!\w)(?:def|class|import|from|as|if|elif|else|while|for|in|try|except|finally|raise|with|lambda|return|yield|global|nonlocal|pass|break|continue|True|False|None)(?!\w)",
        "formatting_rules": {
            "font_weight": "bold",
            "color": "orange"
        }
    },
    {
        "pattern": r"(?<!\w)(?:int|float|double|char|bool|void|class|public|private|protected|static|final|virtual|override|extends|implements|interface|new|return|break|continue|while|for|do|if|else|switch|case|default|try|catch|throw|null|this|package|import|function|let|var|const)(?!\w)",
        "formatting_rules": {
            "font_weight": "bold",
            "color": "teal"
        }
    },
    {
        "pattern": r"(?<!\w)(?:true|false|nil|None|null)(?!\w)",
        "formatting_rules": {
            "font_weight": "bold",
            "color": "red"
        }
    },
    {
        "pattern": r"(?<!\w)\d+(?:\.\d+)?(?!\w)",
        "formatting_rules": {
            "color": "blue"
        }
    },
    {
        "pattern": r"\"[^\"]*\"",
        "formatting_rules": {
            "color": "green"
        }
    },
    {
        "pattern": r"(//.*|#.*)",
        "formatting_rules": {
            "color": "gray"
        }
    },
    {
        "pattern": r"/\*[\s\S]*?\*/",
        "formatting_rules": {
            "color": "darkgray"
        }
    }
]

def convert_string_to_markdown(message):
    import re

    # Convert bold: **text** or __text__
    message = re.sub(r"(\*\*|__)(.+?)(\*\*|__)", r"**\2**", message)

    # Convert italic: *text* or _text_
    message = re.sub(r"(?<!\*)(\*|_)(?!\*)(.*?)(?<!\*)(\*|_)(?!\*)", r"*\2*", message)

    # Convert code blocks: ```text```
    message = re.sub(r"```([\s\S]*?)```", r"```\n\1\n```", message)

    # Convert inline code: `text`
    message = re.sub(r"`([^`]+)`", r"`\1`", message)

    # Convert links: [text](url)
    message = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r"[\1](\2)", message)

    # Convert bullet lists: * text or - text
    message = re.sub(r"^[\s]*(\*|-)[\s]+(.+)$", r"• \2", message, flags=re.MULTILINE)

    # Convert numbered lists: 1. text
    message = re.sub(r"^[\s]*\d+\.[\s]+(.+)$", r"1. \1", message, flags=re.MULTILINE)

    return message
