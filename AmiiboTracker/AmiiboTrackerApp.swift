import SwiftUI
import Firebase

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@main
struct AmiiboTrackerApp: App {


    @StateObject private var service = AmiiboService()
    @StateObject private var authManager = AuthManager()
    @StateObject private var appState = AppState()
    @AppStorage("useDarkMode") private var useDarkMode: Bool = false

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(service)
                .environmentObject(appState)
                .preferredColorScheme(useDarkMode ? .dark : .light)
        }
    }
}
