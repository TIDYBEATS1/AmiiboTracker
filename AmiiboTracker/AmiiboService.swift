//
//  AmiiboService.swift
//  AmiiboTracker
//
//  Created by Sam Stanwell on 25/06/2025.
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

// ✅ Move ViewMode out of the class
enum ViewMode: String, CaseIterable, Identifiable {
    case list = "List"
    case grid = "Grid"
    case detail = "Cards" // 🛠 Rename to match your preview switch logic

    var id: String { rawValue }
}

@MainActor
class AmiiboService: ObservableObject {
    @Published var animalCrossingSubcategoryMap: [String: [String]] = [:]
    @Published var saveStatusMessage: String = ""
    @Published var showSaveStatus: Bool = false
    @State private var selectedSeries: String? = "All"
    @Published var allAmiibos: [Amiibo] = []
    @StateObject var service = AmiiboService() // ✅ GOOD
    @Published var groupedBySeries: [String: [Amiibo]] = [:]
    @Published var usageMap: [String: AmiiboGames] = [:]
    @Published var isLoading = true
    @Published var downloadProgress: Double = 0.0
    @Published var dataSource: String = ""
    @Published var isFirstBoot = false
    private var hasFetched = false
    @AppStorage("selectedViewMode") var selectedViewMode: ViewMode = .list

    @Published var ownedAmiiboIDs: Set<String> = [] {
        didSet {
            saveOwnedAmiibos()
            updateOwnedGroup()
        }
    }

    func updateOwnedGroup() {
        groupedBySeries["Owned"] = allAmiibos.filter { ownedAmiiboIDs.contains($0.id) }
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
        print("🔧 AmiiboService initialized")
        loadSubcategoriesFromJSON()

        }

    func usageInfo(for amiibo: Amiibo) -> AmiiboGamePlatformUsage? {
        print("Checking usageMap for:", amiibo.id)
        return usageMap[amiibo.id]?.games
    }

