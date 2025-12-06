//
//  SignInView.swift
//  Chirp
//
//  Created by Juan Palacio on 21.07.202423.11.2023.
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                // twitter logo
                TwitterLogo(frameWidth: 30, paddingTop: 15)
                Spacer()
                // hero text
                HeroText()
                // buttons
                // continue with google button
                googleSignup(colorScheme: colorScheme)
                // continue with apple
                SignInWithAppleButton(authManager: authManager, colorScheme: colorScheme)
                // or separator
                orSeparator()
                // inputs
                LoginInputs(email: $email, password: $password)
                // log in button
                LoginButtonReal(
                    email: email,
                    password: password,
                    isLoading: $isLoading,
                    showError: $showError,
                    errorMessage: $errorMessage,
                    authManager: authManager
                )
                // Forgot password
                Button("Forgot password?") {
                    Task {
                        guard !email.isEmpty else {
                            errorMessage = "Enter your email first"
                            showError = true
                            return
                        }
                        do {
                            try await authManager.resetPassword(email: email)
                            errorMessage = "Password reset email sent!"
                            showError = true
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
                .font(.footnote)
                .foregroundColor(Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0)))

                Spacer()
                // don't have an account text
                FooterText()
            }
            .alert("Notice", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
}

#Preview {
    SignInView()
}

struct HeroText: View {
    var body: some View {
        Text("Sign in to twitter")
            .font(.title)
            .fontWeight(.heavy)
            .padding(.bottom, 15)
            .padding(.trailing,70)
    }
}

struct LoginInputs: View {
    @Binding var email : String
    @Binding var password : String
    var body: some View {
        VStack{
            TextField("Email or username", text: $email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .frame(width: 300)
                .fontWeight(.semibold)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.systemGray3), lineWidth: 1)
                )
            SecureField("Enter your password", text: $password)
                .padding()
                .frame(width: 300)
                .fontWeight(.semibold)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(.systemGray3), lineWidth: 1) // Apply border with corner radius
                )
        }
    }
}

// MARK: - Real Login Button

struct LoginButtonReal: View {
    let email: String
    let password: String
    @Binding var isLoading: Bool
    @Binding var showError: Bool
    @Binding var errorMessage: String
    let authManager: AuthManager

    var body: some View {
        Button {
            Task {
                guard !email.isEmpty, !password.isEmpty else {
                    errorMessage = "Please enter email and password"
                    showError = true
                    return
                }

                isLoading = true
                do {
                    try await authManager.signIn(identifier: email, password: password)
                    // Auth state change will trigger navigation via RootView
                } catch {
                    errorMessage = error.localizedDescription
                    showError = true
                }
                isLoading = false
            }
        } label: {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .frame(width: (UIScreen.main.bounds.width) - 100, height: 50)
                    .background(Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0)))
                    .cornerRadius(10)
                    .padding(.top, 5)
            } else {
                Text("Log in")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(width: (UIScreen.main.bounds.width) - 100, height: 50)
                    .background(Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0)))
                    .cornerRadius(10)
                    .padding(.top, 5)
            }
        }
        .disabled(isLoading)
    }
}

// MARK: - Sign In With Apple Button

struct SignInWithAppleButton: View {
    let authManager: AuthManager
    let colorScheme: ColorScheme

    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        SignInWithAppleButtonViewRepresentable(colorScheme: colorScheme) { credential in
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

struct SignInWithAppleButtonViewRepresentable: UIViewRepresentable {
    let colorScheme: ColorScheme
    let onCompletion: (ASAuthorizationAppleIDCredential) -> Void

    func makeUIView(context: Context) -> ASAuthorizationAppleIDButton {
        let style: ASAuthorizationAppleIDButton.Style = colorScheme == .dark ? .white : .black
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: style)
        button.addTarget(context.coordinator, action: #selector(Coordinator.handleAppleSignIn), for: .touchUpInside)
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

        @objc func handleAppleSignIn() {
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
            print("Apple Sign-In failed: \(error.localizedDescription)")
        }
    }
}

struct FooterText: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        HStack {
            Text("Don't have an account?")
            Button("Sign up") {
                // Dismiss the current view and go back
                presentationMode.wrappedValue.dismiss()
            }
            .foregroundColor(Color(UIColor(red: 29/255, green: 161/255, blue: 242/255, alpha: 1.0)))
        }
        .font(.subheadline)
    }
}
