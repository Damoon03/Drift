//  TimelineView.swift
//  Drift

import SwiftUI
import SwiftData

struct TimelineView: View {

    @Query(sort: \MemoryEntry.date, order: .reverse) private var entries: [MemoryEntry]
    @Environment(\.modelContext) private var context

    @StateObject private var viewModel = TimelineViewModel()

    var body: some View {
        ZStack {
            DraftTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(entries) { entry in
                            SwipeToDeleteRow(onDelete: {
                                Haptic.warning()
                                withAnimation(.easeOut(duration: 0.25)) {
                                    context.delete(entry)
                                    try? context.save()
                                }
                            }) {
                                Button {
                                    Haptic.light()
                                    viewModel.selectedEntry = entry
                                } label: {
                                    MemoryCard(entry: entry)
                                }
                                .buttonStyle(.plain)
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    Haptic.warning()
                                    context.delete(entry)
                                    try? context.save()
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                        if entries.isEmpty { emptyState }
                        Spacer(minLength: 140)
                    }
                }
            }

            bottomBar
        }
        .ignoresSafeArea()
        .onAppear { viewModel.onAppear() }
        .sheet(isPresented: $viewModel.showCreate) {
            CreateMemoryView()
        }
        .sheet(item: $viewModel.selectedEntry) { entry in
            MemoryDetailView(entry: entry)
        }
        .fullScreenCover(isPresented: $viewModel.showMap) {
            MemoryMapView(entries: entries)
        }
    }
}

private extension TimelineView {

    var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer().frame(height: 54)
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TIMELINE")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(4)
                        .foregroundStyle(DraftTheme.secondary)
                    Text(viewModel.currentMonth)
                        .font(.custom("Georgia", size: 30))
                        .foregroundStyle(DraftTheme.text)
                }
                Spacer()
                Text("\(entries.count)")
                    .font(.system(size: 11, weight: .ultraLight, design: .monospaced))
                    .foregroundStyle(DraftTheme.text.opacity(0.2))
                    .padding(.bottom, 6)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 22)
            .opacity(viewModel.appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.7), value: viewModel.appeared)
        }
    }

    var bottomBar: some View {
        VStack {
            Spacer()
            Rectangle()
                .fill(.ultraThinMaterial)
                .frame(height: 110)
                .overlay(alignment: .top) { Divider().overlay(DraftTheme.divider) }
                .mask {
                    LinearGradient(
                        colors: [.clear, .black],
                        startPoint: .top,
                        endPoint: .init(x: 0.5, y: 0.35)
                    )
                }
        }
        .overlay(alignment: .bottom) {
            HStack {
                Button {
                    Haptic.light()
                    viewModel.showMap = true
                } label: {
                    Text("MAP")
                        .tracking(4)
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(DraftTheme.secondary)
                }
                Spacer()
                Button {
                    Haptic.medium()
                    viewModel.showCreate = true
                } label: {
                    ZStack {
                        Circle()
                            .stroke(DraftTheme.secondary.opacity(0.45), lineWidth: 1)
                        Image(systemName: "plus")
                            .font(.system(size: 26, weight: .ultraLight))
                            .foregroundStyle(DraftTheme.secondary)
                    }
                    .frame(width: 80, height: 80)
                }
                Spacer()
                Text("MEM")
                    .tracking(4)
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(DraftTheme.secondary.opacity(0.35))
            }
            .padding(.horizontal, 52)
            .padding(.bottom, 32)
        }
    }

    var emptyState: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 100)
            Text("no memories yet.")
                .font(.custom("Georgia-Italic", size: 17))
                .foregroundStyle(DraftTheme.text.opacity(0.18))
        }
    }
}

#Preview {
    TimelineView()
        .preferredColorScheme(.dark)
}
