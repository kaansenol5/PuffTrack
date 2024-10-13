//
//  ContentView.swift
//  PuffTrackReal
//
//  Created by Kaan Şenol on 3.07.2024.
//
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PuffTrackViewModel()
    @StateObject private var socialsViewModel = SocialsViewModel()
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var syncer: Syncer?
    @State private var isSettingsPresented = false
    @State private var isMilestonesPresented = false
    @State private var isFriendsPresented = false
    @State private var isAuthPresented = false
    @State private var isPurchaseViewPresented = false
    @Environment(\.colorScheme) var colorScheme
    @State private var onboardingComplete: Bool = UserDefaults.standard.bool(forKey: "onboardingComplete")
    
    var body: some View {
        Group {
            if !onboardingComplete {
                OnboardingView(isOnboardingComplete: $onboardingComplete, viewModel: viewModel)
            } else if !purchaseManager.isSubscribed{
                PurchaseView()
            } else {
                mainContent
                    .onChange(of: purchaseManager.isSubscribed) { newValue in
                        if !newValue {
                            isPurchaseViewPresented = true
                        }
                    }
                    .sheet(isPresented: $isPurchaseViewPresented) {
                        PurchaseView()
                    }
            }
        }
    }
    
    var mainContent: some View {
        GeometryReader { geometry in
                VStack(spacing: geometry.size.height * 0.03) {
                    headerSection(screenHeight: geometry.size.height)
                    puffTracker(size: geometry.size)
                    withdrawalTrackerSection
                    statsSection
                    if geometry.size.height > 647 {
                        socialSection
                    }
                }
                .padding(.horizontal, geometry.size.width * 0.05)
                .padding(.vertical, geometry.size.height * 0.02)
        }
        .alert(isPresented: $socialsViewModel.isErrorDisplayed) {
            Alert(
                title: Text("Alert"),
                message: Text(socialsViewModel.errorMessage),
                dismissButton: .default(Text("OK")) {
                    print("OK tapped")
                    socialsViewModel.isErrorDisplayed = false
                    socialsViewModel.errorMessage = ""
                }
            )
        }
        .onAppear {
            if syncer == nil {
                syncer = Syncer(puffTrackViewModel: viewModel, socialsViewModel: socialsViewModel)
            }
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(viewModel: viewModel, socialsViewModel: socialsViewModel, isAuthViewPresented: isAuthPresented)
        }
        .sheet(isPresented: $isMilestonesPresented) {
            MilestonesView(viewModel: viewModel)
        }
        .sheet(isPresented: $isAuthPresented) {
            AuthView(socialsViewModel: socialsViewModel, isPresented: $isAuthPresented)
        }
        .sheet(isPresented: $isFriendsPresented) {
            if socialsViewModel.isUserLoggedIn() {
                FriendsView(socialsViewModel: socialsViewModel)
            } else {
                AuthView(socialsViewModel: socialsViewModel, isPresented: $isAuthPresented)
            }
        }
    }

    private func headerSection(screenHeight: CGFloat) -> some View {
        ZStack {
            HStack {
                Button(action: { isSettingsPresented.toggle() }) {
                    Image(systemName: "gear")
                        .foregroundColor(.red)
                        .imageScale(.large)
                }
                
                Spacer()
                
                if screenHeight <= 647 {
                    // Small screen: Make the friends button a system icon
                    Button(action: {
                        if socialsViewModel.isUserLoggedIn() {
                            isFriendsPresented.toggle()
                        } else {
                            isAuthPresented.toggle()
                        }
                    }) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.red)
                            .imageScale(.large)
                            .frame(width: 24, height: 24)
                    }
                } else {
                    // Larger screens: Show the red dot as is
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                }
            }
            
            Text("PuffTrack")
                .font(.custom("Futura", size: 24))
                .foregroundColor(textColor)
        }
    }

    private func puffTracker(size: CGSize) -> some View {
        VStack(spacing: size.height * 0.02) {
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                    .frame(width: min(size.width * 0.5, size.height * 0.3), height: min(size.width * 0.5, size.height * 0.3))
                    .rotationEffect(.degrees(180))
                
                Circle()
                    .trim(from: 0, to: min(CGFloat(viewModel.puffCount) / CGFloat(viewModel.model.settings.dailyPuffLimit) * 0.5, 0.5))
                    .stroke(Color.red, lineWidth: 20)
                    .frame(width: min(size.width * 0.5, size.height * 0.3), height: min(size.width * 0.5, size.height * 0.3))
                    .rotationEffect(.degrees(180))
                    .animation(.spring(), value: viewModel.puffCount)

                
                VStack {
                    Text("\(viewModel.puffCount)")
                        .font(.system(size: min(size.width * 0.12, size.height * 0.07), weight: .bold, design: .rounded))
                        .foregroundColor(textColor)
                    Text("PUFFS")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Vape lasts \(String(format: "%.1f", viewModel.vapeDuration)) days")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(hoursSinceLastPuffText)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            PuffButton(action: {
                viewModel.addPuff(socialsViewModel: socialsViewModel)
                syncer?.syncUnsynedPuffs()
            })
            .frame(width: min(size.width * 0.6, 250))
        }
    }

    private var hoursSinceLastPuffText: String {
        let hours = viewModel.hoursSinceLastPuff
        if hours < 1 {
            return "Less than an hour since last puff"
        } else if hours == 1 {
            return "1 hour since last puff"
        } else {
            return "\(hours) hours since last puff"
        }
    }

    private var withdrawalTrackerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Withdrawal Tracker")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(.red)
                    .font(.system(size: 24))
                
                Text(viewModel.withdrawalStatus)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(timeElapsed)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(viewModel.withdrawalDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 5)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var timeElapsed: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: viewModel.lastPuffTime, relativeTo: Date())
    }

    private var statsSection: some View {
        VStack(spacing: 15) {
            HStack {
                Text("Streak")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("Monthly Potential Savings")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                HStack(spacing: 15) {
                    StatCard(value: "\(viewModel.streak) days", icon: "flame.fill", color: .orange, action: { isMilestonesPresented.toggle() })
                        .frame(width: geometry.size.width / 2 - 7.5)
                    StatCard(value: "$\(String(format: "%.0f", viewModel.moneySaved))", icon: "dollarsign.circle.fill", color: .green, action: {})
                        .frame(width: geometry.size.width / 2 - 7.5)
                }
            }
            .frame(height: 100)
        }
    }

    private var socialSection: some View {
        Button(action: {
            if socialsViewModel.isUserLoggedIn() {
                isFriendsPresented.toggle()
            } else {
                isAuthPresented.toggle()
            }
        }) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Friends")
                    .font(.headline)
                    .foregroundColor(textColor)
                if socialsViewModel.serverData?.friends.isEmpty ?? true {
                    Text("No friends yet, click to add friends")
                        .foregroundColor(.secondary)
                }
                ForEach(socialsViewModel.serverData?.friends.prefix(3) ?? []) { friend in
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(getInitials(from: friend.name))
                                    .foregroundColor(.white)
                                    .font(.headline)
                            )
                        VStack(alignment: .leading, spacing: 5) {
                            Text(friend.name)
                                .foregroundColor(textColor)
                                .font(.headline)
                            Text("\(friend.puffsummary.puffsToday) puffs today")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("\(friend.puffsummary.changePercentage)%")
                            .foregroundColor(Int(friend.puffsummary.changePercentage) ?? 0 >= 0 ? .green : .red)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 5)
                }
            }
            .padding()
            .background(cardBackgroundColor)
            .cornerRadius(10)
        }
    }

    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.9) : Color.white
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)
    }
}

struct PuffButton: View {
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
            HStack {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                Text("ADD PUFF")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.red)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
    }
}

struct StatCard: View {
    let value: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 24))
                Spacer()
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(15)
        }
    }
}

#Preview {
    ContentView()
}
