import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isLoginMode = true
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var showingAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // App Logo/Title
                VStack(spacing: 8) {
                    Text("INCREMENT")
                        .font(.system(size: 24, weight: .bold, design: .default))
                        .italic()
                        .foregroundColor(AppStyle.brandBlue)
                    
                    Text("Track Your Progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Authentication Form
                VStack(spacing: 16) {
                    if !isLoginMode {
                        TextField("Full Name", text: $name)
                            .padding()
                            .background(AppStyle.cardBackground)
                            .cornerRadius(20)
                            .autocapitalization(.words)
                    }
                    
                    TextField("Email", text: $email)
                        .padding()
                        .background(AppStyle.cardBackground)
                        .cornerRadius(20)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    
                    SecureField("Password", text: $password)
                        .padding()
                        .background(AppStyle.cardBackground)
                        .cornerRadius(20)
                    
                    if !isLoginMode {
                        SecureField("Confirm Password", text: $confirmPassword)
                            .padding()
                            .background(AppStyle.cardBackground)
                            .cornerRadius(20)
                    }
                    
                    // Action Button
                    Button(action: handleAuthentication) {
                        HStack {
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isLoginMode ? "Sign In" : "Sign Up")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppStyle.brandBlue)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                    }
                    .disabled(authManager.isLoading || !isFormValid)
                    
                    // Toggle Mode
                    Button(action: { 
                        isLoginMode.toggle()
                        clearForm()
                    }) {
                        Text(isLoginMode ? "Don't have an account? Sign Up" : "Already have an account? Sign In")
                            .foregroundColor(AppStyle.brandBlue)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(authManager.errorMessage ?? "An error occurred")
            }
        }
    }
    
    private var isFormValid: Bool {
        if isLoginMode {
            return !email.isEmpty && !password.isEmpty
        } else {
            return !name.isEmpty && !email.isEmpty && !password.isEmpty && password == confirmPassword
        }
    }
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        name = ""
    }
    
    private func handleAuthentication() {
        Task {
            let success: Bool
            
            if isLoginMode {
                success = await authManager.signIn(email: email, password: password)
            } else {
                success = await authManager.signUp(email: email, password: password, name: name)
            }
            
            if !success {
                showingAlert = true
            }
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
