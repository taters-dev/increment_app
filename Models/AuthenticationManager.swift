import Foundation
import Supabase

@MainActor
class AuthenticationManager: ObservableObject {
    static let shared = AuthenticationManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: Auth.User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseConfig.shared.client
    
    private init() {
        // Check if user is already authenticated on app launch (non-blocking)
        Task { [weak self] in
            await self?.checkAuthStatus()
        }
    }
    
    func checkAuthStatus() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let session = try await supabase.auth.session
            currentUser = session.user
            isAuthenticated = true
        } catch {
            isAuthenticated = false
            currentUser = nil
        }
    }
    
    func signUp(email: String, password: String, name: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["name": .string(name)]
            )
            
            self.currentUser = response.user
            self.isAuthenticated = true
            isLoading = false
            
            // Create initial user profile after successful signup
            await createInitialProfile(name: name, email: email)
            
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            self.currentUser = response.user
            self.isAuthenticated = true
            isLoading = false
            return true
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func resetPassword(email: String) async -> Bool {
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
    
    private func createInitialProfile(name: String, email: String) async {
        // Create an empty user profile for new users
        let initialProfile = UserProfile(
            name: name,
            email: email,
            bio: "",
            workoutSplit: [], // Empty workout split
            goals: [], // Empty goals
            bodyWeightGoal: nil, // No body weight goal initially
            profileImageURL: nil
        )
        
        // Save the profile locally and sync to Supabase
        let userProfileStore = UserProfileStore()
        userProfileStore.profile = initialProfile
        await userProfileStore.saveProfile()
                // Created initial user profile
    }
}
