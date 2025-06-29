//  ContentView.swift
//  AmiiboTracker

import SwiftUI

struct ContentView: View {
    @StateObject private var service = AmiiboService()
    @State private var selectedSeries: String? = "All"
    @State private var searchText = ""
    @State private var showDetail = false
    @State private var detailAmiibo: Amiibo? = nil
    @State private var selectedScope: SearchScope = .all
    @State private var selectedViewMode: ViewMode = .list
    @State private var didLoad = false
#if os(iOS)

    @State private var showCachePrompt = false
#endif

    enum SearchScope: String, CaseIterable, Identifiable {
        case all = "All"
        case owned = "Owned"
        case series = "Series"
        var id: String { rawValue }
    }

    enum ViewMode: String, CaseIterable, Identifiable {
        case list = "List"
        case grid = "Grid"
        case detailed = "Detailed"
        var id: String { rawValue }
    }

    var body: some View {
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
                                await service.fetchAmiibos()
                                print("🌐 Fetched from API")
                            }
                        }
                    }
            }
        }
#elseif os(iOS)
        NavigationSplitView {
            sidebar
        } detail: {
            NavigationStack {
                contentStack
                    .onAppear {
                        #if os(iOS)
                        guard !didLoad else { return }
                        didLoad = true
                        print("📲 iOS onAppear")

                        Task {
                            await service.loadAmiibosForiOS()
                        }
                        #endif
                    }
            }
        }
#else
        NavigationStack {
            contentStack
        }
#endif
    }
 

    private var sidebar: some View {
        List(selection: $selectedSeries) {
            Section(header: Text("View Options")) {
                Text("All").tag("All")
                Label("Owned", systemImage: "person.crop.circle.fill").tag("Owned")
            }

            Section(header: Text("Series")) {
                ForEach(service.groupedBySeries.keys.sorted(), id: \.self) { series in
                    if series != "Owned" && series != "All" {
                        Label(series, systemImage: "books.vertical").tag(series)
                    }
                }
            }
        }
        .navigationTitle("AmiiboTracker")
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
                switch selectedViewMode {
                case .list:
                    List {
                        ForEach(amiibos) { amiibo in
                            HStack {
                                AmiiboRowView(
                                    amiibo: amiibo,
                                    isOwned: service.ownedAmiiboIDs.contains(amiibo.id),
                                    toggleAction: { service.toggleOwnership(for: amiibo) }
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
                    }
                    
                case .detailed:
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
                        }
                    }
                }
            }
        }
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
            ToolbarItem(placement: .automatic) {
                Picker("View", selection: $selectedViewMode) {
                    ForEach(ViewMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            ToolbarItem(placement: .primaryAction) {
                NavigationLink(destination: SettingsView().environmentObject(service)) {
                    Image(systemName: "gearshape")
                }
            }
        }
    }

    private var filteredAmiibos: [Amiibo] {
        let baseList: [Amiibo]

        switch selectedSeries {
        case "Owned":
            baseList = service.allAmiibos.filter { service.ownedAmiiboIDs.contains($0.id) }
        case "All", nil:
            baseList = service.allAmiibos
        default:
            baseList = service.groupedBySeries[selectedSeries ?? ""] ?? []
        }

        if searchText.isEmpty {
            return baseList
        }

        return baseList.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.character.localizedCaseInsensitiveContains(searchText) ||
            $0.gameSeries.localizedCaseInsensitiveContains(searchText)
        }
    }

    private func progressText(for series: String) -> String {
        let amiibos = service.groupedBySeries[series] ?? []
        let owned = amiibos.filter { service.ownedAmiiboIDs.contains($0.id) }.count
        return "\(owned) / \(amiibos.count)"
    }
}

#Preview {
    ContentView()
        .environmentObject(AmiiboService())
}
