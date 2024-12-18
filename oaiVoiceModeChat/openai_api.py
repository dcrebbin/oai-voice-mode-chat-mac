import requests
import json

class OpenAI:
    @staticmethod
    def call_completions_api(message):
        if ApplicationState.openai_api_key() == "":
            print("No OpenAI key found")
            return ""

        url = "https://api.openai.com/v1/chat/completions"
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {ApplicationState.openai_api_key()}",
        }
        body = {
            "model": "gpt-4o-mini",
            "messages": [
                {
                    "role": "system",
                    "content": f"Translate the given {ApplicationState.selected_language()} text into English: {message}. ONLY output the translation, no other text.",
                }
            ],
        }

        response = requests.post(url, headers=headers, data=json.dumps(body))
        if response.status_code == 200:
            response_json = response.json()
            choices = response_json.get("choices", [])
            if choices:
                message_content = choices[0].get("message", {}).get("content", "")
                return message_content
        else:
            print(f"Error: {response.status_code} - {response.text}")

        return ""
