import Foundation
import AuthenticationServices
import SwiftUI

// MARK: - Authentication Manager
@MainActor
final class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentUser: User?
    @Published private(set) var authState: AuthState = .unknown
    
    private let keychainManager = KeychainManager()
    private let cloudKitManager = CloudKitManager.shared
    
    enum AuthState {
        case unknown
        case authenticated
        case unauthenticated
        case loading
    }
    
    private init() {}
    
    // MARK: - Public Methods
    
    func checkAuthenticationStatus() async {
        authState = .loading
        
        // Check for stored credentials
        if let userID = keychainManager.getUserID() {
            do {
                // Verify with CloudKit
                let user = try await cloudKitManager.fetchUser(userID: userID)
                self.currentUser = user
                self.isAuthenticated = true
                self.authState = .authenticated
            } catch {
                print("Failed to fetch user: \(error)")
                self.authState = .unauthenticated
                keychainManager.deleteUserID()
            }
        } else {
            authState = .unauthenticated
        }
    }
    
    func signInWithApple() async throws {
        authState = .loading
        
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        let delegate = SignInWithAppleDelegate()
        authorizationController.delegate = delegate
        
        do {
            let result = try await withCheckedThrowingContinuation { continuation in
                delegate.continuation = continuation
                authorizationController.performRequests()
            }
            
            try await handleSignInResult(result)
        } catch {
            authState = .unauthenticated
            throw error
        }
    }
    
    func signOut() {
        keychainManager.deleteUserID()
        currentUser = nil
        isAuthenticated = false
        authState = .unauthenticated
    }
    
    // MARK: - Private Methods
    
    private func handleSignInResult(_ authorization: ASAuthorization) async throws {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthError.invalidCredential
        }
        
        let userID = appleIDCredential.user
        let email = appleIDCredential.email
        let fullName = appleIDCredential.fullName
        
        // Create or update user
        let user = User(
            id: userID,
            email: email,
            displayName: fullName?.formatted() ?? "FitDad User",
            createdAt: Date()
        )
        
        // Save to CloudKit
        try await cloudKitManager.saveUser(user)
        
        // Save to Keychain
        keychainManager.saveUserID(userID)
        
        // Update state
        self.currentUser = user
        self.isAuthenticated = true
        self.authState = .authenticated
    }
}

// MARK: - Sign In With Apple Delegate
private class SignInWithAppleDelegate: NSObject, ASAuthorizationControllerDelegate {
    var continuation: CheckedContinuation<ASAuthorization, Error>?
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation?.resume(returning: authorization)
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case invalidCredential
    case userNotFound
    case signInFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Invalid authentication credentials"
        case .userNotFound:
            return "User not found"
        case .signInFailed(let error):
            return "Sign in failed: \(error.localizedDescription)"
        }
    }
} 