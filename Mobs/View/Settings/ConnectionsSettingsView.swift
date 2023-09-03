import SwiftUI

struct ConnectionsSettingsView: View {
    @ObservedObject var model: Model

    var database: Database {
        get {
            model.settings.database
        }
    }

    var body: some View {
        VStack {
            Form {
                ForEach(database.connections) { connection in
                    NavigationLink(destination: ConnectionSettingsView(connection: connection, model: model)) {
                        Toggle(connection.name, isOn: Binding(get: {
                            connection.enabled
                        }, set: { value in
                            connection.enabled = value
                            for oconnection in database.connections {
                                if oconnection.id != connection.id {
                                    oconnection.enabled = false
                                }
                            }
                            model.store()
                            model.reloadConnection()
                            model.objectWillChange.send()
                        }))
                        .disabled(connection.enabled)
                    }
                }
                .onDelete(perform: { offsets in
                    database.connections.remove(atOffsets: offsets)
                    model.store()
                    model.objectWillChange.send()
                })
                CreateButtonView(action: {
                    database.connections.append(SettingsConnection(name: "My connection"))
                    model.store()
                    model.objectWillChange.send()
                })
            }
        }
        .navigationTitle("Connections")
    }
}
