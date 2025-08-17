//
//  DataModels.swift
//  PuffTrackReal
//
//  Created by Kaan Şenol on 28.08.2024.
//

import Foundation

extension NumberFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter
    }()
    
    static let currencyShort: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 3
        return formatter
    }()
}

extension Double {
    var currencyFormatted: String {
        return NumberFormatter.currency.string(from: NSNumber(value: self)) ?? "¤\(String(format: "%.2f", self))"
    }
    
    var currencyFormattedShort: String {
        return NumberFormatter.currencyShort.string(from: NSNumber(value: self)) ?? "¤\(String(format: "%.3f", self))"
    }
}

extension String {
    static var currencySymbol: String {
        return NumberFormatter.currency.currencySymbol ?? "¤"
    }
    
    static func currencyPlaceholder(for item: String) -> String {
        let symbol = NumberFormatter.currency.currencySymbol ?? "¤"
        return "\(item) (\(symbol))"
    }
}

enum TrackingMode: String, Codable, CaseIterable {
    case vaping = "vaping"
    case cigarettes = "cigarettes"
    
    var displayName: String {
        switch self {
        case .vaping:
            return "Vaping"
        case .cigarettes:
            return "Cigarettes"
        }
    }
    
    var unitName: String {
        switch self {
        case .vaping:
            return "puff"
        case .cigarettes:
            return "cigarette"
        }
    }
    
    var unitNamePlural: String {
        switch self {
        case .vaping:
            return "puffs"
        case .cigarettes:
            return "cigarettes"
        }
    }
}

struct Puff: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    var isSynced: Bool
    let trackingMode: TrackingMode
}

struct UserSettings: Codable {
    var vapeCost: Double
    var puffsPerVape: Int
    var monthlySpending: Double
    var dailyPuffLimit: Int
    var trackingMode: TrackingMode
    
    var costPerUnit: Double {
        switch trackingMode {
        case .vaping:
            return vapeCost / Double(puffsPerVape)
        case .cigarettes:
            return vapeCost / 20.0 // Assuming 20 cigarettes per pack
        }
    }
    
    var unitDisplayName: String {
        return trackingMode.unitName
    }
    
    var unitDisplayNamePlural: String {
        return trackingMode.unitNamePlural
    }
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
        self.settings = UserSettings(vapeCost: 10.0, puffsPerVape: 600, monthlySpending: 50.0, dailyPuffLimit: 30, trackingMode: .vaping)
        loadData()
    }
    
    func addPuff() {
        let newPuff = Puff(id: UUID(), timestamp: Date(), isSynced: false, trackingMode: settings.trackingMode)
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
        // First load settings to know the tracking mode
        if let data = UserDefaults.standard.data(forKey: "userSettings") {
            if let decoded = try? JSONDecoder().decode(UserSettings.self, from: data) {
                self.settings = decoded
            }
        }
        
        // Then load puffs and migrate if needed
        if let data = UserDefaults.standard.data(forKey: "puffs") {
            // Try to decode with new format first
            if let decoded = try? JSONDecoder().decode([Puff].self, from: data) {
                self.puffs = decoded
            } else {
                // If that fails, try legacy format and migrate
                // This handles the case where old puffs don't have trackingMode
                self.puffs = []
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
