//  CreateMemoryView.swift
//  Drift

import SwiftUI
import SwiftData
import PhotosUI
import Combine

struct CreateMemoryView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    @StateObject private var holder = ViewModelHolder()

    var body: some View {
        ZStack {
            DraftTheme.background.ignoresSafeArea()

            if let viewModel = holder.viewModel {
                CreateMemoryContent(viewModel: viewModel, dismiss: dismiss)
            }
        }
        .task {
            guard holder.viewModel == nil else { return }
            let vm = CreateMemoryViewModel(context: context)
            holder.viewModel = vm
            vm.onAppear()
        }
    }
}

/// Holds the lazily-created ViewModel so it can be built once the real
/// environment ModelContext is available, instead of a throwaway
/// container built inside `init()`.
@MainActor
private final class ViewModelHolder: ObservableObject {
    @Published var viewModel: CreateMemoryViewModel?
}

private struct CreateMemoryContent: View {

    @ObservedObject var viewModel: CreateMemoryViewModel
    let dismiss: DismissAction

    var body: some View {
        VStack(spacing: 0) {
            topBar
            Divider().overlay(DraftTheme.divider)
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    photoSection
                    textSection
                    metaSection
                    audioSection
                    Spacer(minLength: 80)
                }
            }
        }
        .onChange(of: viewModel.selectedPhoto) { _, item in
            viewModel.handlePhotoChange(item)
        }
    }
}

private extension CreateMemoryContent {

