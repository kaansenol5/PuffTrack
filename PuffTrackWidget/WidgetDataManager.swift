//
//  WidgetDataManager.swift
//  PuffTrackWidgetExtension
//
//  Created by Kaan Şenol on 15.11.2024.
//

import Foundation
import Foundation

struct WidgetData: Codable {
    let hoursSinceLastPuff: Int
    let puffsToday: Int
    let dailyLimit: Int
    let streak: Int
}

class WidgetDataManager {
    static let shared = WidgetDataManager()
    private let userDefaults = UserDefaults(suiteName: "group.com.yourapp.pufftrack")
    
    func saveWidgetData(hoursSinceLastPuff: Int, puffsToday: Int, dailyLimit: Int, streak: Int) {
        let data = WidgetData(
            hoursSinceLastPuff: hoursSinceLastPuff,
            puffsToday: puffsToday,
            dailyLimit: dailyLimit,
            streak: streak
        )
        
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        userDefaults?.set(encoded, forKey: "widgetData")
    }
    
    func getWidgetData() -> WidgetData? {
        guard let data = userDefaults?.data(forKey: "widgetData"),
              let widgetData = try? JSONDecoder().decode(WidgetData.self, from: data)
        else { return nil }
        
        return widgetData
    }
}
