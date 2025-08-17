//
//  ContentView.swift
//  PuffTrackReal
//
//  Created by Kaan Şenol on 3.07.2024.
//
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = PuffTrackViewModel()
    @State private var isSettingsPresented = false
    @State private var isMilestonesPresented = false
    @State private var isStatisticsViewPresented = false
    @State private var isGraphViewPresented = false
    @State private var isWithdrawalTrackerPresented = false
    @Environment(\.colorScheme) var colorScheme
    @State private var onboardingComplete: Bool = UserDefaults.standard.bool(forKey: "onboardingComplete")
    
    var body: some View {
        Group {
            if !onboardingComplete {
                OnboardingView(isOnboardingComplete: $onboardingComplete, viewModel: viewModel)
            } else {
                mainContent
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
                }
                .padding(.horizontal, geometry.size.width * 0.05)
                .padding(.vertical, geometry.size.height * 0.02)
        }
        .onAppear {
        }
        .sheet(isPresented: $isSettingsPresented) {
            SettingsView(viewModel: viewModel)
        }
        .sheet(isPresented: $isStatisticsViewPresented) {
            StatisticsView(viewModel: viewModel)
        }
        .sheet(isPresented: $isWithdrawalTrackerPresented) {
            WithdrawalTrackerView(viewModel: viewModel)
        }
        .sheet(isPresented: $isMilestonesPresented) {
            MilestonesView(viewModel: viewModel)
        }
        .sheet(isPresented: $isGraphViewPresented){
            GraphView(viewModel: viewModel)
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
            }
            
            Text("PuffTrack")
                .font(.custom("Futura", size: 24))
                .foregroundColor(textColor)
        }
    }

    private func puffTracker(size: CGSize) -> some View {
        // Safely handle dailyPuffLimit = 0 by using a fallback of 1
        // (or handle it in any custom way, e.g. show a message if limit=0)
        let safeLimit = max(1, viewModel.model.settings.dailyPuffLimit)
        let ratio = CGFloat(viewModel.puffCount) / CGFloat(safeLimit)
        
        return VStack(spacing: size.height * 0.02) {
            ZStack {
                // Background half-circle
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                    .frame(
                        width: min(size.width * 0.5, size.height * 0.3),
                        height: min(size.width * 0.5, size.height * 0.3)
                    )
                    .rotationEffect(.degrees(180))
                
                // Filled portion
                Circle()
                    .trim(from: 0, to: min(ratio * 0.5, 0.5))   //  ratio * 0.5 ensures half-circle
                    .stroke(Color.red, lineWidth: 20)
                    .frame(
                        width: min(size.width * 0.5, size.height * 0.3),
                        height: min(size.width * 0.5, size.height * 0.3)
                    )
                    .rotationEffect(.degrees(180))
                    .animation(.spring(), value: ratio)
                
                // Center text
                VStack {
                    Text("\(viewModel.puffCount)")
                        .font(.system(
                            size: min(size.width * 0.12, size.height * 0.07),
                            weight: .bold,
                            design: .rounded
                        ))
                        .foregroundColor(textColor)
                    
                    Text(viewModel.settings.unitDisplayNamePlural.uppercased())
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text(hoursSinceLastPuffText)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Buttons row
            HStack(spacing: 15) {
                PuffButton(action: {
                    viewModel.addPuff()
                }, unitName: viewModel.settings.unitDisplayName)
                .frame(width: min(size.width * 0.45, 200))
                
                Button(action: { isGraphViewPresented.toggle() }) {
                    Image(systemName: "chart.xyaxis.line")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.red)
                        .frame(width: 50, height: 50)
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                }
            }
            .frame(width: min(size.width * 0.6, 280))
        }
    }

    private var hoursSinceLastPuffText: String {
        let hours = viewModel.hoursSinceLastPuff
        let unitName = viewModel.settings.unitDisplayName
        if hours < 1 {
            return "Less than an hour since last \(unitName)"
        } else if hours == 1 {
            return "1 hour since last \(unitName)"
        } else {
            return "\(hours) hours since last \(unitName)"
        }
    }

    private var withdrawalTrackerSection: some View {
        Button(action: { isWithdrawalTrackerPresented.toggle() }) {
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
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Text(timeElapsed)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text(viewModel.withdrawalDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .padding(.top, 5)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(15)
        }
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
                    StatCard(value: viewModel.moneySaved.currencyFormatted, icon: "dollarsign.circle.fill", color: .green, action: {isStatisticsViewPresented.toggle()})
                        .frame(width: geometry.size.width / 2 - 7.5)
                }
            }
            .frame(height: 100)
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
    let unitName: String
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
                Text("ADD \(unitName.uppercased())")
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
            .preferredColorScheme(.dark)
    
}
