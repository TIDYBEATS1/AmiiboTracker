//
//  CachedAsyncImage.swift
//  AmiiboTracker
//
//  Created by Sam Stanwell on 28/06/2025.
//


import SwiftUI

struct CachedAsyncImage: View {
    let url: URL
    let width: CGFloat
    let height: CGFloat

    @State private var uiImage: UIImage?

    var body: some View {
        Group {
            if let image = uiImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Color.gray.opacity(0.2)
                    .onAppear(perform: load)
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func load() {
        if let cached = ImageCache.shared.image(for: url) {
            uiImage = cached
            return
        }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    ImageCache.shared.store(image, for: url)
                    uiImage = image
                }
            } catch {
                print("❌ Failed to load image: \(error)")
            }
        }
    }
}