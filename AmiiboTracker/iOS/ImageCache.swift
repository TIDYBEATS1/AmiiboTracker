//
//  ImageCache.swift
//  AmiiboTracker
//
//  Created by Sam Stanwell on 28/06/2025.
//


import SwiftUI

class ImageCache {
    static let shared = ImageCache()
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default

    private var cacheDirectory: URL {
        let dir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("AmiiboImageCache", isDirectory: true)
    }

    func image(for url: URL) -> UIImage? {
        let key = url.absoluteString as NSString
        if let memImage = memoryCache.object(forKey: key) {
            return memImage
        }

        let diskURL = cacheDirectory.appendingPathComponent(url.lastPathComponent)
        if let data = try? Data(contentsOf: diskURL),
           let image = UIImage(data: data) {
            memoryCache.setObject(image, forKey: key)
            return image
        }

        return nil
    }

    func store(_ image: UIImage, for url: URL) {
        let key = url.absoluteString as NSString
        memoryCache.setObject(image, forKey: key)

        let folder = cacheDirectory
        let fileURL = folder.appendingPathComponent(url.lastPathComponent)

        if !fileManager.fileExists(atPath: folder.path) {
            try? fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }

        if let data = image.pngData() {
            try? data.write(to: fileURL)
        }
    }
}
