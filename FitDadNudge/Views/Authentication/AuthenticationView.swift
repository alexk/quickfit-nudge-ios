import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo and app name
                VStack(spacing: 20) {
                    Image(systemName: "figure.run.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                    
                    Text("FitDad Nudge")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Micro-workouts for busy dads")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                // Sign in button
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        Task {
                            await handleSignIn(result)
                        }
                    }
                )
                .signInWithAppleButtonStyle(.white)
                .frame(height: 50)
                .cornerRadius(8)
                .shadow(radius: 5)
                .padding(.horizontal, 40)
                
                // Privacy text
                Text("By signing in, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func handleSignIn(_ result: Result<ASAuthorization, Error>) async {
        do {
            switch result {
            case .success(let authorization):
                                 // Temporarily handle sign in without the full auth manager
                 // This will be connected properly once all files are in place
                 print("Sign in successful with authorization: \(authorization)")
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Preview
#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager.shared)
} 