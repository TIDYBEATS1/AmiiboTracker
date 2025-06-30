//  ContentView.swift
//  AmiiboTracker

import SwiftUI
import Foundation
import FirebaseAuth
#if os(iOS)
import UIKit
#endif
struct ContentView: View {
    @State private var selectedSeries: String? = "All"
    @State private var searchText = ""
    @State private var showDetail = false
    @State private var detailAmiibo: Amiibo? = nil
    @State private var selectedScope: SearchScope = .all
    @State private var refreshKey = UUID()
    @State private var selectedSubcategory: String? = nil
    @State private var didLoad = false
    @State private var sortMode: AmiiboSortMode = .alphabetical
    @EnvironmentObject var service: AmiiboService
    @StateObject var authManager = AuthManager()
    private var toastPosition: CGPoint {
        #if os(iOS)
        return CGPoint(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height - 100)
        #elseif os(macOS)
        return CGPoint(x: 500, y: 100) // Adjust to desired location on macOS
        #else
        return CGPoint(x: 500, y: 100)
        #endif
    }
#if os(iOS)
    @State private var showCachePrompt = false
#endif
    enum AmiiboSortMode: String, CaseIterable, Identifiable {
        case series = "Series"
        case alphabetical = "A–Z"
        case owned = "Owned"
        
        var id: String { rawValue }
    }
    enum SearchScope: String, CaseIterable, Identifiable {
        case all = "All"
        case owned = "Owned"
        case series = "Series"
        var id: String { rawValue }
    }
    
