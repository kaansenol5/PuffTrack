//
//  AuthView.swift
//  PuffTrackReal
//
//  Created by Kaan Şenol on 14.09.2024.
//

import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @State private var isLoginMode = true
    @ObservedObject var socialsViewModel: SocialsViewModel
    @State private var passwordsMatch = true
    @State private var email = ""
    @State private var password = ""
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var confirmPassword = ""
    @Environment(\.colorScheme) var colorScheme
    @State private var showEmailLogin = false

    var body: some View {
        ZStack {
            backgroundColor.edgesIgnoringSafeArea(.all)

            VStack(spacing: 30) {
                headerSection

                if showEmailLogin {
                    modePicker
                    fieldsSection

                    if isLoginMode {
                        forgotPasswordButton
                    } else if !passwordsMatch {
                        Text("Passwords do not match")
                            .foregroundColor(.red)
                            .font(.footnote)
                    }

                    actionButton
                    backButton
                } else {
                    signInWithAppleButton
                    signInWithEmailButton
                }
            }
            .padding()
        }
        .alert(isPresented: $socialsViewModel.isErrorDisplayed) {
            Alert(
                title: Text("Error"),
                message: Text(socialsViewModel.errorMessage ?? ""),
                dismissButton: .default(Text("OK")) {
                    socialsViewModel.isErrorDisplayed = false
                    socialsViewModel.errorMessage = ""
                }
            )
        }
    }


    private var headerSection: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 80, height: 80)
                Image(systemName: "flame.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            Text("PuffTrack")
                .font(.custom("Futura", size: 36))
                .foregroundColor(textColor)
        }
    }

    private var signInWithAppleButton: some View {
        SignInWithAppleButton(
            .signIn,
            onRequest: { request in
                request.requestedScopes = [.fullName, .email]
            },
            onCompletion: handleAuthorization
        )
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 50)
        .cornerRadius(10)
    }

    private func handleAuthorization(result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
               let identityTokenData = appleIDCredential.identityToken,
               let identityTokenString = String(data: identityTokenData, encoding: .utf8) {
                
                let userId = appleIDCredential.user
                let email = appleIDCredential.email
                let fullName = [appleIDCredential.fullName?.givenName, appleIDCredential.fullName?.familyName]
                    .compactMap { $0 }
                    .joined(separator: " ")
                
                socialsViewModel.signInWithApple(identityToken: identityTokenString, userId: userId, email: email, fullName: fullName.isEmpty ? nil : fullName) { result in
                    switch result {
                    case .success:
                        isPresented = false
                    case .failure(let error):
                        socialsViewModel.errorMessage = error.localizedDescription
                        socialsViewModel.isErrorDisplayed = true
                    }
                }
            } else {
                socialsViewModel.errorMessage = "Unable to retrieve identity token"
                socialsViewModel.isErrorDisplayed = true
            }
        case .failure(let error):
            socialsViewModel.errorMessage = error.localizedDescription
            socialsViewModel.isErrorDisplayed = true
        }
    }

    private var signInWithEmailButton: some View {
        Button(action: {
            withAnimation {
                showEmailLogin = true
            }
        }) {
            Text("Sign in with Email")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray)
                .cornerRadius(10)
        }
    }

    private var modePicker: some View {
        HStack {
            Button(action: {
                withAnimation {
                    isLoginMode = true
                }
            }) {
                Text("Login")
                    .font(.headline)
                    .foregroundColor(isLoginMode ? .white : .gray)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isLoginMode ? Color.gray : Color.clear)
                    .cornerRadius(10)
            }

            Button(action: {
                withAnimation {
                    isLoginMode = false
                }
            }) {
                Text("Register")
                    .font(.headline)
                    .foregroundColor(!isLoginMode ? .white : .gray)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(!isLoginMode ? Color.gray : Color.clear)
                    .cornerRadius(10)
            }
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }


    private var fieldsSection: some View {
        VStack(spacing: 15) {
            if !isLoginMode {
                AuthTextField(icon: "person.fill", placeholder: "Name", text: $name)
            }

            AuthTextField(icon: "envelope.fill", placeholder: "Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textContentType(.emailAddress)

            AuthTextField(icon: "lock.fill", placeholder: "Password", text: $password, isSecure: true)

            if !isLoginMode {
                AuthTextField(icon: "lock.fill", placeholder: "Confirm Password", text: $confirmPassword, isSecure: true)
            }
        }
        .padding()
        .background(fieldSectionBackgroundColor)
        .cornerRadius(15)
    }

    private var forgotPasswordButton: some View {
        Button(action: {
            // Handle forgot password action
        }) {
            Text("Forgot password?")
                .font(.footnote)
                .foregroundColor(.gray)
        }
    }

    private var actionButton: some View {
        AuthButton(title: isLoginMode ? "LOGIN" : "REGISTER", color: .gray) {
            if isLoginMode {
                socialsViewModel.login(email: email, password: password) { result in
                    switch result {
                    case .success:
                        socialsViewModel.connectSocket()
                        isPresented = false
                    case .failure(let error):
                        socialsViewModel.errorMessage = error.localizedDescription
                        socialsViewModel.isErrorDisplayed = true
                    }
                }
            } else {
                if password == confirmPassword {
                    passwordsMatch = true
                    socialsViewModel.register(name: name, email: email, password: password) { result in
                        switch result {
                        case .success:
                            socialsViewModel.connectSocket()
                            isPresented = false
                        case .failure(let error):
                            socialsViewModel.errorMessage = error.localizedDescription
                            socialsViewModel.isErrorDisplayed = true
                        }
                    }
                } else {
                    passwordsMatch = false
                }
            }
        }
    }


    private var backButton: some View {
        Button(action: {
            withAnimation {
                showEmailLogin = false
            }
        }) {
            Text("Back to Sign In Options")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray)
                .cornerRadius(10)
        }
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.9) : Color.white
    }

    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var fieldSectionBackgroundColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.05)
    }
}

struct AuthTextField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    var isSecure: Bool = false

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(textColor)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(textColor)
            }
        }
        .padding()
        .background(fieldBackgroundColor)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 3)
    }

    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }

    private var fieldBackgroundColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)
    }
}

struct AuthButton: View {
    let title: String
    let action: () -> Void
    let color: Color
    @State private var isPressed = false

    init(title: String, color: Color = .red, action: @escaping () -> Void) {
        self.title = title
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0)) {
                    isPressed = false
                }
            }
            action()
        }) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()
                .background(color)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                .scaleEffect(isPressed ? 0.98 : 1.0)
        }
    }
}

#Preview {
    AuthView(socialsViewModel: SocialsViewModel(), isPresented: .constant(true))
}
