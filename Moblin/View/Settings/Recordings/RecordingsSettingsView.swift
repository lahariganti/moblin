import SwiftUI

struct RecordingsSettingsView: View {
    @EnvironmentObject var model: Model

    var recordingsStorage: RecordingsStorage {
        model.recordingsStorage
    }

    var body: some View {
        VStack {
            HStack {
                Spacer()
                VStack {
                    Text(recordingsStorage.numberOfRecordingsString())
                        .font(.title2)
                    Text("Total recordings")
                        .font(.subheadline)
                }
                Spacer()
                VStack {
                    Text(recordingsStorage.totalSizeString())
                        .font(.title2)
                    Text("Total size")
                        .font(.subheadline)
                }
                Spacer()
            }
            Form {
                Section {
                    List {
                        ForEach(recordingsStorage.database.recordings) { recording in
                            NavigationLink(
                                destination: RecordingsRecordingSettingsView(recording: recording)
                            ) {
                                HStack {
                                    Image(systemName: "photo")
                                    VStack(alignment: .leading) {
                                        Text(recording.title())
                                        Text(recording.subTitle())
                                            .font(.footnote)
                                    }
                                }
                            }
                        }
                        .onDelete(perform: { indexSet in
                            for index in indexSet {
                                recordingsStorage.database.recordings[index].url().remove()
                            }
                            recordingsStorage.database.recordings.remove(atOffsets: indexSet)
                            recordingsStorage.store()
                        })
                    }
                }
            }
            Spacer()
        }
        .navigationTitle("Recordings")
        .toolbar {
            SettingsToolbar()
        }
    }
}
