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
        defer { isLoading = false }
        
        do {
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["name": .string(name)]
            )

            if let session = response.session {
                currentUser = session.user
                isAuthenticated = true
            } else {
                let signInResponse = try await supabase.auth.signIn(
                    email: email,
                    password: password
                )
                currentUser = signInResponse.user
                isAuthenticated = true
            }

            await createInitialProfileIfNeeded(name: name, email: email)
            return true
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
            currentUser = nil
            return false
        }
    }
    
    func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let response = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            currentUser = response.user
            isAuthenticated = true
            return true
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
            currentUser = nil
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
    
    private func createInitialProfileIfNeeded(name: String, email: String) async {
        if let existingProfile = try? await SupabaseStore.shared.fetchProfile(), existingProfile != nil {
            return
        }

        let initialProfile = UserProfile(
            name: name,
            email: email,
            bio: "",
            workoutSplit: [],
            goals: [],
            bodyWeightGoal: nil,
            workoutsGoal: nil,
            profileImageURL: nil
        )
        
        let userProfileStore = UserProfileStore()
        userProfileStore.profile = initialProfile
        await userProfileStore.saveProfile()
    }
}
