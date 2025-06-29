// ThemeSettings.swift
// AmiiboTracker

import SwiftUI

enum ColorSchemePreference: String, CaseIterable, Identifiable {
    case system, light, dark
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var resolved: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
