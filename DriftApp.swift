//  DriftApp.swift
//  Drift

import SwiftUI
import SwiftData

@main
struct DriftApp: App {
    var body: some Scene {
        WindowGroup {
            TimelineView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: MemoryEntry.self)
    }
}
