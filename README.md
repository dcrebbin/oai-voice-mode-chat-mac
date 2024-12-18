# Realtime Chat for Voice Mode (Windows) [Unofficial]

[Download here](https://github.com/dcrebbin/oai-voice-mode-chat-windows/releases)

**Other platforms:**

- Vscode Extension: https://github.com/dcrebbin/real-time-voice-chat-vscode (Unfinished)
- Chrome Extension: https://github.com/dcrebbin/voice-mode-real-time-chat-extension

NOTE: This is not a product from or afilitated with [OpenAI](https://openai.com)

Adds realtime chat for voice mode to allow you to copy code and read what was said in real time.

(Which is unsupported within any official Voice Mode experience in ChatGPT: and can only be accessed if you end the call or manually refresh the ChatGPT website)

**Video Demo:** https://www.youtube.com/watch?v=0gRkIgAmMEU

**Voice Mode**

![Example with voice mode](/example-1.png)

**Standard Chat**

![Example with standard chat](/example-2.png)

## Steps

1. Install via the releases tab on [Github](https://github.com/dcrebbin/oai-voice-mode-chat-windows/releases) or by running the Python script

2. Once run: follow the auth token steps below and paste in your auth token (will need to be retrieved quite often) into the settings panel

3. Press the retrieve latest conversations button

4. Start an instance of ChatGPT Voice and it will retrieve that latest conversation and start outputting the messages from the exchange in real time

\*try playing with the other settings to find a flow that suits you

### Auth Token Tutorial

NOTE: this isn't just your OpenAI API key: this is your user auth token which is used to perform elevated actions for your account (dangerous).

1. (Whilst logged in) head to: https://chatgpt.com
2. Open your browser's developer tools and view the Network tab
3. Find the request to: https://chatgpt.com/backend-api/conversations
4. Head to the Settings tab
5. Copy & paste the Authorization header value without "Bearer" (eyJhbGci...) into the auth token field

(v0.1.0-alpha bug: ensure both settings sliders are above 0 before using it)

![Auth Token Tutorial](/oaiVoiceModeChat/Assets.xcassets/AuthTokenTutorial.imageset/auth-token-tutorial.png)

### Setting up the Python environment on Windows

1. Install Python from the official website: https://www.python.org/downloads/
2. Clone the repository: `git clone https://github.com/dcrebbin/oai-voice-mode-chat-windows.git`
3. Navigate to the project directory: `cd oai-voice-mode-chat-windows`
4. Create a virtual environment: `python -m venv venv`
5. Activate the virtual environment:
   - On Windows: `venv\Scripts\activate`
6. Install the required dependencies: `pip install -r requirements.txt`
7. Run the application: `python main.py`