    var cacheURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("amiibo_cache.json")
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
    
    
    let animalCrossingSubcategories: [String] = [
        "Figures",
        "Series 1",
        "Series 2",
        "Series 3",
        "Series 4",
        "Series 5",
        "Promos",
        "New Leaf Welcome",
        "Sanrio"
    ]

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
                try? await Task.sleep(nanoseconds: 1_000_000)
            }

            try? data.write(to: cacheURL)

            UserDefaults.standard.set(true, forKey: "hasBooted")
            dataSource = "API"
        } catch {
            print("❌ Failed to download initial assets: \(error)")
        }

        isLoading = false
    }
    func amiibos(forSubcategory subcategory: String) -> [Amiibo] {
        guard let ids = animalCrossingSubcategoryMap[subcategory] else { return [] }
        return allAmiibos.filter { ids.contains($0.id) }
    }
    @MainActor
    func fetchAmiibos(force: Bool = false) async {
        guard force || !hasFetched else {
            print("Source3: \(service.dataSource)")
            print("🛑 Already fetched, skipping.")
            return
        }

        guard !isLoading || force else {

            print("⚠️ Already loading, skipping fetch.")
            return
        }

        print("📣 Called fetchAmiibos(force: \(force)), isLoading: \(isLoading)")

        isLoading = true
        defer {
            isLoading = false
            hasFetched = true
        }

        // ✅ 1. Try cache
        if !force,
           FileManager.default.fileExists(atPath: cacheURL.path),
           let cached = try? Data(contentsOf: cacheURL) {
            print("📦 Loaded from cache at: \(cacheURL.path)")
            print("📦 Cache size: \(cached.count) bytes")
            decodeAndStore(from: cached)
            dataSource = "Cache"
            return
        }

        // ✅ 2. Fetch from API
        print("🌐 No cache, fetching from API...")
        do {
            let url = URL(string: "https://www.amiiboapi.com/api/amiibo/")!
            let (data, _) = try await URLSession.shared.data(from: url)
            print("Source: \(service.dataSource)")

            try data.write(to: cacheURL)
            print("💾 Cache saved to: \(cacheURL.path)")
            print("Source2: \(service.dataSource)")

            decodeAndStore(from: data)
            dataSource = "API"
        } catch {
            print("❌ Failed to fetch or save: \(error)")
        }
    }

    @MainActor
    func decodeAndStore(from data: Data) {
        do {
            let decoded = try JSONDecoder().decode(AmiiboResponse.self, from: data)
            self.allAmiibos = decoded.amiibo
            self.groupedBySeries = Dictionary(grouping: decoded.amiibo, by: \.gameSeries)
            self.groupedBySeries["Owned"] = decoded.amiibo.filter {
                self.ownedAmiiboIDs.contains($0.id) }
                self.updateOwnedGroup() // ✅ Add this line
            print("✅ Decoded and stored \(decoded.amiibo.count) amiibos")
        } catch {
            print("❌ Failed to decode Amiibos: \(error)")
        }
    }
    func waitForAmiibos() async {
        while allAmiibos.isEmpty {
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
    }
    func toggleOwnership(for amiibo: Amiibo) {
        if ownedAmiiboIDs.contains(amiibo.id) {
            ownedAmiiboIDs.remove(amiibo.id)
        } else {
            ownedAmiiboIDs.insert(amiibo.id)
        }
    }

    func selectAll(from list: [Amiibo]) {
        let ids = list.map { $0.id }
        ownedAmiiboIDs.formUnion(ids)
        updateOwnedGroup()
        print("🔘 Selected \(ids.count) Amiibos")
    }
    func deselectAll(from list: [Amiibo]) {
        let ids = list.map { $0.id }
        ownedAmiiboIDs.subtract(ids)
        updateOwnedGroup()
        print("🔘 Deselected \(ids.count) Amiibos")
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
    func subgroupedByType(for series: String) -> [String: [Amiibo]] {
        let filtered = groupedBySeries[series] ?? []
        return Dictionary(grouping: filtered, by: \.type)
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
    func loadSubcategoriesFromJSON() {
        guard let url = Bundle.main.url(forResource: "AnimalCrossingSubcategories", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: [String]].self, from: data) else {
            print("❌ Failed to load AnimalCrossingSubcategories.json")
            return
        }

        self.animalCrossingSubcategoryMap = decoded
        print("✅ Loaded subcategories: \(decoded.keys.joined(separator: ", "))")
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

extension AmiiboService {
    func saveOwnedAmiibos(for uid: String) {
        let db = Firestore.firestore()
        let ownedIDs = Array(ownedAmiiboIDs) // assuming ownedAmiiboIDs is a Set or Array of IDs
        
        db.collection("users").document(uid).setData(["owned": ownedIDs]) { error in
            if let error = error {
                print("❌ Failed to save owned Amiibos: \(error.localizedDescription)")
            } else {
                print("✅ Owned Amiibos saved successfully")
            }
        }
    }
    func loadOwnedAmiibos(for uid: String) {
        let db = Firestore.firestore()
        let userDoc = db.collection("users").document(uid)
        
        userDoc.getDocument { [weak self] snapshot, error in
            if let error = error {
                print("❌ Failed to load owned Amiibos from Firestore: \(error.localizedDescription)")
                // Fallback to cache if Firestore fails
                self?.loadFromCacheIfAvailable()
                return
            }
            
            guard let data = snapshot?.data(),
                  let ownedIDs = data["owned"] as? [String] else {
                print("⚠️ No owned Amiibos found in Firestore, loading cache...")
                self?.loadFromCacheIfAvailable()
                return
            }
            
            DispatchQueue.main.async {
                self?.ownedAmiiboIDs = Set(ownedIDs)
                print("✅ Loaded owned Amiibos from Firestore")
            }
        }
    }
}
