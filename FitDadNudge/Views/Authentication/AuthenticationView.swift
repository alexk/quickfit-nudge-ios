import SwiftUI

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
                Button(action: {
                    Task {
                        await signIn()
                    }
                }) {
                    HStack {
                        Image(systemName: "applelogo")
                            .font(.title3)
                        Text("Sign in with Apple")
                            .font(.headline)
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(radius: 5)
                }
                .padding(.horizontal, 40)
                .disabled(authManager.authState == .loading)
                
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
    
    private func signIn() async {
        do {
            try await authManager.signInWithApple()
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