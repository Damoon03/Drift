//
//  SwipeToDelete.swift
//  Drift
//
//  Created by Damoon saber on 4/9/1405 AP.
//

import SwiftUI

struct SwipeToDeleteRow<Content: View>: View {

    let onDelete: () -> Void
    @ViewBuilder let content: Content

    @State private var offsetX: CGFloat = 0
    @State private var triggeredHaptic = false

    private let revealThreshold: CGFloat = -88
    private let deleteThreshold: CGFloat = -160

    var body: some View {
        ZStack(alignment: .trailing) {
            // Background delete affordance, revealed as you drag
            HStack {
                Spacer()
                Image(systemName: "trash")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(DraftTheme.text.opacity(0.7))
                    .padding(.trailing, 28)
                    .opacity(offsetX < -20 ? 1 : 0)
            }
            .background(Color.red.opacity(offsetX < -20 ? 0.55 : 0))

            content
                .offset(x: offsetX)
                .gesture(
                    DragGesture(minimumDistance: 12)
                        .onChanged { value in
                            // Only allow leftward swipe
                            let translation = min(0, value.translation.width)
                            offsetX = translation

                            if translation < deleteThreshold && !triggeredHaptic {
                                Haptic.medium()
                                triggeredHaptic = true
                            } else if translation > deleteThreshold {
                                triggeredHaptic = false
                            }
                        }
                        .onEnded { value in
                            let translation = min(0, value.translation.width)
                            if translation < deleteThreshold {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    offsetX = -500
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    onDelete()
                                }
                            } else {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    offsetX = 0
                                }
                                triggeredHaptic = false
                            }
                        }
                )
        }
        .clipped()
    }
}
