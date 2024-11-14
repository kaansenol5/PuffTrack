//
//  PuffTrackWidget.swift
//  PuffTrackWidget
//
//  Created by Kaan Şenol on 15.11.2024.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> WidgetEntry {
        WidgetEntry(date: Date(), data: WidgetData(hoursSinceLastPuff: 14, puffsToday: 34, dailyLimit: 60, streak: 3))
    }

    func getSnapshot(in context: Context, completion: @escaping (WidgetEntry) -> ()) {
        let entry = WidgetEntry(
            date: Date(),
            data: WidgetDataManager.shared.getWidgetData() ??
                  WidgetData(hoursSinceLastPuff: 14, puffsToday: 34, dailyLimit: 60, streak: 3)
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        
        let entry = WidgetEntry(
            date: currentDate,
            data: WidgetDataManager.shared.getWidgetData() ??
                  WidgetData(hoursSinceLastPuff: 14, puffsToday: 34, dailyLimit: 60, streak: 3)
        )
        
        let timeline = Timeline(entries: [entry], policy: .after(refreshDate))
        completion(timeline)
    }
}

struct WidgetEntry: TimelineEntry {
    let date: Date
    let data: WidgetData
}

struct PuffTrackWidgetEntryView : View {
   var entry: Provider.Entry
   @Environment(\.colorScheme) var colorScheme
   
   var body: some View {
       ZStack {
           ContainerRelativeShape()
               .fill(colorScheme == .dark ? Color.black : Color.white)
           
           VStack(spacing: 0) {
               // Main ring progress
               ZStack {
                   // Background ring
                   Circle()
                       .trim(from: 0, to: 1)
                       .stroke(
                           colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.1),
                           lineWidth: 6
                       )
                   
                   // Progress ring
                   Circle()
                       .trim(from: 0, to: min(CGFloat(entry.data.hoursSinceLastPuff) / 24.0, 1.0))
                       .stroke(
                           LinearGradient(
                               colors: [Color.red, Color.red.opacity(0.7)],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing
                           ),
                           style: StrokeStyle(lineWidth: 6, lineCap: .round)
                       )
                       .rotationEffect(.degrees(-90))
                   
                   // Center content
                   VStack(spacing: 2) {
                       Text("\(entry.data.hoursSinceLastPuff)")
                           .font(.system(size: 28, weight: .semibold, design: .rounded))
                           .foregroundColor(colorScheme == .dark ? .white : .black)
                       Text("hrs")
                           .font(.system(size: 12, weight: .medium))
                           .foregroundColor(.gray)
                   }
               }
               .frame(width: 90, height: 90)
               .padding(.bottom, 8)
               
               // Bottom stats
               HStack(spacing: 20) {
                   VStack(spacing: 2) {
                       Text("\(entry.data.puffsToday)/\(entry.data.dailyLimit)")
                           .font(.system(size: 14, weight: .semibold))
                           .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.9))
                       Text("today")
                           .font(.system(size: 10, weight: .medium))
                           .foregroundColor(.gray)
                   }
                   
                   VStack(spacing: 2) {
                       Text("🔥 \(entry.data.streak)")
                           .font(.system(size: 14, weight: .semibold))
                           .foregroundColor(colorScheme == .dark ? .white.opacity(0.9) : .black.opacity(0.9))
                       Text("streak")
                           .font(.system(size: 10, weight: .medium))
                           .foregroundColor(.gray)
                   }
               }
           }
           .padding()
       }
       .containerBackground(.clear, for: .widget)
   }
}
@main
struct PuffTrackWidget: Widget {
    let kind: String = "PuffTrackWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PuffTrackWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Puff Track")
        .description("Track your daily progress")
        .supportedFamilies([.systemSmall])
    }
}
struct PuffTrackWidget_Previews: PreviewProvider {
    static var previews: some View {
        PuffTrackWidgetEntryView(entry: WidgetEntry(
            date: Date(),
            data: WidgetData(
                hoursSinceLastPuff: 14,
                puffsToday: 34,
                dailyLimit: 60,
                streak: 3
            )
        ))
        .previewContext(WidgetPreviewContext(family: .systemSmall))
        
        // Dark mode preview
        PuffTrackWidgetEntryView(entry: WidgetEntry(
            date: Date(),
            data: WidgetData(
                hoursSinceLastPuff: 14,
                puffsToday: 34,
                dailyLimit: 60,
                streak: 3
            )
        ))
        .previewContext(WidgetPreviewContext(family: .systemSmall))
        .environment(\.colorScheme, .dark)
        
        // Zero state preview
        PuffTrackWidgetEntryView(entry: WidgetEntry(
            date: Date(),
            data: WidgetData(
                hoursSinceLastPuff: 0,
                puffsToday: 0,
                dailyLimit: 30,
                streak: 0
            )
        ))
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
