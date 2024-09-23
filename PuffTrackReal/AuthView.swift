//
//  AuthView.swift
//  PuffTrackReal
//
//  Created by Kaan Şenol on 14.09.2024.
//

import Foundation
import SwiftUI

struct AuthView: View {
    @State private var isLoginMode = true
    @ObservedObject var socialsViewModel: SocialsViewModel
    // Login fields
    @State private var email = ""
    @State private var password = ""
    @Binding var isPresented: Bool  // New binding to control view presentation

    // Register fields
    @State private var name = ""
    @State private var confirmPassword = ""
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            backgroundColor.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 25) {
                headerSection
                
                modePicker
                
                fieldsSection
                
                if isLoginMode {
                    forgotPasswordButton
                }
                
                actionButton
            }
            .padding()
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
                    .background(isLoginMode ? Color.red : Color.clear)
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
                    .background(!isLoginMode ? Color.red : Color.clear)
                    .cornerRadius(10)
            }
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
    
    private var fieldsSection: some View {
        VStack(spacing: 15) {
            if !isLoginMode {
                CustomTextField(icon: "person.fill", placeholder: "Name", text: $name)
            }
            
            CustomTextField(icon: "envelope.fill", placeholder: "Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textContentType(.emailAddress)
            
            CustomTextField(icon: "lock.fill", placeholder: "Password", text: $password, isSecure: true)
            
            if !isLoginMode {
                CustomTextField(icon: "lock.fill", placeholder: "Confirm Password", text: $confirmPassword, isSecure: true)
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
        AuthButton(title: isLoginMode ? "LOGIN" : "REGISTER") {
            if isLoginMode {
                socialsViewModel.login(email: email, password: password) { result in
                    switch result {
                    case .success:
                        socialsViewModel.connectSocket()
                        isPresented = false  // Dismiss the view on successful login
                    case .failure(_):
                        // Handle login failure (show an alert, for example)
                        break
                    }
                }
            } else {
                socialsViewModel.register(name: name, email: email, password: password) { result in
                    switch result {
                    case .success:
                        socialsViewModel.connectSocket()
                        isPresented = false  // Dismiss the view on successful registration
                    case .failure(_):
                        // Handle registration failure (show an alert, for example)
                        break
                    }
                }
            }
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

struct CustomTextField: View {
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
    @State private var isPressed = false
    
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
                .background(Color.red)
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                .scaleEffect(isPressed ? 0.98 : 1.0)
        }
    }
}


