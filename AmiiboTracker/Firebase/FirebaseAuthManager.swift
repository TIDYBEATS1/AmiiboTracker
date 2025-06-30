//
//  FirebaseAuthManager.swift
//  AmiiboTracker
//
//  Created by Sam Stanwell on 30/06/2025.
//


import Foundation
import FirebaseAuth
import FirebaseCore

@MainActor
class FirebaseAuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var errorMessage: String?
    @Published var currentUserID: String?

    init() {
        setupFirebase()
        checkAuthState()
    }

    private func setupFirebase() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    func checkAuthState() {
        if let user = Auth.auth().currentUser {
            self.currentUserID = user.uid
            self.isLoggedIn = true
        } else {
            self.isLoggedIn = false
        }
    }

    func signUp(email: String, password: String) async {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            self.currentUserID = result.user.uid
            self.isLoggedIn = true
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.currentUserID = result.user.uid
            self.isLoggedIn = true
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isLoggedIn = false
            self.currentUserID = nil
        } catch {
            self.errorMessage = "Logout failed: \(error.localizedDescription)"
        }
    }
}
