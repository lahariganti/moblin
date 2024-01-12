import SwiftUI

struct StreamObsSettingsView: View {
    @EnvironmentObject var model: Model
    var stream: SettingsStream

    func submitWebSocketUrl(value: String) {
        let url = cleanUrl(url: value)
        if let message = isValidWebSocketUrl(url: url) {
            model.makeErrorToast(title: message)
            return
        }
        stream.obsWebSocketUrl = url
        model.store()
        if stream.enabled {
            model.obsWebSocketUrlUpdated()
        }
    }

    func submitWebSocketPassword(value: String) {
        stream.obsWebSocketPassword = value
        model.store()
        if stream.enabled {
            model.obsWebSocketPasswordUpdated()
        }
    }

    func submitSourceName(value: String) {
        stream.obsSourceName = value
        model.store()
    }

    var body: some View {
        Form {
            Section {
                NavigationLink(destination: TextEditView(
                    title: String(localized: "URL"),
                    value: stream.obsWebSocketUrl!,
                    onSubmit: submitWebSocketUrl,
                    footer: Text("For example ws://232.32.45.332:4567."),
                    keyboardType: .URL
                )) {
                    TextItemView(name: String(localized: "URL"), value: stream.obsWebSocketUrl!)
                }
                NavigationLink(destination: TextEditView(
                    title: String(localized: "Password"),
                    value: stream.obsWebSocketPassword!,
                    onSubmit: submitWebSocketPassword
                )) {
                    TextItemView(
                        name: String(localized: "Password"),
                        value: stream.obsWebSocketPassword!,
                        sensitive: true
                    )
                }
                NavigationLink(destination: TextEditView(
                    title: String(localized: "Source name"),
                    value: stream.obsSourceName!,
                    onSubmit: submitSourceName,
                    capitalize: true
                )) {
                    TextItemView(
                        name: String(localized: "Source name"),
                        value: stream.obsSourceName!
                    )
                }
            } header: {
                Text("WebSocket")
            }
        }
        .navigationTitle("OBS remote control")
        .toolbar {
            SettingsToolbar()
        }
    }
}
