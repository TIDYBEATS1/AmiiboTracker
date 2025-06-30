import SwiftUI
import FirebaseAuth
import Foundation

struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var service: AmiiboService
    @State private var showingLogin = false
    @State private var username = ""
    @State private var password = ""
    @State private var loginError = ""

    var body: some View {
        Group {
            if authManager.loggedIn {
                ContentView()
            } else {
                loginOverlay
            }
        }
        .onAppear {
            showingLogin = !authManager.loggedIn
        }
        .onChange(of: authManager.loggedIn) { newValue in
            showingLogin = !newValue
        }
        .onReceive(NotificationCenter.default.publisher(for: .showLogin)) { _ in
            showingLogin = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .loadOwnedAmiibos)) { notif in
            if let uid = notif.object as? String {
                service.loadOwnedAmiibos(for: uid)
            }
        }
    }

    @ViewBuilder
    private var loginOverlay: some View {
        ZStack {
            Color.black.opacity(0.05).ignoresSafeArea()

            if showingLogin {
                LoginAlert(
                    isShowing: $showingLogin,
                    username: $username,
                    password: $password,
                    errorMessage: $loginError
                ) { email, password, isRegistering in

                    // Guest login
                    if (email == "guest@amiibo.local" && password == "guest") || (email == "guest" && password == "skip") {
                        authManager.skipLogin()
                        showingLogin = false
                        return
                    }

                    if isRegistering {
                        // Register
                        authManager.register(email: email, password: password) { error in
                            loginError = error ?? ""
                        }
                    } else {
                        // Login
                        authManager.login(email: email, password: password) { error in
                            if error == nil {
                                if let uid = Auth.auth().currentUser?.uid {
                                    service.loadOwnedAmiibos(for: uid)   // Load from Firebase after login
                                }
                            } else {
                                print("Login failed: \(error!)")
                            }
                        }
                    }
                }
            }
        }
    }
}
