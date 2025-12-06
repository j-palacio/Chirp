//
//  SignUpView.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202422.11.2023.
//

import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthManager

    // Dark mode
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationStack {
            VStack {
                // twitter logo
                TwitterLogo(frameWidth: 30, paddingTop: 15)
                Spacer()
                // hero text
                Text("See what's happening in the world right now")
                    .font(.title)
                    .fontWeight(.heavy)
                    .padding(.trailing, 70)
                    .frame(width: 330)
                // buttons
                Spacer()
                // continue with google button
                googleSignup(colorScheme: colorScheme)
                // continue with apple
                SignUpWithAppleButton(authManager: authManager, colorScheme: colorScheme)
                // or separator
                orSeparator()
                // create account button
                NavigationLink {
                    RegistrationFormView()
                        .environmentObject(authManager)
                } label: {
                    Text("Create account")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: (UIScreen.main.bounds.width) - 100, height: 50)
                        .background(Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0)))
                        .cornerRadius(10)
                }
                // text
                signupPolicyText()
                // Already have an account?
                Spacer()
                alreadyHaveAnAccout()
            }
        }
    }
}

#Preview {
    SignUpView()
}

struct alreadyHaveAnAccout: View {
    var body: some View {
        HStack{
            Text("Have an account already?")
            NavigationLink{
                SignInView()
                    
            } label: {
                Text("Log in")
                    .foregroundColor(Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0)))
            }
          
            
        }.font(.subheadline)
    }
}

struct signupPolicyText: View {
    var body: some View {
        HStack{
            Text("By signing up, you agree to the ") +
            Text("Terms of Service ")
                .foregroundColor(Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0))) +
            Text("and ") +
            Text("Privacy Policy, ")
                .foregroundColor(Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0))) +
            Text("including ") +
            Text("Cookie Use.")
                .foregroundColor(Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0)))
        }.font(.footnote)
            .frame(width: (UIScreen.main.bounds.width) - 100, height: 50)
    }
}

// MARK: - Registration Form View

struct RegistrationFormView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var fullName = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 20) {
            TwitterLogo(frameWidth: 30, paddingTop: 15)

            Text("Create your account")
                .font(.title2)
                .fontWeight(.bold)

            VStack(spacing: 15) {
                TextField("Full Name", text: $fullName)
                    .textContentType(.name)
                    .padding()
                    .frame(width: 300)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray3), lineWidth: 1)
                    )

                TextField("Username", text: $username)
                    .textContentType(.username)
                    .autocapitalization(.none)
                    .padding()
                    .frame(width: 300)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray3), lineWidth: 1)
                    )

                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .frame(width: 300)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray3), lineWidth: 1)
                    )

                SecureField("Password", text: $password)
                    .textContentType(.newPassword)
                    .padding()
                    .frame(width: 300)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray3), lineWidth: 1)
                    )

                SecureField("Confirm Password", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .padding()
                    .frame(width: 300)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(.systemGray3), lineWidth: 1)
                    )
            }

            Button {
                Task {
                    await signUp()
                }
            } label: {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(width: (UIScreen.main.bounds.width) - 100, height: 50)
                        .background(Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0)))
                        .cornerRadius(10)
                } else {
                    Text("Sign Up")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: (UIScreen.main.bounds.width) - 100, height: 50)
                        .background(Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0)))
                        .cornerRadius(10)
                }
            }
            .disabled(isLoading)

            Spacer()
        }
        .padding()
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    private func signUp() async {
        // Validation
        guard !fullName.isEmpty else {
            errorMessage = "Please enter your full name"
            showError = true
            return
        }
        guard !username.isEmpty else {
            errorMessage = "Please enter a username"
            showError = true
            return
        }
        guard username.count >= 3 else {
            errorMessage = "Username must be at least 3 characters"
            showError = true
            return
        }
        guard !email.isEmpty else {
            errorMessage = "Please enter your email"
            showError = true
            return
        }
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            showError = true
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match"
            showError = true
            return
        }

        isLoading = true
        do {
            try await authManager.signUpWithEmail(
                email: email,
                password: password,
                username: username.lowercased(),
                fullName: fullName
            )
            // Auth state change will trigger navigation via RootView
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        isLoading = false
    }
}

// MARK: - Sign Up With Apple Button

struct SignUpWithAppleButton: View {
    let authManager: AuthManager
    let colorScheme: ColorScheme

    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        SignUpWithAppleButtonViewRepresentable(colorScheme: colorScheme) { credential in
            Task {
                isLoading = true
                do {
                    try await authManager.signInWithApple(credential: credential)
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }
                isLoading = false
            }
        }
        .frame(width: 300, height: 50)
        .cornerRadius(10)
        .overlay(
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
        )
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

struct SignUpWithAppleButtonViewRepresentable: UIViewRepresentable {
    let colorScheme: ColorScheme
    let onCompletion: (ASAuthorizationAppleIDCredential) -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let style: ASAuthorizationAppleIDButton.Style = colorScheme == .dark ? .white : .black
        let button = ASAuthorizationAppleIDButton(type: .signUp, style: style)
        button.addTarget(context.coordinator, action: #selector(Coordinator.handleAppleSignUp), for: .touchUpInside)
        return button
    }

    func updateUIView(_ uiView: ASAuthorizationAppleIDButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onCompletion: onCompletion)
    }

    class Coordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
        let onCompletion: (ASAuthorizationAppleIDCredential) -> Void

        init(onCompletion: @escaping (ASAuthorizationAppleIDCredential) -> Void) {
            self.onCompletion = onCompletion
        }

        @objc func handleAppleSignUp() {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }

        func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first else {
                return UIWindow()
            }
            return window
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
            if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
                onCompletion(credential)
            }
        }

        func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
            print("Apple Sign-Up failed: \(error.localizedDescription)")
        }
    }
}

struct orSeparator: View {
    var body: some View {
        HStack{
            Rectangle()
                .frame(width: (UIScreen.main.bounds.width / 2) - 65, height: 0.7 )
            Text("Or")
                .font(.footnote)
                .fontWeight(.semibold)
            Rectangle()
                .frame(width: (UIScreen.main.bounds.width / 2) - 65, height: 0.7 )
        }.foregroundColor(.gray)
    }
}

struct googleSignup: View {
    @EnvironmentObject var authManager: AuthManager
    let colorScheme: ColorScheme

    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        Button {
            Task {
                isLoading = true
                do {
                    try await authManager.signInWithGoogle()
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }
                isLoading = false
            }
        } label: {
            HStack{
                if isLoading {
                    ProgressView()
                        .frame(width: 24, height: 24)
                        .padding(.leading, 20)
                } else {
                    Image("GoogleLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24)
                        .padding(.leading, 20)
                }
                Text("Sign up with Google")
                    .padding(.vertical, 15)
                    .padding(.trailing,20)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            .frame(width: 300,height: 50)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.systemGray3), lineWidth: 1)
            )
            .background(colorScheme == .dark ? Color.black : Color.white)
        }
        .disabled(isLoading)
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}
