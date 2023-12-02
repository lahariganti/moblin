import SwiftUI

struct StreamYouTubeSettingsView: View {
    @EnvironmentObject var model: Model
    var stream: SettingsStream

    func submitApiKey(value: String) {
        stream.youTubeApiKey = value
        model.store()
        if stream.enabled {
            model.youTubeApiKeyUpdated()
        }
    }

    func submitVideoId(value: String) {
        stream.youTubeVideoId = value
        model.store()
        if stream.enabled {
            model.youTubeVideoIdUpdated()
        }
    }

    var body: some View {
        Form {
            Section {
                NavigationLink(destination: TextEditView(
                    title: String(localized: "API key"),
                    value: stream.youTubeApiKey!,
                    onSubmit: submitApiKey
                )) {
                    TextItemView(name: String(localized: "API key"), value: stream.youTubeApiKey!)
                }
                NavigationLink(destination: TextEditView(
                    title: String(localized: "Video id"),
                    value: stream.youTubeVideoId!,
                    onSubmit: submitVideoId
                )) {
                    TextItemView(name: String(localized: "Video id"), value: stream.youTubeVideoId!)
                }
            } footer: {
                Text("Very experimental and very secret!")
            }
        }
        .navigationTitle("YouTube")
        .toolbar {
            SettingsToolbar()
        }
    }
}
