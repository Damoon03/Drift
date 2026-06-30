//  MemoryDetailView.swift
//  Drift

import SwiftUI

struct MemoryDetailView: View {

    @StateObject private var viewModel: MemoryDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(entry: MemoryEntry) {
        _viewModel = StateObject(wrappedValue: MemoryDetailViewModel(entry: entry))
    }

    private var hasPhoto: Bool { viewModel.entry.imageData != nil }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                DraftTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        heroPhoto(width: proxy.size.width)

                        VStack(alignment: .leading, spacing: 36) {
                            metaBlock
                            bodyText
                            if viewModel.entry.audioPath != nil { audioBlock }
                            dateStamp
                        }
                        .frame(width: proxy.size.width, alignment: .leading)
                        .padding(.horizontal, 32)
                        .padding(.top, hasPhoto ? 28 : 0)
                        .padding(.bottom, 80)
                    }
                    .frame(width: proxy.size.width, alignment: .leading)
                }
                // Only the photo bleeds into the top safe area; text content
                // always respects it so nothing collides with the notch and
                // text-only memories aren't stranded with dead space above.
                .ignoresSafeArea(.container, edges: hasPhoto ? .top : [])

                closeButton
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.audioService.stopPlayback() }
    }
}

private extension MemoryDetailView {

    func heroPhoto(width: CGFloat) -> some View {
        Group {
            if let data = viewModel.entry.imageData, let ui = UIImage(data: data) {
                let isExtremeLandscape = ui.size.height > 0 && (ui.size.width / ui.size.height) > 2.0

                ZStack {
                    DraftTheme.surface

                    if isExtremeLandscape {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFit()
                            .frame(width: width)
                    } else {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                    }
                }
                .frame(width: width, height: 380)
                .clipped()
                .saturation(0.22).contrast(0.85).brightness(-0.05)
                .overlay { Rectangle().fill(Color(hex: "#3D2000").opacity(0.30)).blendMode(.multiply) }
                .overlay {
                    LinearGradient(colors: [.clear, DraftTheme.background],
                                   startPoint: .init(x: 0.5, y: 0.6), endPoint: .bottom)
                }
                .overlay { FilmGrainView().opacity(0.07).blendMode(.overlay) }
                .scaleEffect(viewModel.showPhoto ? 1 : 1.06)
                .opacity(viewModel.showPhoto ? 1 : 0)
                .animation(.easeOut(duration: 1.1), value: viewModel.showPhoto)
            } else {
                // Text-only memory: small breathing room instead of a
                // collapsed zero-height image and stranded content below.
                Spacer().frame(width: width, height: 64)
            }
        }
    }

    var metaBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(viewModel.entry.formattedTime)
                Circle().frame(width: 3, height: 3)
                Text(viewModel.entry.locationName.isEmpty ? "UNKNOWN" : viewModel.entry.locationName.uppercased())
                    .lineLimit(1)
            }
            .font(.system(size: 11, weight: .medium)).tracking(2)
            .foregroundStyle(DraftTheme.secondary)

            HStack(spacing: 10) {
                Text(viewModel.entry.season.isEmpty ? "—" : viewModel.entry.season)
                Circle().frame(width: 3, height: 3)
                Text(viewModel.entry.temperature.isEmpty ? "—" : viewModel.entry.temperature)
            }
            .font(.system(size: 11, weight: .light)).tracking(2)
            .foregroundStyle(DraftTheme.text.opacity(0.35))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(viewModel.showMeta ? 1 : 0)
        .offset(y: viewModel.showMeta ? 0 : 10)
        .animation(.easeOut(duration: 0.8).delay(0.25), value: viewModel.showMeta)
    }

    var bodyText: some View {
        Text(viewModel.entry.text)
            .font(.system(size: 21, weight: .ultraLight))
            .foregroundStyle(DraftTheme.text.opacity(0.88))
            .lineSpacing(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .opacity(viewModel.showText ? 1 : 0)
            .offset(y: viewModel.showText ? 0 : 14)
            .animation(.easeOut(duration: 0.9).delay(0.45), value: viewModel.showText)
            .padding(.trailing, 60)
    }

    var audioBlock: some View {
        HStack(spacing: 12) {
            Button {
                Haptic.selection()
                viewModel.toggleAudio()
            } label: {
                ZStack {
                    Circle().stroke(DraftTheme.secondary.opacity(0.35), lineWidth: 1).frame(width: 34, height: 34)
                    Image(systemName: viewModel.audioService.isPlaying ? "pause" : "play.fill")
                        .font(.system(size: 11, weight: .ultraLight))
                        .foregroundStyle(DraftTheme.secondary)
                        .offset(x: viewModel.audioService.isPlaying ? 0 : 1)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("VOICE NOTE").font(.system(size: 8, weight: .medium)).tracking(2).foregroundStyle(DraftTheme.secondary)
                Text(viewModel.audioService.formattedDuration)
                    .font(.system(size: 11, weight: .ultraLight, design: .monospaced))
                    .foregroundStyle(DraftTheme.text.opacity(0.38))
            }
        }
        .opacity(viewModel.showAudio ? 1 : 0)
        .offset(y: viewModel.showAudio ? 0 : 8)
        .animation(.easeOut(duration: 0.8).delay(0.65), value: viewModel.showAudio)
    }

    var dateStamp: some View {
        Text(viewModel.entry.formattedMonth.uppercased())
            .font(.system(size: 9, weight: .medium)).tracking(3)
            .foregroundStyle(DraftTheme.text.opacity(0.18))
            .padding(.top, 24)
            .opacity(viewModel.showText ? 1 : 0)
            .animation(.easeOut(duration: 1.0).delay(0.7), value: viewModel.showText)
    }

    var closeButton: some View {
        Button {
            Haptic.light()
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(DraftTheme.text.opacity(0.55))
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .padding(.top, 56).padding(.leading, 20)
    }
}
#Preview {
    MemoryDetailView(entry: MemoryEntry())
}
