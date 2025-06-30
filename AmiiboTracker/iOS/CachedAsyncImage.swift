//
//  CachedAsyncImage.swift
//  AmiiboTracker
//
//  Created by Sam Stanwell on 28/06/2025.
//

import SwiftUI

#if os(iOS)
import UIKit
typealias PlatformImage = UIImage
#elseif os(macOS)
import AppKit
#endif

struct CachedAsyncImage: View {
    let url: URL
    let width: CGFloat
    let height: CGFloat

    @State private var loadedImage: PlatformImage?

    var body: some View {
        Group {
            if let image = loadedImage {
                #if os(iOS)
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                #elseif os(macOS)
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                #endif
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
            loadedImage = cached
            return
        }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = PlatformImage(data: data) {
                    ImageCache.shared.store(image, for: url)
                    loadedImage = image
                }
            } catch {
                print("❌ Failed to load image: \(error)")
            }
        }
    }
}