    var topBar: some View {
        HStack {
            Button("CANCEL") { Haptic.light(); dismiss() }
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundStyle(DraftTheme.secondary.opacity(0.6))
            Spacer()
            Text("NEW MEMORY")
                .font(.system(size: 11, weight: .medium))
                .tracking(3)
                .foregroundStyle(DraftTheme.text.opacity(0.3))
            Spacer()
            Button("SAVE") {
                if viewModel.save() { dismiss() }
            }
            .font(.system(size: 11, weight: .medium))
            .tracking(2)
            .foregroundStyle(viewModel.canSave ? DraftTheme.secondary : DraftTheme.secondary.opacity(0.3))
            .disabled(!viewModel.canSave)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .padding(.top, 44)
    }

    var photoSection: some View {
        let photoBinding = Binding<PhotosPickerItem?>(
            get: { viewModel.selectedPhoto },
            set: { viewModel.selectedPhoto = $0 }
        )
        return PhotosPicker(selection: photoBinding, matching: .images) {
            ZStack {
                if let data = viewModel.imageData, let ui = UIImage(data: data) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity).frame(height: 220)
                        .clipped()
                        .saturation(0.25).contrast(0.88)
                        .overlay { Rectangle().fill(Color(hex: "#3D2000").opacity(0.28)).blendMode(.multiply) }
                        .overlay {
                            LinearGradient(colors: [.clear, DraftTheme.background.opacity(0.5)],
                                           startPoint: .center, endPoint: .bottom)
                        }
                } else {
                    Rectangle()
                        .fill(DraftTheme.surface)
                        .frame(maxWidth: .infinity).frame(height: 160)
                        .overlay {
                            VStack(spacing: 10) {
                                Image(systemName: "photo")
                                    .font(.system(size: 24, weight: .ultraLight))
                                    .foregroundStyle(DraftTheme.secondary.opacity(0.4))
                                Text("ADD PHOTO")
                                    .font(.system(size: 9, weight: .medium))
                                    .tracking(3)
                                    .foregroundStyle(DraftTheme.secondary.opacity(0.4))
                            }
                        }
                }
            }
        }
    }

    var textSection: some View {
        let textBinding = Binding<String>(
            get: { viewModel.text },
            set: { viewModel.text = $0 }
        )
        return ZStack(alignment: .topLeading) {
            if viewModel.text.isEmpty {
                Text("What happened?")
                    .font(.system(size: 18, weight: .ultraLight))
                    .foregroundStyle(DraftTheme.text.opacity(0.18))
                    .padding(.top, 30).padding(.leading, 30)
            }
            TextEditor(text: textBinding)
                .font(.system(size: 18, weight: .ultraLight))
                .foregroundStyle(DraftTheme.text)
                .scrollContentBackground(.hidden)
                .background(.clear)
                .frame(minHeight: 150)
                .tint(DraftTheme.secondary)
                .padding(.horizontal, 24).padding(.vertical, 24)
        }
    }

    var metaSection: some View {
        VStack(spacing: 0) {
            Divider().overlay(DraftTheme.divider)
            HStack(spacing: 0) {
                metaItem(
                    label: "LOCATION",
                    value: viewModel.locationService.locationName.isEmpty
                        ? "LOCATING…"
                        : viewModel.locationService.locationName
                )
                Divider().overlay(DraftTheme.divider).frame(height: 52)
                metaItem(
                    label: "SEASON",
                    value: SeasonHelper.season(for: .now, latitude: viewModel.locationService.latitude)
                )
                Divider().overlay(DraftTheme.divider).frame(height: 52)
                metaItem(label: "TEMP", value: "—")
            }
            .frame(maxWidth: .infinity)
            Divider().overlay(DraftTheme.divider)
        }
    }

    func metaItem(label: String, value: String) -> some View {
        VStack(spacing: 5) {
            Text(label)
                .font(.system(size: 9, weight: .medium)).tracking(2)
                .foregroundStyle(DraftTheme.secondary.opacity(0.55))
            Text(value)
                .font(.system(size: 11, weight: .light)).tracking(1)
                .foregroundStyle(DraftTheme.text.opacity(0.7))
                .lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }

    var audioSection: some View {
        let audio = viewModel.audioService
        return Group {
            if let path = audio.savedPath {
                HStack(spacing: 16) {
                    Button {
                        audio.isPlaying ? audio.stopPlayback() : audio.startPlayback(path: path)
                    } label: {
                        ZStack {
                            Circle()
                                .fill(DraftTheme.secondary.opacity(0.12))
                                .frame(width: 48, height: 48)
                            Circle()
                                .stroke(DraftTheme.secondary.opacity(0.4), lineWidth: 1)
                                .frame(width: 48, height: 48)
                            Image(systemName: audio.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(DraftTheme.secondary)
                                .offset(x: audio.isPlaying ? 0 : 1)
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("VOICE NOTE")
                            .font(.system(size: 9, weight: .medium)).tracking(2)
                            .foregroundStyle(DraftTheme.secondary)
                        Text(audio.formattedDuration)
                            .font(.system(size: 12, weight: .ultraLight, design: .monospaced))
                            .foregroundStyle(DraftTheme.text.opacity(0.4))
                    }
                    Spacer()
                    Button { audio.deleteRecording(path: path) } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(DraftTheme.text.opacity(0.25))
                    }
                }
                .padding(.horizontal, 28).padding(.vertical, 24)
            } else {
                Button {
                    audio.isRecording ? audio.stopRecording() : audio.startRecording()
                } label: {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .stroke(DraftTheme.secondary.opacity(0.18), lineWidth: 2)
                                .frame(width: 44, height: 44)

                            Circle()
                                .trim(from: 0, to: audio.recordingProgress)
                                .stroke(
                                    DraftTheme.secondary,
                                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                                )
                                .frame(width: 44, height: 44)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear(duration: 0.1), value: audio.recordingProgress)

                            if audio.isRecording {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(DraftTheme.secondary)
                                    .frame(width: 12, height: 12)
                            } else {
                                Image(systemName: "mic")
                                    .font(.system(size: 15, weight: .light))
                                    .foregroundStyle(DraftTheme.secondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(audio.isRecording ? "RECORDING" : "ADD VOICE NOTE")
                                .font(.system(size: 9, weight: .medium)).tracking(2)
                                .foregroundStyle(DraftTheme.secondary)
                            Text(audio.isRecording ? "\(audio.formattedDuration) / 0:10" : "UP TO 10 SECONDS")
                                .font(.system(size: 11, weight: .ultraLight, design: .monospaced))
                                .foregroundStyle(DraftTheme.text.opacity(0.35))
                        }
                    }
                    .padding(.horizontal, 28).padding(.vertical, 24)
                }
            }
        }
    }
}
