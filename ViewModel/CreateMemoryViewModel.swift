//  CreateMemoryViewModel.swift
//  Drift

import SwiftUI
import SwiftData
import PhotosUI
import Combine

@MainActor
final class CreateMemoryViewModel: ObservableObject {

    @Published var text         = ""
    @Published var imageData: Data? = nil
    @Published var selectedPhoto: PhotosPickerItem? = nil
    @Published var isSaving     = false
    @Published var appeared     = false

    let locationService = LocationService()
    let audioService    = AudioService()

    private var cancellables = Set<AnyCancellable>()
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context

        // Forward nested ObservableObject changes so the view re-renders
        // when AudioService or LocationService publish updates.
        audioService.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        locationService.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func onAppear() {
        locationService.request()
        withAnimation(.easeOut(duration: 0.5)) { appeared = true }
    }

    func handlePhotoChange(_ item: PhotosPickerItem?) {
        Task {
            imageData = try? await item?.loadTransferable(type: Data.self)
        }
    }

    var canSave: Bool {
        !text.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving
    }

    /// Persists the entry. Returns true on success so the view can dismiss itself.
    @discardableResult
    func save() -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        isSaving = true
        let entry = MemoryEntry(
            date: .now,
            text: trimmed,
            locationName: locationService.locationName,
            latitude: locationService.latitude,
            longitude: locationService.longitude,
            season: SeasonHelper.season(for: .now, latitude: locationService.latitude),
            temperature: "—",
            imageData: imageData,
            audioPath: audioService.savedPath
        )
        context.insert(entry)
        try? context.save()
        Haptic.success()
        return true
    }
}
