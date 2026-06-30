//  MemoryEntry.swift
//  Drift

import Foundation
import SwiftData

@Model
final class MemoryEntry {

    var id: UUID
    var date: Date
    var text: String

    var locationName: String
    var latitude: Double?
    var longitude: Double?

    var season: String
    var temperature: String

    @Attribute(.externalStorage) var imageData: Data?
    var audioPath: String?

    init(
        date: Date = .now,
        text: String = "",
        locationName: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        season: String = "",
        temperature: String = "",
        imageData: Data? = nil,
        audioPath: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.text = text
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.season = season
        self.temperature = temperature
        self.imageData = imageData
        self.audioPath = audioPath
    }

    var formattedTime: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date).uppercased()
    }

    var formattedMonth: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }
}
