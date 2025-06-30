//
//  AppState.swift
//  AmiiboTracker
//
//  Created by Sam Stanwell on 30/06/2025.
//


import Foundation
import FirebaseAuth
import SwiftUI

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = Auth.auth().currentUser != nil
    @AppStorage("didSkipLogin") var didSkipLogin: Bool = false

    var isAuthenticated: Bool {
        isLoggedIn || didSkipLogin
    }
    private var authListener: AuthStateDidChangeListenerHandle?

   
    init() {
        authListener = Auth.auth().addStateDidChangeListener { _, user in    
            DispatchQueue.main.async {
                self.isLoggedIn = user != nil
                print("🟢 Auth state changed: loggedIn=\(self.isLoggedIn)")
            }
        }
    }

    func skipLogin() {
        print("⏭️ User skipped login")
        didSkipLogin = true
    }

    func signOut() {
        try? Auth.auth().signOut()
        isLoggedIn = false
        didSkipLogin = false
    }
}
