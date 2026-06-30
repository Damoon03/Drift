//  FilmGrainView.swift
//  Drift
//  Renders a static noise texture to simulate aged film grain.

import SwiftUI

struct FilmGrainView: UIViewRepresentable {

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear

        // CIFilter noise
        guard
            let filter = CIFilter(name: "CIRandomGenerator"),
            let noiseImage = filter.outputImage
        else { return view }

        let cropped = noiseImage.cropped(to: CGRect(x: 0, y: 0, width: 400, height: 400))
        let context = CIContext()
        guard let cgImage = context.createCGImage(cropped, from: cropped.extent) else { return view }

        let imageView = UIImageView(image: UIImage(cgImage: cgImage))
        imageView.contentMode = .scaleAspectFill
        imageView.alpha = 1
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(imageView)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
