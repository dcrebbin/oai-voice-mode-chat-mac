import SwiftUI

struct Settings: View {

    @State private var authToken = ApplicationState.authToken
    @State private var retrievalSpeed = ApplicationState.retrievalSpeed
    @State private var latestConversationCutoff = ApplicationState.latestConversationCutoff
    var body: some View {

        var version =
            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

        ScrollView {
            VStack(alignment: .leading) {
                Text("Voice Mode Chat for Mac v" + version).padding(.leading, 10).padding(.top, 10)
                Divider()
                Text("Auth Token*").bold().font(.system(size: 12)).padding(.leading, 10).padding(
                    .top, 10)
                HStack {
                    SecureField("", text: $authToken)
                        .padding(.horizontal, 10)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: authToken) {
                            ApplicationState.authToken = authToken
                            UserDefaults.standard.set(authToken, forKey: "authToken")
                        }
                }
                Text("Retrieval Speed").bold().font(.system(size: 12)).padding(.leading, 10)
                Text(
                    "This is the speed at which the app will check for new messages in the conversation. Lower values will check more frequently: used for rate limiting mitigation."
                ).font(.system(size: 10)).padding(.leading, 10).textSelection(.enabled)
                HStack {
                    Slider(value: $retrievalSpeed, in: 0.25...10, step: 0.25)
                        .onChange(of: retrievalSpeed) {
                            ApplicationState.retrievalSpeed = retrievalSpeed
                            UserDefaults.standard.set(
                                ApplicationState.retrievalSpeed, forKey: "retrievalSpeed")
                        }
                        .padding(.horizontal, 10)
                    Text(String(format: "%.2f", retrievalSpeed) + "s")
                }
                Text("Latest Conversation Cutoff").bold().font(.system(size: 12)).padding(
                    .leading, 10)
                Text(
                    "This is the cutoff time for a conversation to be considered 'new'. Lower values will ensure newer conversations are retrieved and older conversations will be ignored."
                ).padding(.leading, 10).font(.system(size: 10)).textSelection(.enabled)
                HStack {
                    Slider(value: $latestConversationCutoff, in: 1...300)
                        .padding(.horizontal, 10)
                        .onChange(of: latestConversationCutoff) {
                            ApplicationState.latestConversationCutoff = latestConversationCutoff
                            UserDefaults.standard.set(
                                ApplicationState.latestConversationCutoff,
                                forKey: "latestConversationCutoff")
                        }
                    Text(String(format: "%.2f", latestConversationCutoff) + "s")
                }
                Text("*Auth Token Tutorial").bold().padding(.top, 10).padding(.leading, 10)
                Text(
                    "Note: this isn't just your OpenAI API key: this is your user auth token which is used to perform elevated actions for your account (dangerous)."
                ).font(.system(size: 10)).padding(.leading, 10).textSelection(.enabled)
                Spacer()
                Text("1. (Whilst logged in) head to: https://chatgpt.com").padding(.leading, 10)
                    .textSelection(.enabled)
                Text("2. Open your browser's developer tools and view the Network tab").padding(
                    .leading, 10
                ).textSelection(.enabled)
                Text("3. Find the request to: https://chatgpt.com/backend-api/conversations")
                    .padding(.leading, 10).textSelection(.enabled)
                Text(
                    "4. Copy & paste the Authorization header value (eyJhbGci...) into the field above"
                ).padding(.leading, 10).textSelection(.enabled)
                Image("AuthTokenTutorial")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 700, alignment: .center)
                    .padding(.leading, 10)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
