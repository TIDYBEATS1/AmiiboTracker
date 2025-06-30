import SwiftUI
import Foundation
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var service: AmiiboService
    @EnvironmentObject var authManager: AuthManager
    @AppStorage("useDarkMode") private var useDarkMode: Bool = false

    @State private var showDownloadAlert = false
    @State private var showClearAlert = false
    @State private var isDownloading = false
    @State private var downloadComplete = false
    @State private var enableOfflineMode = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    let filteredAmiibos: [Amiibo]
    let selectAllAction: () -> Void
    let deselectAllAction: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Settings")
                    .font(.largeTitle.bold())
                    .padding(.top, 12)

                HStack(spacing: 12) {
                    ProgressView(value: service.downloadProgress)
                        .frame(width: 120)

                    Text(ownedCountText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if downloadComplete {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .transition(.scale)
                    }
                }

                // MARK: - Preferences
                VStack(alignment: .leading, spacing: 12) {
                    Text("Preferences")
                        .font(.headline)

                    Toggle("Offline Mode", isOn: $enableOfflineMode)
                    Toggle("Use Dark Mode", isOn: $useDarkMode)
                }

                Divider()

                // MARK: - Collection Management
                VStack(alignment: .leading, spacing: 8) {
                    Text("Collection")
                        .font(.headline)

                    HStack(spacing: 16) {
                        Button("Select All") {
                            service.selectAll(from: filteredAmiibos)
                            if let uid = Auth.auth().currentUser?.uid {
                                service.saveOwnedAmiibos(for: uid)
                            }
                        }

                        Button("Deselect All") {
                            service.deselectAll(from: filteredAmiibos)
                            if let uid = Auth.auth().currentUser?.uid {
                                service.saveOwnedAmiibos(for: uid)
                            }
                        }
                        Button("DEBUG: Print owned") {
                            print("🧾 Owned IDs: \(service.ownedAmiiboIDs.count)")
                        }
                    }
                    .padding(.vertical, 8)

                    if !service.ownedAmiiboIDs.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(service.allAmiibos.filter { service.ownedAmiiboIDs.contains($0.id) }) { amiibo in
                                    VStack {
                                        AsyncImage(url: URL(string: amiibo.image)) { phase in
                                            if let image = phase.image {
                                                image
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                            } else {
                                                Color.gray.opacity(0.2)
                                            }
                                        }
                                        .frame(width: 60, height: 60)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))

                                        Text(amiibo.name)
                                            .font(.caption2)
                                            .lineLimit(1)
                                    }
                                }
                            }
                        }
                        .frame(height: 80)
                        .padding(.top, 8)
                    }
                }

                Divider()

                // MARK: - Data Actions
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

                Divider()

                // MARK: - Login Section
                // ✅ Login Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Login")
                        .font(.headline)

                    if authManager.loggedIn {
                        HStack {
                            Label("Signed in as", systemImage: "person.crop.circle")
                            Spacer()
                            Text(authManager.user?.email ?? "Unknown")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Button(role: .destructive) {
                            authManager.logout()
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } else {
                        Button {
                            NotificationCenter.default.post(name: .showLogin, object: nil)
                        } label: {
                            Label("Sign In", systemImage: "person.crop.circle.badge.plus")
                        }
                    }
                }

                // MARK: - Data Source Footer
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
        .onAppear {
            print("👀 SettingsView appeared")
            if service.allAmiibos.isEmpty {
                print("📱 [SettingsView] Forcing load from cache")
                service.loadFromCacheIfAvailable()
            }
        }
        .alert("Download Amiibo Data?", isPresented: $showDownloadAlert) {
            Button("Download", role: .destructive) {
                Task {
                    withAnimation { downloadComplete = false }
                    isDownloading = true
                    await service.fetchAmiibos(force: true)
                    isDownloading = false
                    withAnimation(.spring()) { downloadComplete = true }
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

    // MARK: - Helpers
    private var currentUserEmail: String {
        authManager.user?.email ?? "Unknown"
    }
    
    private var ownedCountText: String {
        let owned = service.ownedAmiiboIDs.count
        let total = service.allAmiibos.count
        return "\(owned) / \(total) Owned"
    }
}
