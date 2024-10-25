//
//  WithdrawalTrackerView.swift
//  PuffTrack
//
//  Created by Kaan Şenol on 25.10.2024.
//

import SwiftUI

struct WithdrawalTrackerView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: PuffTrackViewModel
    
    // Animation states
    @State private var pulseAnimation = false
    @State private var showContent = false
    
    // Expansion states
    @State private var expandedSection: Section?
    @State private var currentTipIndex = 0
    
    enum Section: String {
        case timeline = "Withdrawal Timeline"
        case health = "Health Benefits"
        case symptoms = "Managing Symptoms"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                header
                timeCounter
                
                CollapsibleSection(
                    title: Section.timeline.rawValue,
                    isExpanded: expandedSection == .timeline,
                    onTap: { toggleSection(.timeline) }
                ) {
                    timelineContent
                }
                
                CollapsibleSection(
                    title: Section.health.rawValue,
                    isExpanded: expandedSection == .health,
                    onTap: { toggleSection(.health) }
                ) {
                    healthBenefitsContent
                }
                
                CollapsibleSection(
                    title: Section.symptoms.rawValue,
                    isExpanded: expandedSection == .symptoms,
                    onTap: { toggleSection(.symptoms) }
                ) {
                    symptomsContent
                }
                
                // Tips Carousel
                VStack(alignment: .leading) {
                    Text("Tips & Tricks")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(currentPhaseTips) { tip in
                                TipCard(tip: tip)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .padding()
        }
        .background(backgroundColor.ignoresSafeArea())
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            withAnimation {
                pulseAnimation = true
            }
        }
    }
    
    // MARK: - Tip Card View
    
    struct TipCard: View {
        let tip: WithdrawalTip
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: tip.icon)
                    .font(.title2)
                    .foregroundColor(.red)
                
                Text(tip.title)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Text(tip.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: 280)
            .padding()
            .background(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1))
            .cornerRadius(15)
        }
    }
    
    // MARK: - Withdrawal Tip Model
    
    struct WithdrawalTip: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let description: String
        let phase: TimelinePhase
    }
    
    // MARK: - Tips Data
    
    var allTips: [WithdrawalTip] = [
        // Initial Phase Tips
        WithdrawalTip(
            icon: "drop.fill",
            title: "Stay Hydrated",
            description: "Drink plenty of water to help flush out toxins and reduce cravings.",
            phase: .initial
        ),
        WithdrawalTip(
            icon: "lungs.fill",
            title: "Deep Breathing",
            description: "Practice 4-7-8 breathing when cravings hit: inhale for 4, hold for 7, exhale for 8.",
            phase: .initial
        ),
        WithdrawalTip(
            icon: "figure.walk",
            title: "Take a Walk",
            description: "A short 5-minute walk can help reduce immediate cravings and anxiety.",
            phase: .initial
        ),
        
        // Early Phase Tips
        WithdrawalTip(
            icon: "hand.raised.fill",
            title: "5-Minute Rule",
            description: "When a craving hits, wait 5 minutes. Most cravings pass within this time.",
            phase: .early
        ),
        WithdrawalTip(
            icon: "cup.and.saucer.fill",
            title: "Herbal Tea",
            description: "Switch to caffeine-free herbal tea to help manage stress and anxiety.",
            phase: .early
        ),
        WithdrawalTip(
            icon: "mouth.fill",
            title: "Oral Fixation",
            description: "Try sugar-free gum or cinnamon sticks to satisfy oral cravings.",
            phase: .early
        ),
        
        // Moderate Phase Tips
        WithdrawalTip(
            icon: "bed.double.fill",
            title: "Sleep Routine",
            description: "Maintain a consistent sleep schedule to help your body adjust.",
            phase: .moderate
        ),
        WithdrawalTip(
            icon: "face.smiling.fill",
            title: "Support System",
            description: "Reach out to friends or family when you're feeling challenged.",
            phase: .moderate
        ),
        WithdrawalTip(
            icon: "brain.head.profile",
            title: "Mindfulness",
            description: "Practice 2-minute mindfulness sessions throughout the day.",
            phase: .moderate
        ),
        
        // Peak Phase Tips
        WithdrawalTip(
            icon: "arrow.up.heart.fill",
            title: "Physical Activity",
            description: "Exercise can help reduce withdrawal symptoms and improve mood.",
            phase: .peak
        ),
        WithdrawalTip(
            icon: "pencil",
            title: "Journal",
            description: "Write down your triggers and how you overcome them.",
            phase: .peak
        ),
        WithdrawalTip(
            icon: "clock.fill",
            title: "Time Boxing",
            description: "Break your day into manageable chunks and celebrate small wins.",
            phase: .peak
        ),
        
        // Recovery Phase Tips
        WithdrawalTip(
            icon: "leaf.fill",
            title: "New Habits",
            description: "Replace vaping triggers with healthy alternatives you enjoy.",
            phase: .recovery
        ),
        WithdrawalTip(
            icon: "chart.bar.fill",
            title: "Track Progress",
            description: "Monitor your improvements in breathing, taste, and energy levels.",
            phase: .recovery
        ),
        WithdrawalTip(
            icon: "star.fill",
            title: "Celebrate Success",
            description: "Reward yourself with the money you've saved from not vaping.",
            phase: .recovery
        )
    ]
    
    private var currentPhaseTips: [WithdrawalTip] {
        allTips.filter { $0.phase == currentPhase }
    }
    

    
    private func toggleSection(_ section: Section) {
        withAnimation(.spring()) {
            expandedSection = expandedSection == section ? nil : section
        }
    }
    
    // MARK: - Supporting Views
    
    struct CollapsibleSection<Content: View>: View {
        let title: String
        let isExpanded: Bool
        let onTap: () -> Void
        let content: () -> Content
        @Environment(\.colorScheme) var colorScheme
        
        var body: some View {
            VStack(spacing: 0) {
                Button(action: onTap) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.05))
                    .cornerRadius(isExpanded ? 15 : 15)
                }
                
                if isExpanded {
                    content()
                        .padding()
                        .background(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.05))
                        .cornerRadius(15)
                        .transition(.opacity.combined(with: .scale))
                }
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 5) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                        .padding(8)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(Circle())
                }
                Spacer()
            }
            
            Text("Withdrawal Progress")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(textColor)
            
            Text(viewModel.withdrawalDescription)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)
        }
    }
    
    private var timeCounter: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                    .frame(width: 200, height: 200)
                
                Circle()
                    .trim(from: 0, to: min(Double(viewModel.hoursSinceLastPuff) / 72.0, 1.0))
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.red, .pink]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))
                
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .opacity(pulseAnimation ? 0.5 : 0)
                    .animation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                VStack(spacing: 5) {
                    Text("\(viewModel.hoursSinceLastPuff)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(textColor)
                    
                    Text("HOURS")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("NICOTINE-FREE")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            if viewModel.hoursSinceLastPuff > 0 {
                Text("Every hour without vaping is a victory 💪")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .padding(.top)
            }
            else if viewModel.hoursSinceLastPuff > 24{
                Text("Every day without vaping is a victory 💪")
                    .font(.subheadline)
                    .foregroundColor(.green)
                    .padding(.top)

            }
            else {
                Text("Take the first step. Your future self will thank you.")
                    .font(.subheadline)
                    .foregroundColor(.red)
                    .padding(.top)
            }
        }
    }
    
    private var timelineContent: some View {
        VStack(alignment: .leading, spacing: 15) {
            ForEach(TimelinePhase.allCases, id: \.rawValue) { phase in
                TimelinePhaseView(
                    phase: phase,
                    isActive: phase == currentPhase,
                    isCompleted: phase.rawValue < currentPhase.rawValue
                )
                .opacity(showContent ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(Double(phase.rawValue) * 0.1), value: showContent)
            }
        }
    }
    
    private var healthBenefitsContent: some View {
        VStack(alignment: .leading, spacing: 15) {
            ForEach(healthBenefits) { benefit in
                HealthBenefitRow(
                    benefit: benefit,
                    hours: viewModel.hoursSinceLastPuff
                )
            }
        }
    }
    
    private var symptomsContent: some View {
        VStack(alignment: .leading, spacing: 15) {
            ForEach(currentSymptoms, id: \.symptom) { symptom in
                SymptomRow(symptomInfo: symptom)
            }
        }
    }
    
