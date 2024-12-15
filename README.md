# OpenAI Chat for Voice Mode

Adds realtime chat for voice mode to allow you to copy code and read what was said in real time.

Xcode: 16.0

![](/example.png)

Auth Token Tutorial

Note: this isn't just your OpenAI API key: this is your user auth token which is used to perform elevated actions for your account (dangerous).

1. (Whilst logged in) head to: https://chatgpt.com
2. Open your browser's developer tools and view the Network tab
3. Find the request to: https://chatgpt.com/backend-api/conversations
4. Copy & paste the Authorization header value (eyJhbGci...) into the field above

![Auth Token Tutorial](/oaiVoiceModeChat/Assets.xcassets/AuthTokenTutorial.imageset/auth-token-tutorial.png)

Steps:

1. install via the releases tab on Github or by building and running this project with XCode

2. Once run: follow the auth token steps above and paste in your auth token (will need to be retrieved quite often) into the settings panel

3. Press the retrieve latest conversations button

4. Start an instance of ChatGPT Voice and it will retrieve that latest conversation and start outputting the messages from the exchange in real time

\*try playing with the other settings to find a flow that suits you
