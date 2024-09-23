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
    @State private var isSettingsPresented = false
    @State private var isMilestonesPresented = false
    @State private var isFriendsPresented = false
    @State private var isAuthPresented = false  // New state for AuthView presentation

    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            backgroundColor.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 15) {
                headerSection
                puffTracker
                withdrawalTrackerSection
                statsSection
                socialSection
            }
            .padding()
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(viewModel: viewModel)
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
    private var headerSection: some View {
        ZStack {
            HStack {
                Button(action: { isSettingsPresented.toggle() }) {
                    Image(systemName: "gear")
                        .foregroundColor(.red)
                        .imageScale(.large)
                }
                
                Spacer()
                
                Circle()
                    .fill(Color.red)
                    .frame(width: 10, height: 10)
            }
            
            Text("PuffTrack")
                .font(.custom("Futura", size: 24))
                .foregroundColor(textColor)
        }
    }
    
    private var puffTracker: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(180))
                
                Circle()
                    .trim(from: 0, to: min(CGFloat(viewModel.puffCount) / 100, 0.5))
                    .stroke(Color.red, lineWidth: 20)
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(180))
                    .animation(.spring(), value: viewModel.puffCount)
                
                VStack {
                    Text("\(viewModel.puffCount)")
                        .font(.system(size: 50, weight: .bold, design: .rounded))
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
                viewModel.addPuff()
            })
            .position(x: 180, y: -30)
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
            .padding(.horizontal)
            
            HStack(spacing: 15) {
                StatCard(value: "\(viewModel.streak) days", icon: "flame.fill", color: .orange, action: { isMilestonesPresented.toggle() })
                StatCard(value: "$\(String(format: "%.0f", viewModel.moneySaved))", icon: "dollarsign.circle.fill", color: .green, action: {})
            }
        }
    }


    private var socialSection: some View {
        Button(action: {
            if(socialsViewModel.isUserLoggedIn()){
                isFriendsPresented.toggle()
            }
            else{
                isAuthPresented.toggle()
            } }) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Friends")
                    .font(.headline)
                    .foregroundColor(textColor)
                
                ForEach(1...3, id: \.self) { _ in
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 40, height: 50)
                            .overlay(
                                Text("FN") // Placeholder initials
                                    .foregroundColor(.white)
                                    .font(.headline)
                            )
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Friend Name")
                                .foregroundColor(textColor)
                                .font(.headline)
                            Text("15 puffs today")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                        Text("-5%")
                            .foregroundColor(.green)
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

// PuffButton and StatCard remain the same
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
            .frame(minWidth: 200, minHeight: 50)
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
            .frame(maxWidth: .infinity)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(15)
        }
    }
}

#Preview{
    ContentView()
}
