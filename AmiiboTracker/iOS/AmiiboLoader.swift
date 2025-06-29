import Foundation
import SwiftUI

#if os(iOS)

extension AmiiboService {
    
    @MainActor
    func loadAmiibosForiOS() async {
        print("📱 [iOS] Starting loadAmiibosForiOS()")

        let path = cacheURL.path
        print("📁 Checking for cache at: \(path)")

        guard FileManager.default.fileExists(atPath: path) else {
            print("❌ Cache file does not exist — fetching from API")
            await fetchAmiibos_iOS(force: true)
            return
        }

        do {
            let cached = try Data(contentsOf: cacheURL)
            print("📦 Read cached data: \(cached.count) bytes")

            let decoded = try JSONDecoder().decode(AmiiboResponse.self, from: cached)
            self.allAmiibos = decoded.amiibo
            self.groupedBySeries = Dictionary(grouping: decoded.amiibo, by: \.gameSeries)
            self.groupedBySeries["Owned"] = decoded.amiibo.filter { self.ownedAmiiboIDs.contains($0.id) }

            print("✅ Loaded \(decoded.amiibo.count) Amiibos from cache")
            dataSource = "Cache"
        } catch {
            print("❌ Failed to load cache: \(error)")
            await fetchAmiibos_iOS(force: true)
        }
    }
    
    func fetchAmiibos_iOS(force: Bool = false) async {
        print("🌍 [iOS] Starting fetchAmiibos_iOS")
        
        do {
            let url = URL(string: "https://www.amiiboapi.com/api/amiibo/")!
            let (data, _) = try await URLSession.shared.data(from: url)
            print("📦 [iOS] Got data: \(data.count) bytes")
            
            let decoded = try JSONDecoder().decode(AmiiboResponse.self, from: data)
            self.allAmiibos = decoded.amiibo
            self.groupedBySeries = Dictionary(grouping: decoded.amiibo, by: \.gameSeries)
            self.groupedBySeries["Owned"] = decoded.amiibo.filter { self.ownedAmiiboIDs.contains($0.id) }
            print("✅ [iOS] Decoded \(decoded.amiibo.count) Amiibos")
            for amiibo in decoded.amiibo {
                if let imageURL = URL(string: amiibo.image),
                   ImageCache.shared.image(for: imageURL) == nil {
                    Task.detached {
                        do {
                            let (data, _) = try await URLSession.shared.data(from: imageURL)
                            if let image = UIImage(data: data) {
                                ImageCache.shared.store(image, for: imageURL)
                                print("📥 Cached image for: \(amiibo.name)")
                            }
                        } catch {
                            print("❌ Failed to cache image for \(amiibo.name): \(error)")
                        }
                    }
                }
            }
            try data.write(to: cacheURL)
            print("💾 Wrote cache to: \(cacheURL.path)")
        } catch {
            print("❌ Failed to write cache: \(error)")
            
        }
        
    }
}
extension UserDefaults {
    func contains(key: String) -> Bool {
        return object(forKey: key) != nil
    }
}
#endif
