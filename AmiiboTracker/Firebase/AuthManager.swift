import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthManager: ObservableObject {
    @Published var loggedIn: Bool = false
    @Published var user: User?

    var currentUser: User? {
        Auth.auth().currentUser
    }

    init() {
        self.user = Auth.auth().currentUser
        self.loggedIn = (user != nil)
        
        Auth.auth().addStateDidChangeListener { _, user in
            self.user = user
            self.loggedIn = (user != nil)
        }
    }

    func login(email: String, password: String, completion: @escaping (String?) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(error.localizedDescription)
                } else {
                    self.user = result?.user
                    self.loggedIn = true
                    print("✅ Logged in as: \(self.user?.email ?? "unknown")")

                    // Notify app to load owned Amiibos
                    if let uid = result?.user.uid {
                        NotificationCenter.default.post(name: .loadOwnedAmiibos, object: uid)
                    }

                    completion(nil)
                }
            }
        }
    }

    func register(email: String, password: String, completion: @escaping (String?) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(error.localizedDescription)
                } else {
                    self.user = result?.user
                    self.loggedIn = true
                    completion(nil)
                }
            }
        }
    }

    func logout() {
        do {
            try Auth.auth().signOut()
            self.user = nil
            self.loggedIn = false
        } catch {
            print("❌ Logout failed: \(error.localizedDescription)")
        }
    }

    func skipLogin() {
        self.user = nil
        self.loggedIn = true // Guest login mode
    }
}
