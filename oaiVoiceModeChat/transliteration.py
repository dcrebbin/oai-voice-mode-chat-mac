import json

class Transliteration:
    @staticmethod
    def load_mappings(file_path):
        with open(file_path, 'r', encoding='utf-8') as file:
            return json.load(file)

    @staticmethod
    def transliterate(text, mappings):
        transliterated_text = []
        for char in text:
            if char in mappings:
                transliterated_text.append(mappings[char])
            else:
                transliterated_text.append(char)
        return ''.join(transliterated_text)

# Load Mandarin and Cantonese mappings
mandarin_mappings = Transliteration.load_mappings('mandarin.json')
cantonese_mappings = Transliteration.load_mappings('cantonese.json')

# Example usage
text = "你好"
mandarin_transliterated = Transliteration.transliterate(text, mandarin_mappings)
cantonese_transliterated = Transliteration.transliterate(text, cantonese_mappings)

print("Mandarin Transliteration:", mandarin_transliterated)
print("Cantonese Transliteration:", cantonese_transliterated)
