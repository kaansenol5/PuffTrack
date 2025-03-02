//
//  DataModels.swift
//  PuffTrackReal
//
//  Created by Kaan Şenol on 28.08.2024.
//

import Foundation

struct Puff: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    var isSynced: Bool
}

struct UserSettings: Codable {
    var vapeCost: Double
    var puffsPerVape: Int
    var monthlySpending: Double
    var dailyPuffLimit: Int
}

struct Milestone: Identifiable {
    let id = UUID()
    let days: Int
    let title: String
    let description: String
    var isAchieved: Bool = false
}

class PuffTrackData: ObservableObject {
    @Published var puffs: [Puff] = []
    @Published var settings: UserSettings
    
    init() {
        self.settings = UserSettings(vapeCost: 10.0, puffsPerVape: 600, monthlySpending: 50.0, dailyPuffLimit: 30)
        loadData()
    }
    
    func addPuff() {
        let newPuff = Puff(id: UUID(), timestamp: Date(), isSynced: false)
        puffs.append(newPuff)
        removeOldPuffs()
        saveData()
    }
    
    
    func removeOldPuffs() {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        puffs = puffs.filter { $0.timestamp > thirtyDaysAgo }
        saveData()
    }
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: "puffs") {
            if let decoded = try? JSONDecoder().decode([Puff].self, from: data) {
                self.puffs = decoded
            }
        }
        
        if let data = UserDefaults.standard.data(forKey: "userSettings") {
            if let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) {
                self.settings = decoded
            }
        }
    }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(puffs) {
            UserDefaults.standard.set(encoded, forKey: "puffs")
        }
        
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: "userSettings")
        }
    }
    
    func getPuffCountForDate(_ date: Date) -> Int {
        let calendar = Calendar.current
        return puffs.filter { calendar.isDate($0.timestamp, inSameDayAs: date) }.count
    }
    
}
