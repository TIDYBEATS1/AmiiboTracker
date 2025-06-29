//
//  AmiiboService.swift
//  AmiiboTracker
//
//  Created by Sam Stanwell on 25/06/2025.
//

import Foundation
import SwiftUI

@MainActor
class AmiiboService: ObservableObject {
    @Published var allAmiibos: [Amiibo] = []
    @Published var groupedBySeries: [String: [Amiibo]] = [:]
    @Published var usageMap: [String: AmiiboGames] = [:]
    @Published var isLoading = true
    @Published var downloadProgress: Double = 0.0
    @Published var dataSource: String = ""
    @Published var isFirstBoot = false
    
    @Published var ownedAmiiboIDs: Set<String> = [] {
        didSet {
            saveOwnedAmiibos()
        }
    }
    @Published var allowImageCaching: Bool {
        didSet {
            UserDefaults.standard.set(allowImageCaching, forKey: "allowImageCaching")
        }
    }
    init() {
        allowImageCaching = UserDefaults.standard.bool(forKey: "allowImageCaching")
        loadOwnedAmiibos()
        loadUsageData()
    }
    
    func usageInfo(for amiibo: Amiibo) -> AmiiboGamePlatformUsage? {
        print("Checking usageMap for:", amiibo.id)
        return usageMap[amiibo.id]?.games
    }
    
    var cacheURL: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documents.appendingPathComponent("amiibo_cache.json")
    }
    
    func loadUsageData() {
        guard let url = Bundle.main.url(forResource: "games_info_compact", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode(GamesInfoCompact.self, from: data) else {
            print("❌ Failed to load or decode games_info_compact.json")
            return
        }
        
        self.usageMap = decoded.amiibos
    }
    
    func downloadInitialAssets() async {
        guard let url = URL(string: "https://www.amiiboapi.com/api/amiibo/") else { return }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(AmiiboResponse.self, from: data)
            
            let total = Double(decoded.amiibo.count)
            allAmiibos = decoded.amiibo
            groupedBySeries = Dictionary(grouping: decoded.amiibo, by: \.gameSeries)
            
            for (index, _) in decoded.amiibo.enumerated() {
                downloadProgress = Double(index + 1) / total
                try? await Task.sleep(nanoseconds: 1_000_000) // shorter delay
            }
            
            try? data.write(to: cacheURL)
            
            // ✅ Only after successful load
            UserDefaults.standard.set(true, forKey: "hasBooted")
            dataSource = "API"
        } catch {
            print("❌ Failed to download initial assets: \(error)")
        }
        
        isLoading = false
    }
    
    @MainActor
    func fetchAmiibos(force: Bool = false) async {
        guard !isLoading else {
            print("⚠️ Already loading, skipping fetch.")
            return
        }
        
        if !force && FileManager.default.fileExists(atPath: cacheURL.path),
           let cached = try? Data(contentsOf: cacheURL) {
            print("📦 Skipping API fetch, loading from cache")
            decodeAndStore(from: cached)
            return
        }
        guard !isLoading || force else {
            print("⚠️ Already loading, skipping fetch.")
            return
        }
        
        print("🟢 fetchAmiibos started")
        isLoading = true
        defer { isLoading = false }
        
        // ✅ Load from cache first
        if let cached = try? Data(contentsOf: cacheURL) {
            print("📦 Loaded from cache on first task")
            decodeAndStore(from: cached)
            dataSource = "Cache"
            return
        }
        
        // 🔁 Fallback to API if cache is missing
        await downloadInitialAssets()
    }
    
    @MainActor
    func decodeAndStore(from data: Data) {
        do {
            let decoded = try JSONDecoder().decode(AmiiboResponse.self, from: data)
            self.allAmiibos = decoded.amiibo
            self.groupedBySeries = Dictionary(grouping: decoded.amiibo, by: \.gameSeries)
            self.groupedBySeries["Owned"] = decoded.amiibo.filter { self.ownedAmiiboIDs.contains($0.id) }
            print("✅ Decoded and stored \(decoded.amiibo.count) amiibos")
        } catch {
            print("❌ Failed to decode Amiibos: \(error)")
        }
    }
    
    func toggleOwnership(for amiibo: Amiibo) {
        if ownedAmiiboIDs.contains(amiibo.id) {
            ownedAmiiboIDs.remove(amiibo.id)
        } else {
            ownedAmiiboIDs.insert(amiibo.id)
        }
    }
    
    func selectAll() {
        ownedAmiiboIDs = Set(allAmiibos.map { $0.id })
    }
    
    func deselectAll() {
        ownedAmiiboIDs.removeAll()
    }
    
    func clearCache() {
        do {
            if FileManager.default.fileExists(atPath: cacheURL.path) {
                try FileManager.default.removeItem(at: cacheURL)
                print("🗑️ Cache cleared.")
                dataSource = "None"
                UserDefaults.standard.set(false, forKey: "hasBooted")
                isFirstBoot = true
            }
        } catch {
            print("❌ Failed to clear cache: \(error)")
        }
    }
    
    private let ownedKey = "ownedAmiiboIDs"
    
    private func loadOwnedAmiibos() {
        if let data = UserDefaults.standard.data(forKey: ownedKey),
           let savedIDs = try? JSONDecoder().decode(Set<String>.self, from: data) {
            self.ownedAmiiboIDs = savedIDs
        }
    }
    
    private func saveOwnedAmiibos() {
        if let data = try? JSONEncoder().encode(ownedAmiiboIDs) {
            UserDefaults.standard.set(data, forKey: ownedKey)
        }
    }
    func loadAmiibosIfNeeded() async {
        guard !isLoading else {
            print("⚠️ Already loading, skipping fetch.")
            return
        }
        
        if allAmiibos.isEmpty {
            if FileManager.default.fileExists(atPath: cacheURL.path),
               let cached = try? Data(contentsOf: cacheURL) {
                decodeAndStore(from: cached)
                print("📦 Loaded from cache")
            } else {
                await fetchAmiibos(force: true)
                print("🌐 Fetched from API (fallback)")
            }
        } else {
            print("✅ Amiibos already loaded")
        }
    }
    
    @MainActor
    func loadFromCacheIfAvailable() {
        let path = cacheURL.path
        guard FileManager.default.fileExists(atPath: path),
              let cached = try? Data(contentsOf: cacheURL) else {
            print("❌ No cache file found at \(path)")
            return
        }
        
        decodeAndStore(from: cached)
        print("📦 Loaded from cache at \(path)")
    }
}
