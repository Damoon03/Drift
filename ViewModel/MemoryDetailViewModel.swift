//  MemoryDetailViewModel.swift
//  Drift

import SwiftUI
import Combine

@MainActor
final class MemoryDetailViewModel: ObservableObject {

    @Published var showPhoto  = false
    @Published var showMeta   = false
    @Published var showText   = false
    @Published var showAudio  = false

    let audioService = AudioService()
    let entry: MemoryEntry

    private var cancellables = Set<AnyCancellable>()

    init(entry: MemoryEntry) {
        self.entry = entry

        audioService.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    func onAppear() {
        showPhoto = true
        showMeta  = true
        showText  = true
        showAudio = true

        // Let the photo/text fade-in breathe for a moment before the
        // voice note starts, so it feels like the memory "wakes up."
        if let path = entry.audioPath {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 900_000_000)
                self.audioService.startPlayback(path: path)
            }
        }
    }

    func toggleAudio() {
        guard let path = entry.audioPath else { return }
        audioService.isPlaying
            ? audioService.stopPlayback()
            : audioService.startPlayback(path: path)
    }
}
