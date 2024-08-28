//
//  ViewModel.swift
//  PuffTrackReal
//
//  Created by Kaan Şenol on 28.08.2024.
//

import Foundation
import Foundation
import Combine

class PuffTrackViewModel: ObservableObject {
    @Published private var model: PuffTrackData
    @Published var withdrawalStatus: String = ""
    @Published var withdrawalDescription: String = ""
    @Published var streak: Int = 0
    @Published var moneySaved: Double = 0
    @Published var vapeDuration: Double = 0
    @Published var milestones: [Milestone] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init(model: PuffTrackData = PuffTrackData()) {
        self.model = model
        setupMilestones()
        setupBindings()
        updateCalculations()
    }
    
    private func setupMilestones() {
        milestones = [
            Milestone(days: 1, title: "24 Hours Free", description: "You've made it through the first day!"),
            Milestone(days: 3, title: "3-Day Challenge", description: "You've overcome the toughest part!"),
            Milestone(days: 7, title: "One Week Wonder", description: "A full week without vaping!"),
            Milestone(days: 30, title: "Monthly Marvel", description: "30 days of freedom!"),
            Milestone(days: 90, title: "Quarterly Queen/King", description: "You're on your way to a new life!"),
            Milestone(days: 365, title: "Year of Triumph", description: "A full year vape-free! Incredible!")
        ]
    }
    
    
    var puffCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return model.puffCounts.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) })?.count ?? 0
    }
    
    var lastPuffTime: Date {
        model.puffCounts.sorted { $0.date > $1.date }.first?.date ?? Date()
    }
    var hoursSinceLastPuff: Int {
        let timeInterval = -lastPuffTime.timeIntervalSinceNow
        return Int(timeInterval / 3600)
    }
    

    
    var settings: UserSettings {
        model.settings
    }
    
    func addPuff() {
        model.addPuff()
        objectWillChange.send()  // Ensure the UI updates
        updateCalculations()
    }
    
    func updateSettings(vapeCost: Double, puffsPerVape: Int, monthlySpending: Double) {
        model.settings = UserSettings(vapeCost: vapeCost, puffsPerVape: puffsPerVape, monthlySpending: monthlySpending)
    }
    
    private func setupBindings() {
        model.$puffCounts
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
        streak = CalculationEngine.calculateStreak(puffCounts: model.puffCounts)
        
        let withdrawalInfo = CalculationEngine.calculateWithdrawalStatus(lastPuffTime: lastPuffTime)
        withdrawalStatus = withdrawalInfo.status
        withdrawalDescription = withdrawalInfo.description
        
        let financials = CalculationEngine.calculateFinancials(puffCounts: model.puffCounts, settings: model.settings)
        moneySaved = financials.moneySaved
        vapeDuration = financials.vapeDuration
        
        updateMilestones()
    }
    
    private func updateMilestones() {
        for i in 0..<milestones.count {
            milestones[i].isAchieved = streak >= milestones[i].days
        }
    }
}

