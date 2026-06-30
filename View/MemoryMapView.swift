//  MemoryMapView.swift
//  Drift

import SwiftUI
import MapKit

struct MemoryMapView: View {

    @StateObject private var viewModel: MemoryMapViewModel
    @Environment(\.dismiss) private var dismiss

    init(entries: [MemoryEntry]) {
        _viewModel = StateObject(wrappedValue: MemoryMapViewModel(entries: entries))
    }

    var body: some View {
        ZStack(alignment: .top) {
            Map(coordinateRegion: $viewModel.region, annotationItems: viewModel.mappable) { entry in
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: entry.latitude!, longitude: entry.longitude!
                )) {
                    pinView(entry: entry)
                }
            }
            .ignoresSafeArea()
            .colorScheme(.dark)
            .saturation(0.3)

            topBar

            VStack {
                Spacer()
                if let entry = viewModel.selectedEntry {
                    mapPreviewCard(entry: entry)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 52)
                }
            }
            .animation(.spring(response: 0.38, dampingFraction: 0.82), value: viewModel.selectedEntry?.id)
        }
        .onAppear { viewModel.onAppear() }
    }
}

private extension MemoryMapView {

    var topBar: some View {
        HStack {
            Button {
                Haptic.light()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(DraftTheme.text.opacity(0.7))
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            Spacer()
            Text("MAP")
                .font(.system(size: 11, weight: .medium)).tracking(4)
                .foregroundStyle(DraftTheme.secondary)
            Spacer()
            Text("\(viewModel.mappable.count)")
                .font(.system(size: 11, weight: .ultraLight, design: .monospaced))
                .foregroundStyle(DraftTheme.text.opacity(0.3))
                .frame(width: 44)
        }
        .padding(.horizontal, 20).padding(.top, 56)
    }

    func pinView(entry: MemoryEntry) -> some View {
        let isSelected = viewModel.selectedEntry?.id == entry.id
        return Button {
            Haptic.selection()
            viewModel.selectPin(entry)
        } label: {
            VStack(spacing: 0) {
                ZStack {
                    Circle().fill(DraftTheme.background.opacity(0.7)).frame(width: 36, height: 36)
                    if let data = entry.imageData, let ui = UIImage(data: data) {
                        Image(uiImage: ui).resizable().scaledToFill()
                            .frame(width: 28, height: 28).clipShape(Circle()).saturation(0.3)
                    } else {
                        Circle().fill(DraftTheme.secondary).frame(width: 10, height: 10)
                    }
                    Circle()
                        .stroke(isSelected ? DraftTheme.secondary : DraftTheme.secondary.opacity(0.4),
                                lineWidth: isSelected ? 1.5 : 1)
                        .frame(width: 36, height: 36)
                }
                Triangle()
                    .fill(isSelected ? DraftTheme.secondary : DraftTheme.secondary.opacity(0.5))
                    .frame(width: 6, height: 5).offset(y: -1)
            }
            .scaleEffect(isSelected ? 1.15 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
    }

    func mapPreviewCard(entry: MemoryEntry) -> some View {
        HStack(spacing: 16) {
            if let data = entry.imageData, let ui = UIImage(data: data) {
                Image(uiImage: ui).resizable().scaledToFill()
                    .frame(width: 56, height: 56).clipShape(RoundedRectangle(cornerRadius: 8)).saturation(0.3)
            } else {
                RoundedRectangle(cornerRadius: 8).fill(DraftTheme.surface).frame(width: 56, height: 56)
                    .overlay { Image(systemName: "photo").foregroundStyle(DraftTheme.secondary.opacity(0.3)) }
            }
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(entry.formattedTime)
                    Circle().frame(width: 3, height: 3)
                    Text(entry.locationName.uppercased())
                }
                .font(.system(size: 10, weight: .medium)).tracking(2).foregroundStyle(DraftTheme.secondary)
                Text(entry.text)
                    .font(.system(size: 13, weight: .light)).foregroundStyle(DraftTheme.text.opacity(0.78)).lineLimit(2)
            }
            Spacer()
            Button { viewModel.dismissCard() } label: {
                Image(systemName: "xmark").font(.system(size: 11)).foregroundStyle(DraftTheme.text.opacity(0.25)).frame(width: 28, height: 28)
            }
        }
        .padding(18)
        .background(Color(hex: "#0E0E0E"))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.07), lineWidth: 1))
        .padding(.horizontal, 20)
    }
}
