import Foundation
import SwiftUI

private let recordingsDirectory = URL.documentsDirectory.appending(component: "Recordings")

class Recording: Identifiable, Codable {
    var id: UUID = .init()
    var settings: SettingsStream
    var startTime: Date = .init()
    var stopTime: Date = .init()
    var size: UInt64? = 0
    var description: String? = ""

    init(settings: SettingsStream) {
        self.settings = settings
    }

    func subTitle() -> String {
        if let description, !description.isEmpty {
            return description
        } else {
            return "\(settings.resolutionString()), \(settings.fps) FPS, \(size!.formatBytes())"
        }
    }

    func name() -> String {
        return "\(id).mp4"
    }

    func length() -> Duration {
        return Duration(
            secondsComponent: Int64(stopTime.timeIntervalSince(startTime)),
            attosecondsComponent: 0
        )
    }

    func url() -> URL {
        return recordingsDirectory.appending(component: name())
    }

    func shareUrl() -> URL {
        return url()
    }

    func sizeString() -> String {
        return size!.formatBytes()
    }
}

class RecordingsDatabase: Codable {
    var recordings: [Recording] = []

    static func fromString(settings: String) throws -> RecordingsDatabase {
        let database = try JSONDecoder().decode(
            RecordingsDatabase.self,
            from: settings.data(using: .utf8)!
        )
        return database
    }

    func toString() throws -> String {
        return try String(decoding: JSONEncoder().encode(self), as: UTF8.self)
    }
}

final class RecordingsStorage {
    private var realDatabase = RecordingsDatabase()
    var database: RecordingsDatabase {
        realDatabase
    }

    @AppStorage("recordings") var storage = ""

    init() {
        do {
            try FileManager.default.createDirectory(
                at: recordingsDirectory,
                withIntermediateDirectories: true
            )
        } catch {
            logger.error("Failed to create recordings directory with error \(error.localizedDescription)")
        }
    }

    func load() {
        do {
            try tryLoadAndMigrate(settings: storage)
        } catch {
            logger.info("recordings: Failed to load with error \(error). Using default.")
            realDatabase = RecordingsDatabase()
        }
        cleanup()
    }

    private func cleanup() {
        guard let enumerator = FileManager.default.enumerator(
            at: recordingsDirectory,
            includingPropertiesForKeys: nil
        ) else {
            return
        }
        for case let fileUrl as URL in enumerator
            where !database.recordings.contains(where: { recording in
                fileUrl.resolvingSymlinksInPath() == recording.url().resolvingSymlinksInPath()
            })
        {
            logger.info("recordings: Removing unused file \(fileUrl)")
            fileUrl.remove()
        }
    }

    private func tryLoadAndMigrate(settings: String) throws {
        realDatabase = try RecordingsDatabase.fromString(settings: settings)
        migrateFromOlderVersions()
    }

    func store() {
        do {
            storage = try realDatabase.toString()
        } catch {
            logger.error("recordings: Failed to store.")
        }
    }

    private func migrateFromOlderVersions() {
        for recording in database.recordings where recording.size == nil {
            recording.size = 0
            store()
        }
    }

    func createRecording(settings: SettingsStream) -> Recording {
        return Recording(settings: settings)
    }

    func append(recording: Recording) {
        while database.recordings.count > 100 {
            _ = database.recordings.popLast()
        }
        recording.size = recording.url().fileSize
        recording.stopTime = Date()
        database.recordings.insert(recording, at: 0)
    }

    func numberOfRecordingsString() -> String {
        return String(database.recordings.count)
    }

    func totalSizeString() -> String {
        return database.recordings.reduce(0) { total, recording in
            total + recording.size!
        }.formatBytes()
    }
}
