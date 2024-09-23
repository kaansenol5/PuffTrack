//
//  CalculationEngine.swift
//  PuffTrackReal
//
//  Created by Kaan Şenol on 28.08.2024.
//

import Foundation

class CalculationEngine {
    static func calculateStreak(puffs: [Puff]) -> Int {
        guard let lastPuffDate = puffs.map({ $0.timestamp }).max() else { return 0 }
        
        let calendar = Calendar.current
        let now = Date()
        let daysSinceLastPuff = calendar.dateComponents([.day], from: lastPuffDate, to: now).day ?? 0
        
        return daysSinceLastPuff
    }
    
    static func calculateWithdrawalStatus(puffs: [Puff]) -> (status: String, description: String) {
        guard let lastPuffTime = puffs.map({ $0.timestamp }).max() else {
            return ("No data", "Start tracking your puffs to see your withdrawal status.")
        }
        
        let hoursSinceLastPuff = Int(-lastPuffTime.timeIntervalSinceNow / 3600)
        
        if hoursSinceLastPuff < 4 {
            return ("You are still puffing", "Try to extend the time between puffs.")
        }
        
        switch hoursSinceLastPuff {
        case 4...12:
            return ("Early Withdrawal", "You might experience mild cravings. Stay hydrated and try deep breathing.")
        case 13...24:
            return ("Moderate Withdrawal", "Cravings may intensify. Stay busy and remember why you're quitting.")
        case 25...72:
            return ("Peak Withdrawal", "This is the toughest part. Your body is healing. Stay strong!")
        default:
            return ("Recovery in Progress", "Great job! The worst is over. Keep going!")
        }
    }

    static func calculateFinancials(puffs: [Puff], settings: UserSettings) -> (moneySaved: Double, vapeDuration: Double) {
        let avgPuffsPerDay = calculateAveragePuffsPerDay(puffs: puffs)
        let dailySpend = settings.monthlySpending / 30
        let newDailySpend = (Double(avgPuffsPerDay) / Double(settings.puffsPerVape)) * settings.vapeCost
        let moneySaved = max(0, dailySpend - newDailySpend) * 30
        let vapeDuration = Double(settings.puffsPerVape) / max(1, avgPuffsPerDay)
        
        return (moneySaved, vapeDuration)
    }
    
    private static func calculateAveragePuffsPerDay(puffs: [Puff]) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: now)!
        
        let recentPuffs = puffs.filter { $0.timestamp >= thirtyDaysAgo }
        let uniqueDays = Set(recentPuffs.map { calendar.startOfDay(for: $0.timestamp) }).count
        
        return Double(recentPuffs.count) / Double(max(1, uniqueDays))
    }
    
    static func getPuffCountForDate(_ date: Date, puffs: [Puff]) -> Int {
        let calendar = Calendar.current
        return puffs.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }.count
    }
}
