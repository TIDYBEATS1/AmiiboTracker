import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var service: AmiiboService
    @State private var showDownloadAlert = false
    @State private var showClearAlert = false
    @State private var isDownloading = false
    @State private var downloadComplete = false
    @State private var enableOfflineMode = false
    @State private var darkMode = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @AppStorage("useDarkMode") private var useDarkMode: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("Settings")
                    .font(.largeTitle.bold())
                    .padding(.top, 12)

                // Progress Info
                HStack(spacing: 12) {
                    ProgressView(value: service.downloadProgress)
                        .frame(width: 120)
                    Text("\(service.ownedAmiiboIDs.count) / \($service.allAmiibos.count) Owned")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if downloadComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .transition(.scale)
                    }
                }

                // Toggles
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preferences")
                        .font(.headline)

                    Toggle("Offline Mode", isOn: $enableOfflineMode)
                    Toggle("Use Dark Mode", isOn: $useDarkMode)
                }

                Divider()

                // Collection Controls
                VStack(alignment: .leading, spacing: 8) {
                    Text("Collection")
                        .font(.headline)

                    HStack(spacing: 16) {
                        Button("Select All") {
                            service.selectAll()
                        }

                        Button("Deselect All") {
                            service.deselectAll()
                        }
                    }
                }

                Divider()

                // Data Management
                VStack(alignment: .leading, spacing: 8) {
                    Text("Data")
                        .font(.headline)

                    Button {
                        showDownloadAlert = true
                    } label: {
                        Label("Download Amiibo Data", systemImage: "arrow.down.circle")
                    }
                    .disabled(isDownloading)

                    Button(role: .destructive) {
                        showClearAlert = true
                    } label: {
                        Label("Clear Cache", systemImage: "trash")
                    }
                }

                Spacer(minLength: horizontalSizeClass == .compact ? 40 : 12)

                // Source Info
                HStack {
                    Text("Source: \(service.dataSource.isEmpty ? "Cache" : service.dataSource)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .alert("Download Amiibo Data?", isPresented: $showDownloadAlert) {
            Button("Download", role: .destructive) {
                Task {
                    withAnimation {
                        downloadComplete = false
                    }
                    isDownloading = true
                    await service.fetchAmiibos(force: true)
                    isDownloading = false
                    withAnimation(.spring()) {
                        downloadComplete = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will re-download and overwrite your cached Amiibo data.")
        }
        .alert("Clear Cache?", isPresented: $showClearAlert) {
            Button("Clear", role: .destructive) {
                service.clearCache()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete cached Amiibo data and require a new download.")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AmiiboService())
}