    var body: some View {
        ZStack {
            #if os(macOS)
            NavigationSplitView {
                sidebar
            } detail: {
                NavigationStack {
                    contentStack
                        .task {
                            if service.allAmiibos.isEmpty {
                                if FileManager.default.fileExists(atPath: service.cacheURL.path),
                                   let cached = try? Data(contentsOf: service.cacheURL) {
                                    service.decodeAndStore(from: cached)
                                    print("📦 Loaded from cache on first task")
                                } else {
                                    await service.fetchAmiibos(force: true)
                                    print("🌐 Fetched from API")
                                }
                            }
                        }
                }
            }
            .transition(.opacity)
            .zIndex(1)
            
            #elseif os(iOS)
            NavigationSplitView {
                sidebar
            } detail: {
                NavigationStack {
                    contentStack
                        .onAppear {
                            guard !didLoad else { return }
                            didLoad = true
                            print("📲 iOS onAppear")

                            Task {
                                await service.loadAmiibosForiOS()
                            }
                        }
                }
            }
            
            #else
            NavigationStack {
                contentStack
            }
            #endif

            // Toast overlay
            if service.showSaveStatus {
                Text(service.saveStatusMessage)
                    .padding()
                    .background(.regularMaterial)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut, value: service.showSaveStatus)
                    .zIndex(10)
                    .position(toastPosition)
            }
        }
    }
    
    private var sidebar: some View {
        List(selection: $selectedSeries) {
            // MARK: - View Options
                Section(header: Text("View Options")) {
                    Text("All").tag("All")
                    Label("Owned", systemImage: "person.crop.circle.fill").tag("Owned")

                
                NavigationLink(
                    destination: SettingsView(
                        filteredAmiibos: filteredAmiibos,
                        selectAllAction: { service.selectAll(from: filteredAmiibos) },
                        deselectAllAction: { service.deselectAll(from: filteredAmiibos) }
                    )
                ) {
                    Label("Settings", systemImage: "gear")
                }
            }
            
            // MARK: - Series Section
            Section(header: Text("Series")) {
                ForEach(service.groupedBySeries.keys
                    .filter { $0 != "Owned" }
                    .sorted(), id: \.self) { series in
                    if series == "Animal Crossing" {
                        DisclosureGroup {
                            // Show subcategories dynamically
                            ForEach(service.animalCrossingSubcategoryMap.keys.sorted(), id: \.self) { sub in
                                Text(sub).tag("Animal Crossing - \(sub)")
                            }
                        } label: {
                            Label("Animal Crossing", systemImage: "leaf.fill").tag(series)
                        }
                    } else {
                        Label(series, systemImage: "books.vertical").tag(series)
                    }
                }
            }
        }
    }
    
    
    private var contentStack: some View {
        let amiibos = filteredAmiibos
        let total = service.allAmiibos.count
        let owned = service.ownedAmiiboIDs.count
        let progressFraction = total > 0 ? Double(owned) / Double(total) : 0
        
        return Group {
            if amiibos.isEmpty {
                VStack {
                    Spacer()
                    Text("No Amiibo to display")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                switch service.selectedViewMode {
                case .list:
                    List {
                        ForEach(amiibos) { amiibo in
                            HStack {
                                AmiiboRowView(
                                    amiibo: amiibo,
                                    isOwned: service.ownedAmiiboIDs.contains(amiibo.id),
                                    toggleAction: {
                                        service.toggleOwnership(for: amiibo)
                                        if let uid = Auth.auth().currentUser?.uid {
                                            service.saveOwnedAmiibos(for: uid)  // Save to Firebase after toggle
                                        }
                                    }
                                )   
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        detailAmiibo = amiibo
                                        showDetail = true
                                    }) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.blue)
                                    }
                                        .buttonStyle(.plain)
                            }
                            .contentShape(Rectangle())
                        }
                    }
                case .grid:
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 16)], spacing: 16) {
                            ForEach(amiibos) { amiibo in
                                AmiiboGridItemView(
                                    amiibo: amiibo,
                                    isOwned: service.ownedAmiiboIDs.contains(amiibo.id),
                                    onTap: {
                                        detailAmiibo = amiibo
                                        showDetail = true
                                    }
                                )
                                .frame(width: 100)
                            }
                        }
                        .padding()
                        .onChange(of: service.selectedViewMode) { _ in refreshKey = UUID() }
                        .onChange(of: selectedSeries) { _ in refreshKey = UUID() }
                        .onChange(of: service.ownedAmiiboIDs) { _ in refreshKey = UUID() } // ✅ added
                    }
                    
                case .detail:
                    List {
                        ForEach(amiibos) { amiibo in
                            VStack(alignment: .leading) {
                                Text(amiibo.name).font(.headline)
                                Text("Series: \(amiibo.gameSeries)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Character: \(amiibo.character)")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                Text("Loaded Amiibos: \(service.allAmiibos.count)")
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 4)
                            .onTapGesture {
                                detailAmiibo = amiibo
                                showDetail = true
                            }
                            .onChange(of: service.selectedViewMode) { _ in refreshKey = UUID() }
                            .onChange(of: selectedSeries) { _ in refreshKey = UUID() }
                            .onChange(of: service.ownedAmiiboIDs) { _ in refreshKey = UUID() } // ✅ added
                        }
                    }
                }
            }
        }
        .id(refreshKey) // ✅ force refresh
        .navigationDestination(isPresented: $showDetail) {
            if let detailAmiibo {
                AmiiboDetailView(amiibo: detailAmiibo)
                    .environmentObject(service)
            }
        }
        .searchable(text: $searchText, prompt: "Search Amiibo")
        .searchScopes($selectedScope) {
            ForEach(SearchScope.allCases) { scope in
                Text(scope.rawValue).tag(scope)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                HStack(spacing: 12) {
                    Text("\(owned) / \(total)")
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: progressFraction)
                        .frame(width: 100)
                }
            }
        }
    }
    private func matchScore(for value: String, query: String) -> Int {
        if value == query {
            return 3 // exact match
        } else if value.hasPrefix(query) {
            return 2 // starts with
        } else if value.contains(query) {
            return 1 // contains somewhere
        } else {
            return 0 // no match
        }
    }
    private var filteredAmiibos: [Amiibo] {
        var baseList: [Amiibo]
        
        // 🌿 Handle Animal Crossing subcategory selection
        if let selected = selectedSeries, selected.starts(with: "Animal Crossing - ") {
            let subcategory = selected.replacingOccurrences(of: "Animal Crossing - ", with: "")
            if let ids = animalCrossingSubcategoryMap[subcategory] {
                baseList = service.allAmiibos.filter { ids.contains($0.id) }
            } else {
                baseList = []
            }
        } else if let selected = selectedSeries {
            switch selected {
            case "All":
                baseList = service.allAmiibos
            default:
                baseList = service.groupedBySeries[selected] ?? []
            }
        } else {
            baseList = service.allAmiibos
        }
        
        // 🔍 Apply search filter if needed
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            
            return baseList.sorted { a, b in
                let aScore = matchScore(for: a.name.lowercased(), query: query)
                let bScore = matchScore(for: b.name.lowercased(), query: query)
                
                if aScore != bScore {
                    return aScore > bScore
                } else {
                    return a.name < b.name
                }
            }
        } else {
            // 🧠 Sorting mode (when NOT searching)
            switch sortMode {
            case .alphabetical:
                return baseList.sorted { $0.name < $1.name }
            case .owned:
                return baseList.filter { service.ownedAmiiboIDs.contains($0.id) }
                    .sorted { $0.name < $1.name }
            case .series:
                return baseList // already grouped
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AmiiboService())
}