// MARK: - Helper Properties
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var currentPhase: TimelinePhase {
        let hours = viewModel.hoursSinceLastPuff
        switch hours {
        case 0...3: return .initial
        case 4...12: return .early
        case 13...24: return .moderate
        case 25...72: return .peak
        default: return .recovery
        }
    }
    
    private var currentSymptoms: [(symptom: String, management: String)] {
        switch currentPhase {
        case .initial:
            return [
                ("Irritability", "Practice deep breathing and mindfulness"),
                ("Anxiety", "Stay hydrated and go for a walk"),
                ("Restlessness", "Keep your hands busy with stress balls or fidget toys")
            ]
        case .early:
            return [
                ("Strong Cravings", "Use nicotine-free alternatives like gum or toothpicks"),
                ("Headaches", "Stay hydrated and get fresh air"),
                ("Difficulty Concentrating", "Take frequent breaks and practice mindfulness")
            ]
        case .moderate:
            return [
                ("Mood Swings", "Practice self-care and reach out to supporters"),
                ("Increased Appetite", "Keep healthy snacks nearby"),
                ("Sleep Issues", "Maintain a regular sleep schedule")
            ]
        case .peak:
            return [
                ("Peak Cravings", "Remember why you started. This is temporary"),
                ("Fatigue", "Get adequate rest and stay active"),
                ("Anxiety", "Practice relaxation techniques")
            ]
        case .recovery:
            return [
                ("Occasional Cravings", "Stay vigilant and maintain healthy habits"),
                ("Improved Energy", "Channel it into exercise and hobbies"),
                ("Better Breathing", "Notice and celebrate your progress")
            ]
        }
    }
}
// MARK: - TimelinePhase
enum TimelinePhase: Int, CaseIterable {
    case initial = 0      // 0-4 hours
    case early = 1        // 4-12 hours
    case moderate = 2     // 13-24 hours
    case peak = 3         // 25-72 hours
    case recovery = 4     // 72+ hours
    
