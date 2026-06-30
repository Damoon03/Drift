//
//  Triangle.swift
//  Drift
//
//  Created by Damoon saber on 4/9/1405 AP.
//

import SwiftUI

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to:    CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            p.closeSubpath()
        }
    }
}
