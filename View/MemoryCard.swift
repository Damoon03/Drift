//  MemoryCard.swift
//  Drift

import SwiftUI

struct MemoryCard: View {

    let entry: MemoryEntry

    private var uiImage: UIImage? {
        guard let data = entry.imageData else { return nil }
        return UIImage(data: data)
    }

    /// Very wide source images (e.g. desktop wallpapers) get aggressively
    /// cropped by scaledToFill, often losing the left-side area the text
    /// overlay depends on. Past this ratio we letterbox instead of crop.
    private var isExtremeLandscape: Bool {
        guard let img = uiImage, img.size.height > 0 else { return false }
        return (img.size.width / img.size.height) > 2.0
    }

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                Divider().overlay(DraftTheme.divider)

                ZStack(alignment: .leading) {

                    // Guaranteed dark base so text stays legible no matter
                    // what the underlying photo's content looks like.
                    DraftTheme.surface

                    // Base image or placeholder
                    Group {
                        if let ui = uiImage {
                            if isExtremeLandscape {
                                Image(uiImage: ui)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: proxy.size.width)
                            } else {
                                Image(uiImage: ui)
                                    .resizable()
                                    .scaledToFill()
                            }
                        } else {
                            Rectangle().fill(DraftTheme.surface)
                        }
                    }
                    .frame(width: proxy.size.width, height: 210)
                    .clipped()
                    // Aged film effect: desaturate + warm tone overlay
                    .saturation(0.25)
                    .contrast(0.88)
                    .brightness(-0.04)
                    .overlay {
                        // Warm sepia wash
                        Rectangle()
                            .fill(Color(hex: "#3D2000").opacity(0.28))
                            .blendMode(.multiply)
                    }
                    // Dark left gradient for text legibility
                    .overlay {
                        LinearGradient(
                            stops: [
                                .init(color: Color.black.opacity(0.82), location: 0.0),
                                .init(color: Color.black.opacity(0.60), location: 0.35),
                                .init(color: Color.black.opacity(0.20), location: 0.65),
                                .init(color: Color.clear,               location: 1.0),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    }
                    // Subtle film grain via noise pattern
                    .overlay {
                        FilmGrainView()
                            .opacity(0.06)
                            .blendMode(.overlay)
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        topMeta
                        Text(entry.text.isEmpty ? "—" : entry.text)
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(DraftTheme.text.opacity(0.88))
                            .frame(maxWidth: proxy.size.width - 56, alignment: .leading)
                            .lineLimit(3)
                        bottomMeta
                    }
                    .padding(.horizontal, 28)
                }
                .frame(width: proxy.size.width, height: 210)
                .clipped()

                Divider().overlay(DraftTheme.divider)
            }
            .contentShape(Rectangle())
        }
        .frame(height: 211) // 210 image + ~1pt for dividers collapsing in GeometryReader's flexible height
    }
}

private extension MemoryCard {

    var topMeta: some View {
        HStack(spacing: 10) {
            Text(entry.formattedTime)
            Circle().frame(width: 3, height: 3)
            Text(entry.locationName.isEmpty ? "UNKNOWN" : entry.locationName.uppercased())
        }
        .font(.system(size: 10, weight: .medium))
        .tracking(2)
        .foregroundStyle(DraftTheme.secondary)
    }

    var bottomMeta: some View {
        HStack(spacing: 10) {
            Text(entry.season.isEmpty ? "—" : entry.season)
            Circle().frame(width: 3, height: 3)
            Text(entry.temperature.isEmpty ? "—" : entry.temperature)
        }
        .font(.system(size: 10, weight: .light))
        .tracking(2)
        .foregroundStyle(DraftTheme.text.opacity(0.45))
    }
}