    var title: String {
        switch self {
        case .initial: return "Initial Phase"
        case .early: return "Early Withdrawal"
        case .moderate: return "Moderate Withdrawal"
        case .peak: return "Peak Withdrawal"
        case .recovery: return "Recovery Phase"
        }
    }
    
    var duration: String {
        switch self {
        case .initial: return "0-4 hours"
        case .early: return "4-12 hours"
        case .moderate: return "13-24 hours"
        case .peak: return "25-72 hours"
        case .recovery: return "72+ hours"
        }
    }
}

// MARK: - TimelinePhaseView
struct TimelinePhaseView: View {
    let phase: TimelinePhase
    let isActive: Bool
    let isCompleted: Bool
    
    var body: some View {
        HStack {
            Circle()
                .fill(isCompleted ? Color.green : (isActive ? Color.red : Color.gray))
                .frame(width: 20, height: 20)
                .overlay(
                    Group {
                        if isCompleted {
                            Image(systemName: "checkmark")
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                    }
                )
            
            VStack(alignment: .leading) {
                Text(phase.title)
                    .font(.headline)
                Text(phase.duration)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}

// MARK: - HealthBenefit Model
struct HealthBenefit: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let timeInHours: Int
}

let healthBenefits = [
    HealthBenefit(
        title: "Heart Rate Normalization",
        description: "Your heart rate begins to drop to normal levels",
        timeInHours: 24
    ),
    HealthBenefit(
        title: "Oxygen Levels Improve",
        description: "Blood oxygen levels increase to normal",
        timeInHours: 48
    ),
    HealthBenefit(
        title: "Nicotine Elimination",
        description: "Nicotine is eliminated from your body",
        timeInHours: 72
    ),
    HealthBenefit(
        title: "Taste and Smell",
        description: "Your senses of taste and smell begin to improve",
        timeInHours: 96
    )
]

// MARK: - HealthBenefitRow
struct HealthBenefitRow: View {
    let benefit: HealthBenefit
    let hours: Int
    @State private var showProgress = false
    
    var progress: Double {
        min(Double(hours) / Double(benefit.timeInHours), 1.0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(benefit.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(progress >= 1.0 ? .green : .gray)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.red, .pink]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (showProgress ? progress : 0), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
            
            Text(benefit.description)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                showProgress = true
            }
        }
    }
}

// MARK: - SymptomRow
struct SymptomRow: View {
    let symptomInfo: (symptom: String, management: String)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(symptomInfo.symptom)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Text(symptomInfo.management)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}


#Preview {
    WithdrawalTrackerView(viewModel: PuffTrackViewModel())
}
