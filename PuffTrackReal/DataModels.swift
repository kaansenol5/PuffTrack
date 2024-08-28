//
//  DataModels.swift
//  PuffTrackReal
//
//  Created by Kaan Şenol on 28.08.2024.
//

import Foundation
import Foundation

struct DailyPuffCount: Codable, Identifiable {
    let id: UUID
    var date: Date
    var count: Int
}

struct Milestone: Identifiable {
    let id = UUID()
    let days: Int
    let title: String
    let description: String
    var isAchieved: Bool = false
}

struct UserSettings: Codable {
    var vapeCost: Double
    var puffsPerVape: Int
    var monthlySpending: Double
}

class PuffTrackData: ObservableObject {
    @Published var puffCounts: [DailyPuffCount] = []
    @Published var settings: UserSettings
    
    init() {
        self.settings = UserSettings(vapeCost: 10.0, puffsPerVape: 600, monthlySpending: 50.0)
        loadData()
    }
    
    func addPuff() {
        let now = Date()
        if let index = puffCounts.firstIndex(where: { Calendar.current.isDateInToday($0.date) }) {
            puffCounts[index].count += 1
            puffCounts[index].date = now  // Update to the exact time of the latest puff
        } else {
            puffCounts.append(DailyPuffCount(id: UUID(), date: now, count: 1))
        }
        saveData()
    }
    
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: "puffCounts") {
            if let decoded = try? JSONDecoder().decode([DailyPuffCount].self, from: data) {
                self.puffCounts = decoded
            }
        }
        
        if let data = UserDefaults.standard.data(forKey: "userSettings") {
            if let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) {
                self.settings = decoded
            }
        }
    }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(puffCounts) {
            UserDefaults.standard.set(encoded, forKey: "puffCounts")
        }
        
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "userSettings")
        }
    }
}
