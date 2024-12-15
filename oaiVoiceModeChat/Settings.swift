import AVFoundation
import CoreText
import SwiftUI

struct SettingsView: View {
    @State private var authToken: String = ""

    init() {
        authToken = UserDefaults.standard.string(forKey: "authToken") ?? ""
    }

    func saveAuthToken() {
        UserDefaults.standard.set(authToken, forKey: "authToken")
    }

    var body: some View {
        ZStack(alignment: .top) {
            TranslucentView(material: .hudWindow)
                .edgesIgnoringSafeArea(.all)
            VStack(alignment: .leading, spacing: 0) {
                Text("Auth Token").bold().font(.system(size: 12))
                HStack {
                    SecureField("", text: $authToken)
                        .padding(.all, 4)
                        .textFieldStyle(.roundedBorder)
                    Button(action: saveAuthToken) {
                        Text("Save")
                    }
                }

            }
            .padding(.all, 6)
            .frame(maxWidth: .infinity, minHeight: 250, maxHeight: .infinity)
            .background(Color.clear)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
    }
}

#Preview {
    ContentView()
}
