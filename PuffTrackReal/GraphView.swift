//
//  GraphView.swift
//  PuffTrack
//
//  Created by Kaan Şenol on 26.10.2024.
//

//
//  GraphView.swift
//  PuffTrackReal
//

import SwiftUI

struct GraphView: View {
    @ObservedObject var viewModel: PuffTrackViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTimeRange = TimeRange.week
    
    enum TimeRange {
        case day, week, month
        
        var days: Int {
            switch self {
            case .day: return 1
            case .week: return 7
            case .month: return 30
            }
        }
        
        var title: String {
            switch self {
            case .day: return "Day"
            case .week: return "Week"
            case .month: return "Month"
            }
        }
    }


    private var maxValue: Int {
        let max = chartData.map { $0.1 }.max() ?? 0
        return max > 0 ? max : 10  // Use 10 as minimum max value to show proper scaling when all values are 0
    }

    private var chartData: [(Date, Int)] {
        let calendar = Calendar.current
        let today = Date()
        
        switch selectedTimeRange {
        case .day:
            // Show last 24 hours in 4-hour intervals
            return (0..<6).map { interval in
                let date = calendar.date(byAdding: .hour, value: -(interval * 4), to: today)!
                let count = viewModel.model.puffs.filter {
                    calendar.isDate($0.timestamp, equalTo: date, toGranularity: .hour) ||
                    calendar.isDate($0.timestamp, equalTo: date, toGranularity: .hour) ||
                    calendar.isDate($0.timestamp, equalTo: date, toGranularity: .hour) ||
                    calendar.isDate($0.timestamp, equalTo: date, toGranularity: .hour)
                }.count
                return (date, count)
            }.reversed()
            
        case .week:
            // Daily data for the week
            return (0..<7).map { dayOffset in
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
                let count = CalculationEngine.getPuffCountForDate(date, puffs: viewModel.model.puffs)
                return (date, count)
            }.reversed()
            
        case .month:
            // Show data by 3-day intervals for the month
            return (0..<10).map { interval in
                let startDate = calendar.date(byAdding: .day, value: -(interval * 3), to: today)!
                var totalCount = 0
                for dayOffset in 0..<3 {
                    let date = calendar.date(byAdding: .day, value: -dayOffset, to: startDate)!
                    totalCount += CalculationEngine.getPuffCountForDate(date, puffs: viewModel.model.puffs)
                }
                return (startDate, totalCount)
            }.reversed()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        switch selectedTimeRange {
        case .day:
            formatter.dateFormat = "HH:mm"
        case .week, .month:
            formatter.dateFormat = "MM/dd"
        }
        return formatter.string(from: date)
    }
    private var hasData: Bool {
        !viewModel.model.puffs.isEmpty
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    timeRangePicker
                    
                    statsCards
                    
                    graphCard
                    
                    trendAnalysis
                }
                .padding()
            }
            .background(backgroundColor.edgesIgnoringSafeArea(.all))
            .navigationTitle("Puff Analytics")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private var timeRangePicker: some View {
        HStack {
            ForEach([TimeRange.day, .week, .month], id: \.days) { range in
                Button(action: {
                    withAnimation {
                        selectedTimeRange = range
                    }
                }) {
                    Text(range.title)
                        .font(.headline)
                        .foregroundColor(selectedTimeRange == range ? .white : .gray)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(selectedTimeRange == range ? Color.red : Color.clear)
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var statsCards: some View {
        HStack(spacing: 15) {
            StatBox(title: "Average", value: "\(averagePuffs)", subtitle: "puffs/day")
            StatBox(title: "Highest", value: "\(maxPuffs)", subtitle: "puffs/day")
        }
    }
    
    private var graphCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geometry in
                ZStack {
                    // Background grid
                    VStack(spacing: geometry.size.height / 4) {
                        ForEach(0..<4) { _ in
                            Divider()
                                .background(Color.gray.opacity(0.2))
                        }
                    }
                    
                    // Line Chart
                    Path { path in
                        let points = chartData.enumerated().map { index, dataPoint -> CGPoint in
                            let x = CGFloat(index) / CGFloat(max(chartData.count - 1, 1)) * geometry.size.width
                            let y = geometry.size.height - (CGFloat(dataPoint.1) / CGFloat(max(maxValue, 1))) * geometry.size.height
                            return CGPoint(x: x, y: y)
                        }
                        
                        if let firstPoint = points.first {
                            path.move(to: firstPoint)
                            for index in 1..<points.count {
                                let point = points[index]
                                let control1 = CGPoint(
                                    x: points[index-1].x + (point.x - points[index-1].x) / 2,
                                    y: points[index-1].y
                                )
                                let control2 = CGPoint(
                                    x: points[index-1].x + (point.x - points[index-1].x) / 2,
                                    y: point.y
                                )
                                path.addCurve(to: point, control1: control1, control2: control2)
                            }
                        }
                    }
                    .stroke(Color.red, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    
                    // Data Points with labels
                    ForEach(Array(chartData.enumerated()), id: \.offset) { index, dataPoint in
                        VStack(spacing: 4) {
                            // Data label
                            Text("\(dataPoint.1)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            
                            // Data point
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            
                            // Date label
                            Text(formatDate(dataPoint.0))
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .position(
                            x: CGFloat(index) / CGFloat(max(chartData.count - 1, 1)) * geometry.size.width,
                            y: geometry.size.height - (CGFloat(dataPoint.1) / CGFloat(max(maxValue, 1))) * geometry.size.height
                        )
                    }
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(15)
    }


    private var trendAnalysis: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Trend Analysis")
                .font(.headline)
                .foregroundColor(textColor)
            
            Text(trendDescription)
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBackgroundColor)
        .cornerRadius(15)
    }
    
    private var averagePuffs: Int {
        guard !chartData.isEmpty else { return 0 }
        let sum = chartData.reduce(0) { $0 + $1.1 }
        return sum / chartData.count
    }

    private var maxPuffs: Int {
        chartData.map { $0.1 }.max() ?? 0
    }

    private var trendDescription: String {
        guard hasData else {
            return "Start tracking your puffs to see trends and insights."
        }
        let trend = calculateTrend()
        if trend > 0 {
            return "Your puff count is trending upward. Consider setting a lower daily limit."
        } else if trend < 0 {
            return "Great job! Your puff count is trending downward."
        } else {
            return "Your puff count has been steady. Set new goals to reduce it further."
        }
    }
    private func calculateTrend() -> Double {
        guard chartData.count > 1 else { return 0 }
        let firstHalf = chartData.prefix(chartData.count / 2).map { $0.1 }
        let secondHalf = chartData.suffix(chartData.count / 2).map { $0.1 }
        let firstAvg = Double(firstHalf.reduce(0, +)) / Double(firstHalf.count)
        let secondAvg = Double(secondHalf.reduce(0, +)) / Double(secondHalf.count)
        return secondAvg - firstAvg
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.05)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 24, weight: .bold))
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
}

#Preview {
    GraphView(viewModel: PuffTrackViewModel())
}
