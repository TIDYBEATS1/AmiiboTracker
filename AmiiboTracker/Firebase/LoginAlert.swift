import SwiftUI

struct LoginAlert: View {
    @Binding var isShowing: Bool
    @Binding var username: String
    @Binding var password: String
    @Binding var errorMessage: String
    
    var onSubmit: (String, String, Bool) -> Void
    
    @State private var isRegistering = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text(isRegistering ? "Register" : "Login")
                .font(.headline)
            
            TextField("Email", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            HStack {
                Button("Cancel") {
                    isShowing = false
                }
                
                Spacer()
                
                Button(isRegistering ? "Register" : "Login") {
                    onSubmit(username, password, isRegistering)
                }
            }
            
            Button(isRegistering ? "Have an account? Login" : "No account? Register") {
                isRegistering.toggle()
            }
            .font(.footnote)
            Button("Skip Login") {
                onSubmit("guest@amiibo.local", "guest", false)
                isShowing = false
            }
            .font(.footnote)
            .foregroundColor(.blue)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemFill)))
        .shadow(radius: 10)
        .padding()
    }
}
