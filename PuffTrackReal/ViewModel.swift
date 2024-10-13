//
//  ViewModel.swift
//  PuffTrackReal
//
//  Created by Kaan Şenol on 28.08.2024.
//

import Foundation
import Combine
import UserNotifications

class PuffTrackViewModel: ObservableObject {
    @Published var model: PuffTrackData
    @Published var withdrawalStatus: String = ""
    @Published var withdrawalDescription: String = ""
    @Published var streak: Int = 0
    @Published var moneySaved: Double = 0
    @Published var vapeDuration: Double = 0
    @Published var milestones: [Milestone] = []
    @Published var notificationsEnabled: Bool = false {
        didSet {
            if notificationsEnabled {
                requestNotificationPermission()
            } else {
                cancelAllNotifications()
            }
        }
    }

    private var cancellables = Set<AnyCancellable>()
    
    init(model: PuffTrackData = PuffTrackData()) {
        self.model = model
        setupMilestones()
        setupBindings()
        updateCalculations()
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            DispatchQueue.main.async {
                self.notificationsEnabled = granted
                if granted {
                    self.scheduleNotifications()
                }
            }
        }
    }

    func scheduleNotifications() {
        cancelAllNotifications()
        
        // Schedule daily motivation notification
        scheduleDailyInsightNotification()
        
        // Schedule milestone notifications
        for milestone in milestones where !milestone.isAchieved {
            scheduleMilestoneNotification(for: milestone)
        }
    }

    private let dailyInsights = [
        "Drink less coffee to reduce cravings",
        "Stay hydrated throughout the day",
        "Practice deep breathing exercises",
        "Go for a short walk when you feel the urge to vape",
        "Try chewing sugar-free gum as a distraction",
        "Meditate for 5 minutes to reduce stress",
        "Call a friend for support when you're struggling",
        "Eat more fruits and vegetables for better overall health",
        "Get at least 7 hours of sleep each night",
        "Exercise regularly to boost your mood",
        "Try a new hobby to keep your hands busy",
        "Avoid alcohol as it can trigger cravings",
        "Practice positive self-talk and affirmations",
        "Reward yourself for each day without vaping",
        "Keep a journal to track your progress and feelings",
        "Spend time in nature to reduce stress",
        "Try aromatherapy with calming scents like lavender",
        "Practice good posture to improve breathing",
        "Listen to calming music when you feel stressed",
        "Eat smaller, more frequent meals to stabilize blood sugar",
        "Try yoga or stretching to relax your body",
        "Use a stress ball or fidget toy when you have cravings",
        "Practice mindfulness in your daily activities",
        "Limit screen time before bed for better sleep",
        "Try progressive muscle relaxation techniques",
        "Engage in creative activities like drawing or writing",
        "Spend quality time with pets for emotional support",
        "Take a warm bath to relax in the evening",
        "Practice gratitude by listing things you're thankful for",
        "Try herbal tea instead of caffeinated drinks"
    ]
    private func scheduleDailyInsightNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Insight"
        content.body = dailyInsights.randomElement() ?? "Stay strong on your journey!"
        
        var dateComponents = DateComponents()
        dateComponents.hour = 9 // Set to 9 AM, adjust as needed
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "dailyInsight", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleMilestoneNotification(for milestone: Milestone) {
        let content = UNMutableNotificationContent()
        content.title = "Milestone Alert!"
        content.body = "You're approaching the '\(milestone.title)' milestone. Keep going!"
        
        let daysUntilMilestone = milestone.days - streak
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(daysUntilMilestone * 24 * 60 * 60), repeats: false)
        
        let request = UNNotificationRequest(identifier: "milestone-\(milestone.id)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    private func setupMilestones() {
        milestones = [
            Milestone(days: 1, title: "24 Hours Free", description: "You've made it through the first day!"),
            Milestone(days: 3, title: "3-Day Challenge", description: "You've overcome the toughest part!"),
            Milestone(days: 7, title: "One Week Wonder", description: "A full week vape-free!"),
            Milestone(days: 14, title: "Fortnight Freedom", description: "Two weeks without vaping!"),
            Milestone(days: 30, title: "Monthly Marvel", description: "30 days of freedom!"),
            Milestone(days: 60, title: "60-Day Milestone", description: "Two months vape-free! You're making incredible progress!")
        ]
    }
    var puffCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return CalculationEngine.getPuffCountForDate(today, puffs: model.puffs)
    }
    
    var lastPuffTime: Date {
        model.puffs.map { $0.timestamp }.max() ?? Date()
    }

    var hoursSinceLastPuff: Int {
        let timeInterval = -lastPuffTime.timeIntervalSinceNow
        return Int(timeInterval / 3600)
    }
    
    var settings: UserSettings {
        model.settings
    }
    
    func addPuff(socialsViewModel: SocialsViewModel) {
        model.addPuff(socialsViewModel: socialsViewModel)
        objectWillChange.send()  // Ensure the UI updates
        updateCalculations()
    }
    
    func updateSettings(vapeCost: Double, puffsPerVape: Int, monthlySpending: Double, dailyPuffLimit: Int) {
        model.settings = UserSettings(vapeCost: vapeCost, puffsPerVape: puffsPerVape, monthlySpending: monthlySpending, dailyPuffLimit: dailyPuffLimit)
    }
    
    private func setupBindings() {
        model.$puffs
            .sink { [weak self] _ in
                self?.updateCalculations()
            }
            .store(in: &cancellables)
        
        model.$settings
            .sink { [weak self] _ in
                self?.updateCalculations()
            }
            .store(in: &cancellables)
    }
    
    private func updateCalculations() {
        streak = CalculationEngine.calculateStreak(puffs: model.puffs)
        
        let withdrawalInfo = CalculationEngine.calculateWithdrawalStatus(puffs: model.puffs)
        withdrawalStatus = withdrawalInfo.status
        withdrawalDescription = withdrawalInfo.description
        
        let financials = CalculationEngine.calculateFinancials(puffs: model.puffs, settings: model.settings)
        moneySaved = financials.moneySaved
        vapeDuration = financials.vapeDuration
        
        if notificationsEnabled {
            scheduleNotifications()
        }
        updateMilestones()
    }
    
    private func updateMilestones() {
        for i in 0..<milestones.count {
            milestones[i].isAchieved = streak >= milestones[i].days
        }
    }
}
