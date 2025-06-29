//
//  AmiiboTrackerApp.swift
//  AmiiboTracker
//
//  Created by Sam Stanwell on 25/06/2025.
//

import SwiftUI

@main
struct AmiiboTrackerApp: App {
    @StateObject private var service = AmiiboService()
    @AppStorage("useDarkMode") private var useDarkMode: Bool = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(service)
                .preferredColorScheme(useDarkMode ? .dark : .light)

        }
    }
}
