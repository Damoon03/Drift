//  MemoryMapViewModel.swift
//  Drift

import SwiftUI
import MapKit
import Combine

@MainActor
final class MemoryMapViewModel: ObservableObject {

    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522),
        span: MKCoordinateSpan(latitudeDelta: 40, longitudeDelta: 40)
    )
    @Published var selectedEntry: MemoryEntry? = nil

    let entries: [MemoryEntry]

    init(entries: [MemoryEntry]) {
        self.entries = entries
    }

    var mappable: [MemoryEntry] {
        entries.filter { $0.latitude != nil && $0.longitude != nil }
    }

    func onAppear() {
        fitToEntries()
    }

    func selectPin(_ entry: MemoryEntry) {
        selectedEntry = (selectedEntry?.id == entry.id) ? nil : entry
    }

    func dismissCard() {
        selectedEntry = nil
    }

    func fitToEntries() {
        guard !mappable.isEmpty else { return }
        let lats = mappable.compactMap { $0.latitude }
        let lons = mappable.compactMap { $0.longitude }
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLon = lons.min()!, maxLon = lons.max()!
        region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: (minLat + maxLat) / 2,
                longitude: (minLon + maxLon) / 2
            ),
            span: MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.8, 0.08),
                longitudeDelta: max((maxLon - minLon) * 1.8, 0.08)
            )
        )
    }
}
