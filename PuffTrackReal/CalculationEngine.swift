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
        var streak = 0
        let today = Calendar.current.startOfDay(for: Date())
        
        for count in sortedCounts {
            if count.count == 0 {
                streak += 1
            } else {
                break
            }
            
            if !Calendar.current.isDateInYesterday(count.date) && count.date != today {
                break
            }
        }
        
        return streak
    }
    
    static func calculateWithdrawalStatus(lastPuffTime: Date) -> (status: String, tip: String) {
        let hoursSinceLastPuff = Int(-lastPuffTime.timeIntervalSinceNow / 3600)
        switch hoursSinceLastPuff {
        case 0...2:
            return ("Craving Nicotine", "Try deep breathing exercises to manage cravings.")
        case 3...5:
            return ("Mild Withdrawal", "Stay hydrated and consider a short walk to distract yourself.")
        case 6...12:
            return ("Moderate Withdrawal", "You're doing great! Consider calling a friend for support.")
        case 13...24:
            return ("Peak Withdrawal", "The worst is almost over. Treat yourself to something nice.")
        default:
            return ("Recovery in Progress", "Your body is healing. Keep up the excellent work!")
        }
    }
    
    static func calculateFinancials(puffCounts: [DailyPuffCount], settings: UserSettings) -> (moneySaved: Double, vapeDuration: Double) {
        let avgPuffsPerDay = calculateAveragePuffsPerDay(puffCounts: puffCounts)
        let dailySpend = settings.monthlySpending / 30
        let newDailySpend = (Double(avgPuffsPerDay) / Double(settings.puffsPerVape)) * settings.vapeCost
        let moneySaved = max(0, dailySpend - newDailySpend)
        let vapeDuration = Double(settings.puffsPerVape) / max(1, avgPuffsPerDay)
        
        return (moneySaved, vapeDuration)
    }
    
    private static func calculateAveragePuffsPerDay(puffCounts: [DailyPuffCount]) -> Double {
        let recentCounts = puffCounts.suffix(30)
        let totalPuffs = recentCounts.reduce(0) { $0 + $1.count }
        return Double(totalPuffs) / Double(max(1, recentCounts.count))
    }
}
