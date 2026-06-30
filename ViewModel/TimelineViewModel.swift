//  TimelineViewModel.swift
//  Drift

import SwiftUI
import Combine

@MainActor
final class TimelineViewModel: ObservableObject {

    @Published var selectedEntry: MemoryEntry? = nil
    @Published var showCreate   = false
    @Published var showMap      = false
    @Published var appeared     = false

    func onAppear() {
        withAnimation(.easeOut(duration: 0.6)) { appeared = true }
    }

    var currentMonth: String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: .now)
    }
}
