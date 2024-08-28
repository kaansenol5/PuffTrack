//
//  CalculationEngine.swift
//  PuffTrackReal
//
//  Created by Kaan Şenol on 28.08.2024.
//

import Foundation
import Foundation

class CalculationEngine {
    static func calculateStreak(puffCounts: [DailyPuffCount]) -> Int {
        let sortedCounts = puffCounts.sorted { $0.date > $1.date }
        guard let lastPuffDate = sortedCounts.first?.date else { return 0 }
        
        let calendar = Calendar.current
        let now = Date()
        let daysSinceLastPuff = calendar.dateComponents([.day], from: lastPuffDate, to: now).day ?? 0
        
        return daysSinceLastPuff
    }
    
    static func calculateWithdrawalStatus(lastPuffTime: Date) -> (status: String, description: String) {
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
    static func calculateFinancials(puffCounts: [DailyPuffCount], settings: UserSettings) -> (moneySaved: Double, vapeDuration: Double) {
        let avgPuffsPerDay = calculateAveragePuffsPerDay(puffCounts: puffCounts)
        let dailySpend = settings.monthlySpending / 30
        let newDailySpend = (Double(avgPuffsPerDay) / Double(settings.puffsPerVape)) * settings.vapeCost
        let moneySaved = max(0, dailySpend - newDailySpend) * 30
        let vapeDuration = Double(settings.puffsPerVape) / max(1, avgPuffsPerDay)
        
        return (moneySaved, vapeDuration)
    }
    
    private static func calculateAveragePuffsPerDay(puffCounts: [DailyPuffCount]) -> Double {
        let recentCounts = puffCounts.suffix(30)
        let totalPuffs = recentCounts.reduce(0) { $0 + $1.count }
        return Double(totalPuffs) / Double(max(1, recentCounts.count))
    }
}
