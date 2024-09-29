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
    let date: Date
    var count: Int
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
        let today = Calendar.current.startOfDay(for: Date())
        if let index = puffCounts.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            puffCounts[index].count += 1
        } else {
            puffCounts.append(DailyPuffCount(id: UUID(), date: today, count: 1))
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
