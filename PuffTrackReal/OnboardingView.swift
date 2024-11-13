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
    @State private var dailyPuffLimit = ""
    @State private var showInputAlert = false
    
    // Add this state variable to control keyboard focus
    @FocusState private var focusedField: Field?
    
    // Add drag gesture state
    @GestureState private var dragOffset: CGFloat = 0
    
    let steps = [
        "Welcome",
        "Track Progress",
        "Social Support",
        "Vaping Habits",
        "Impact Analysis",
        "Set Daily Limit",
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
                        impactAnalysisView(size: geometry.size).tag(4)
                        setDailyLimitView(size: geometry.size, dailyPuffLimit: $dailyPuffLimit, accentColor: Color.red).tag(5)
                        stayMotivatedView(size: geometry.size).tag(6)
                        getStartedView(size: geometry.size).tag(7)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)
                    .interactiveDismissDisabled() // Disable default TabView swipe
                    .gesture(
                        DragGesture()
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation.width
                            }
                            .onEnded { value in
                                let threshold = geometry.size.width * 0.5
                                let newStep = value.translation.width > threshold ? currentStep - 1 :
                                             value.translation.width < -threshold ? currentStep + 1 :
                                             currentStep
                                
                                // Validate before allowing progression
                                if newStep > currentStep && currentStep == 3 && !areVapingFieldsFilled() {
                                    showInputAlert = true
                                } else if newStep >= 0 && newStep < steps.count {
                                    withAnimation {
                                        currentStep = newStep
                                    }
                                }
                            }
                    )
                    
                    navigationButtons
                }
            }
        }
        .alert(isPresented: $showInputAlert) {
            Alert(title: Text("Information Required"),
                  message: Text("Please fill in all vaping habit fields to continue."),
                  dismissButton: .default(Text("OK")))
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
                Button(action: {
                    withAnimation { currentStep -= 1 }
                    focusedField = nil // Dismiss keyboard when going back
                }) {
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
                    focusedField = nil // Dismiss keyboard when going to next step
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
            Image("pufftracklogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: min(size.width, size.height) * 0.4)
                .foregroundColor(accentColor)
            
            Text("Welcome to PuffTrack")
                .font(.system(size: 32, weight: .bold))
            
            Text("Your ally in quitting, one less puff at a time.")
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text("PuffTrack helps you break free from vaping by tracking habits, setting goals, and celebrating your victories in quitting.")
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
            Text("Every puff avoided is a win.")
                .font(.title3)
                .multilineTextAlignment(.center)
            Text("PuffTrack gives you the data you need to quit. Watch your progress grow and see how far you've come.")
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
            Text("Stronger together.")
                .font(.title3)
                .multilineTextAlignment(.center)
            Text("Quitting is hard, but you don't have to do it alone. Connect with friends, share your progress, and encourage each other to stay vape-free.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .foregroundColor(textColor)
    }
    
    func vapingHabitsView(size: CGSize) -> some View {
        VStack(spacing: 20) {
            Text("Understand Your Habits")
                .font(.system(size: 28, weight: .bold))
            Text("We need to know where you're at to help you quit. Provide your current vaping details to build a plan for your journey away from nicotine.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Group {
                CustomTextField(placeholder: "Cost per vape ($)", text: $vapeCost, colorScheme: colorScheme, focusedField: $focusedField, field: .vapeCost)
                    .keyboardType(.decimalPad)
                CustomTextField(placeholder: "Puffs per vape", text: $puffsPerVape, colorScheme: colorScheme, focusedField: $focusedField, field: .puffsPerVape)
                    .keyboardType(.numberPad)
                CustomTextField(placeholder: "Monthly vape spending ($)", text: $monthlySpending, colorScheme: colorScheme, focusedField: $focusedField, field: .monthlySpending)
                    .keyboardType(.decimalPad)
            }
        }
        .padding()
        .foregroundColor(textColor)
    }
    
    func impactAnalysisView(size: CGSize) -> some View {
        VStack(spacing: 20) {
            if let cost = Double(vapeCost),
               let puffs = Double(puffsPerVape),
               let monthly = Double(monthlySpending) {
                
                // Calculate yearly metrics
                let yearlySpending = monthly * 12
                let vapesPerYear = (monthly * 12) / cost
                let timeWasted = (puffs * vapesPerYear * 3) / 3600 // 3 seconds per puff, converted to hours
                let wasteGenerated = vapesPerYear * 0.15 // Assuming 0.15 kg per vape device
                
                VStack(spacing: 30) {
                    Text("Analyzing Your Vaping Impact")
                        .font(.system(size: 24, weight: .bold))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    LoadingView(isLoading: true)
                        .frame(height: 50)
                    
                    RevealingMetricsView(
                        yearlySpending: yearlySpending,
                        vapesPerYear: vapesPerYear,
                        timeWasted: timeWasted,
                        wasteGenerated: wasteGenerated
                    )
                }
            } else {
                Text("Please fill in all fields to see your impact analysis")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    func setDailyLimitView(size: CGSize, dailyPuffLimit: Binding<String>, accentColor: Color) -> some View {
        let limitValue = Binding<Double>(
            get: { Double(dailyPuffLimit.wrappedValue) ?? 0 },
            set: { dailyPuffLimit.wrappedValue = String(Int($0)) }
        )
        
        return VStack(spacing: 20) {
            Text("Cutting Back, Day by Day")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.secondary.opacity(0.1))
                
                VStack {
                    Slider(value: limitValue, in: 0...100, step: 1)
                        .accentColor(accentColor)
                        .padding(.horizontal)
                    
                    HStack {
                        Text("0")
                        Spacer()
                        Text("\(Int(limitValue.wrappedValue))")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(accentColor)
                        Spacer()
                        Text("100")
                    }
                    .padding(.horizontal)
                }
            }
            .frame(height: size.height * 0.15)
            
            Text("Set a daily puff limit to start cutting back. Every reduction counts.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "info.circle")
                Text("Challenge yourself to reduce your daily puff count")
            }
            .font(.footnote)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
    
    func stayMotivatedView(size: CGSize) -> some View {
        VStack(spacing: 30) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: min(size.width, size.height) * 0.15))
                .foregroundColor(accentColor)
            Text("Motivation to Quit for Good")
                .font(.system(size: 28, weight: .bold))
            Text("Receive personalized notifications to keep you on track.")
                .font(.title3)
                .multilineTextAlignment(.center)
            Text("Receive daily nudges to help you stay on track and quit vaping for good. Remember: every time you skip a puff, you're winning.")
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
            Text("A Healthier You Starts Now")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
            Text("You're taking the first step towards a life free from nicotine. Let's quit, one puff at a time.")
                .font(.title3)
                .multilineTextAlignment(.center)
            Text("Every avoided puff brings you closer to a healthier, happier life. PuffTrack is here to help you get there.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .foregroundColor(textColor)
    }
    
    private func areVapingFieldsFilled() -> Bool {
        return !vapeCost.isEmpty &&
               !puffsPerVape.isEmpty &&
               !monthlySpending.isEmpty &&
               (Double(vapeCost) != nil) &&
               (Int(puffsPerVape) != nil) &&
               (Double(monthlySpending) != nil)
    }
    
    private func completeOnboarding() {
        let limit = Int(dailyPuffLimit) ?? 0
        if let cost = Double(vapeCost),
           let puffs = Int(puffsPerVape),
           let spending = Double(monthlySpending)
            {
            viewModel.updateSettings(vapeCost: cost, puffsPerVape: puffs, monthlySpending: spending, dailyPuffLimit: limit)
            
            isOnboardingComplete = true
            UserDefaults.standard.set(true, forKey: "onboardingComplete")
        } else {
            showInputAlert = true
        }
    }
}

struct LoadingView: View {
    @State private var isLoading: Bool
    @State private var showResults = false
    
    init(isLoading: Bool) {
        self._isLoading = State(initialValue: isLoading)
        self._showResults = State(initialValue: false)
    }
    
    var body: some View {
        VStack {
            if isLoading && !showResults {
                ProgressView("Analyzing your habits...")
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation {
                                showResults = true
                            }
                        }
                    }
            }
        }
    }
}

struct RevealingMetricsView: View {
    let yearlySpending: Double
    let vapesPerYear: Double
    let timeWasted: Double
    let wasteGenerated: Double
    
    @State private var showMetrics = false
    
    var body: some View {
        VStack(spacing: 25) {
            if showMetrics {
                // Money Impact
                MetricCard(
                    icon: "dollarsign.circle.fill",
                    title: "Yearly Spending",
                    value: String(format: "$%.2f", yearlySpending),
                    subtitle: "That's a down payment on a car",
                    color: .red
                )
                .transition(.scale.combined(with: .opacity))
                
                // Vapes Count
                MetricCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "Vapes Used Yearly",
                    value: String(format: "%.0f devices", vapesPerYear),
                    subtitle: "Each one impacts your health",
                    color: .orange
                )
                .transition(.scale.combined(with: .opacity))
                
                // Time Impact
                MetricCard(
                    icon: "clock.fill",
                    title: "Hours Lost to Vaping",
                    value: String(format: "%.1f hours", timeWasted),
                    subtitle: "Time you'll never get back",
                    color: .purple
                )
                .transition(.scale.combined(with: .opacity))
                
                // Environmental Impact
                MetricCard(
                    icon: "leaf.fill",
                    title: "Waste Generated",
                    value: String(format: "%.1f kg", wasteGenerated),
                    subtitle: "Non-biodegradable waste in landfills",
                    color: .green
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.6).delay(1.0)) {
                showMetrics = true
            }
        }
    }
}

struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(value)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(color)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(15)
        }
    }
}

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let colorScheme: ColorScheme
    @FocusState.Binding var focusedField: Field?
    let field: Field
    
    var body: some View {
        TextField(placeholder, text: $text)
            .padding()
            .background(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05))
            .cornerRadius(10)
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .accentColor(.red)
            .focused($focusedField, equals: field)
    }
}

enum Field: Hashable {
    case vapeCost
    case puffsPerVape
    case monthlySpending
    case dailyPuffLimit
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false), viewModel: PuffTrackViewModel())
}
