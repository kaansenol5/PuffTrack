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
    @Published var withdrawalTip: String = ""
    @Published var streak: Int = 0
    @Published var moneySaved: Double = 0
    @Published var vapeDuration: Double = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    init(model: PuffTrackData = PuffTrackData()) {
        self.model = model
        setupBindings()
        updateCalculations()
    }
    
    var puffCount: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return model.puffCounts.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) })?.count ?? 0
    }
    
    var lastPuffTime: Date {
        model.puffCounts.sorted { $0.date > $1.date }.first?.date ?? Date()
    }
    
    var settings: UserSettings {
        model.settings
    }
    
    func addPuff() {
        model.addPuff()
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
        withdrawalTip = withdrawalInfo.tip
        
        let financials = CalculationEngine.calculateFinancials(puffCounts: model.puffCounts, settings: model.settings)
        moneySaved = financials.moneySaved
        vapeDuration = financials.vapeDuration
    }
}

