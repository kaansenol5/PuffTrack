//
//  OnboardingView.swift
//  PuffTrackReal
//
//  Created by Kaan Şenol on 25.09.2024.
//

import Foundation
import SwiftUI

struct OnboardingView: View {
    @Binding var isOnboardingComplete: Bool
    @ObservedObject var viewModel: PuffTrackViewModel
    @State private var currentStep = 0
    @Environment(\.colorScheme) var colorScheme
    
    // User input states
    @State private var name = ""
    @State private var vapeCost = ""
    @State private var puffsPerVape = ""
    @State private var monthlySpending = ""
    @State private var showInputAlert = false
    
    let steps = [
        "Welcome",
        "Track Progress",
        "Social Support",
        "Vaping Habits",
        "Stay Motivated",
        "Get Started"
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    progressBar
                    
                    TabView(selection: $currentStep) {
                        welcomeView(size: geometry.size).tag(0)
                        trackProgressView(size: geometry.size).tag(1)
                        socialSupportView(size: geometry.size).tag(2)
                        vapingHabitsView(size: geometry.size).tag(3)
                        stayMotivatedView(size: geometry.size).tag(4)
                        getStartedView(size: geometry.size).tag(5)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                    
                    navigationButtons
                }
            }
        }
        .alert(isPresented: $showInputAlert) {
            Alert(title: Text("Information Required"), message: Text("Please fill in all fields to continue."), dismissButton: .default(Text("OK")))
        }
    }
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    var accentColor: Color {
        Color.red
    }
    
    var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(0..<steps.count, id: \.self) { index in
                Capsule()
                    .fill(index <= currentStep ? accentColor : Color.gray.opacity(0.3))
                    .frame(height: 4)
                    .animation(.spring(), value: currentStep)
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button(action: { withAnimation { currentStep -= 1 } }) {
                    Text("Back")
                        .foregroundColor(textColor.opacity(0.7))
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(20)
                }
            }
            Spacer()
            Button(action: {
                if currentStep == 3 && !areVapingFieldsFilled() {
                    showInputAlert = true
                } else if currentStep == steps.count - 1 {
                    completeOnboarding()
                } else {
                    withAnimation { currentStep += 1 }
                }
            }) {
                Text(currentStep == steps.count - 1 ? "Get Started" : "Next")
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(accentColor)
                    .cornerRadius(20)
            }
        }
        .padding()
    }
    
    func welcomeView(size: CGSize) -> some View {
        VStack(spacing: 30) {
            Image(systemName: "lungs.fill")
                .font(.system(size: min(size.width, size.height) * 0.2))
                .foregroundColor(accentColor)
            Text("Welcome to PuffTrack")
                .font(.system(size: 32, weight: .bold))
            Text("Your personal companion on the journey to a healthier, vape-free life.")
                .font(.title3)
                .multilineTextAlignment(.center)
            Text("PuffTrack helps you monitor your vaping habits, set goals, and celebrate your progress towards quitting.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .foregroundColor(textColor)
    }
    
    func trackProgressView(size: CGSize) -> some View {
        VStack(spacing: 30) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: min(size.width, size.height) * 0.15))
                .foregroundColor(accentColor)
            Text("Track Your Progress")
                .font(.system(size: 28, weight: .bold))
            Text("Monitor your daily puff count and see how it changes over time.")
                .font(.title3)
                .multilineTextAlignment(.center)
            Text("PuffTrack provides insightful statistics on your vaping habits, helping you understand your patterns and motivating you to reduce your intake.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .foregroundColor(textColor)
    }
    
    func socialSupportView(size: CGSize) -> some View {
        VStack(spacing: 30) {
            Image(systemName: "person.3.fill")
                .font(.system(size: min(size.width, size.height) * 0.15))
                .foregroundColor(accentColor)
            Text("Connect and Support")
                .font(.system(size: 28, weight: .bold))
            Text("You're not alone on this journey.")
                .font(.title3)
                .multilineTextAlignment(.center)
            Text("Connect with friends, share your progress, and motivate each other. Our social features allow you to build a support network and celebrate milestones together.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .foregroundColor(textColor)
    }
    
    func vapingHabitsView(size: CGSize) -> some View {
        VStack(spacing: 20) {
            Text("Your Vaping Habits")
                .font(.system(size: 28, weight: .bold))
            Text("Help us understand your current habits so we can provide personalized insights and track your savings.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Group {
                CustomTextField(placeholder: "Cost per vape ($)", text: $vapeCost, colorScheme: colorScheme)
                    .keyboardType(.decimalPad)
                CustomTextField(placeholder: "Puffs per vape", text: $puffsPerVape, colorScheme: colorScheme)
                    .keyboardType(.numberPad)
                CustomTextField(placeholder: "Monthly vape spending ($)", text: $monthlySpending, colorScheme: colorScheme)
                    .keyboardType(.decimalPad)
            }
        }
        .padding()
        .foregroundColor(textColor)
    }
    
    func stayMotivatedView(size: CGSize) -> some View {
        VStack(spacing: 30) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: min(size.width, size.height) * 0.15))
                .foregroundColor(accentColor)
            Text("Stay Motivated")
                .font(.system(size: 28, weight: .bold))
            Text("Receive personalized notifications to keep you on track.")
                .font(.title3)
                .multilineTextAlignment(.center)
            Text("Get daily insights, motivational messages, and milestone reminders. We'll help you stay focused on your goal of quitting.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Toggle("Enable Notifications", isOn: $viewModel.notificationsEnabled)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
        }
        .padding()
        .foregroundColor(textColor)
    }
    
    func getStartedView(size: CGSize) -> some View {
        VStack(spacing: 30) {
            Image(systemName: "flag.checkered.circle.fill")
                .font(.system(size: min(size.width, size.height) * 0.2))
                .foregroundColor(accentColor)
            Text("You're All Set!")
                .font(.system(size: 32, weight: .bold))
            Text("Your journey to a healthier lifestyle begins now.")
                .font(.title3)
                .multilineTextAlignment(.center)
            Text("Remember, every puff you don't take is a step towards a healthier you. PuffTrack is here to support you every step of the way.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .foregroundColor(textColor)
    }
    
    private func areVapingFieldsFilled() -> Bool {
        return !vapeCost.isEmpty && !puffsPerVape.isEmpty && !monthlySpending.isEmpty
    }
    
    private func completeOnboarding() {
        if let cost = Double(vapeCost),
           let puffs = Int(puffsPerVape),
           let spending = Double(monthlySpending) {
            viewModel.updateSettings(vapeCost: cost, puffsPerVape: puffs, monthlySpending: spending)
            isOnboardingComplete = true
            UserDefaults.standard.set(true, forKey: "onboardingComplete")
        } else {
            showInputAlert = true
        }
    }
}

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let colorScheme: ColorScheme
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
            .cornerRadius(10)
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .accentColor(.red)
    }
}
