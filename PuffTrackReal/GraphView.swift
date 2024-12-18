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
    @State private var selectedBarIndex: Int? = nil
    
    enum TimeRange: String, CaseIterable {
        case hours = "12H"
        case week = "7D"
        case month = "1M"
    }
    
    private var chartData: [(label: String, value: Int)] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeRange {
        case .hours:
            // 6 bars, 2-hour intervals
            return (0..<6).map { interval in
                let endDate = calendar.date(byAdding: .hour, value: -(interval * 2), to: now)!
                let startDate = calendar.date(byAdding: .hour, value: -2, to: endDate)!
                
                let formatter = DateFormatter()
                formatter.dateFormat = "ha"
                let label = "\(formatter.string(from: startDate))-\(formatter.string(from: endDate))"
                
                let count = viewModel.model.puffs.filter {
                    $0.timestamp >= startDate && $0.timestamp <= endDate
                }.count
                
                return (label, count)
            }.reversed()
            
        case .week:
            // 7 bars, daily
            return (0..<7).map { dayOffset in
                let date = calendar.date(byAdding: .day, value: -dayOffset, to: now)!
                let formatter = DateFormatter()
                formatter.dateFormat = "E"  // "Mon", "Tue", etc.
                let label = formatter.string(from: date)
                let count = CalculationEngine.getPuffCountForDate(date, puffs: viewModel.model.puffs)
                return (label, count)
            }.reversed()
            
        case .month:
            // 4 bars, weekly
            return (0..<4).map { weekOffset in
                let endDate = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now)!
                let startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: endDate)!
                
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM d"
                let label = "\(formatter.string(from: startDate))-\(formatter.string(from: endDate))"
                
                let count = viewModel.model.puffs.filter {
                    $0.timestamp >= startDate && $0.timestamp <= endDate
                }.count
                
                return (label, count)
            }.reversed()
        }
    }
    
    private var maxValue: Int {
        let max = chartData.map { $0.value }.max() ?? 0
        return max > 0 ? max : 10  // Minimum scale of 10 for empty data
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    timeRangePicker
                    statsCards
                    graphCard
                    TrendAnalysis(viewModel: viewModel, timeRange: selectedTimeRange.rawValue)
                }
                .padding()
            }
            .background(backgroundColor.edgesIgnoringSafeArea(.all))
            .navigationTitle("Puff Analytics")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            // Dismiss selected bar when tapping outside
            .onTapGesture {
                selectedBarIndex = nil
            }
        }
    }
    
    private var timeRangePicker: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    withAnimation {
                        selectedTimeRange = range
                        selectedBarIndex = nil
                    }
                }) {
                    Text(range.rawValue)
                        .font(.headline)
                        .foregroundColor(selectedTimeRange == range ? .white : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedTimeRange == range ? Color.red : Color.clear)
                                .animation(.spring(), value: selectedTimeRange)
                        )
                }
            }
        }
        .padding(4)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var graphCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    // Bars
                    HStack(alignment: .bottom, spacing: geometry.size.width * 0.02) {
                        ForEach(Array(chartData.enumerated()), id: \.offset) { index, dataPoint in
                            VStack(spacing: 4) {
                                // Bar
                                Rectangle()
                                    .fill(Color.red.opacity(selectedBarIndex == index ? 0.8 : 0.6))
                                    .frame(height: CGFloat(dataPoint.value) / CGFloat(maxValue) * (geometry.size.height * 0.7))
                                    .animation(.spring(), value: selectedBarIndex)
                                    .onTapGesture {
                                        withAnimation {
                                            selectedBarIndex = selectedBarIndex == index ? nil : index
                                        }
                                    }
                                
                                // Label
                                Text(dataPoint.label)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .fixedSize()
                            }
                            .overlay(
                                Group {
                                    if selectedBarIndex == index {
                                        // Speech balloon popup
                                        Text("\(dataPoint.value)")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                BalloonShape()
                                                    .fill(Color.red)
                                            )
                                            .offset(y: -40)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.bottom, 20)
                }
            }
            .frame(height: 250)
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(15)
    }
    
    private var statsCards: some View {
        HStack(spacing: 15) {
            StatBox(title: "Average", value: "\(averagePuffs)", subtitle: "puffs/\(timeframeUnit)")
            StatBox(title: "Highest", value: "\(maxPuffs)", subtitle: "puffs/\(timeframeUnit)")
        }
    }
    
    private var timeframeUnit: String {
        switch selectedTimeRange {
        case .hours: return "2h"
        case .week: return "day"
        case .month: return "week"
        }
    }
    

    
    // Helper computed properties
    private var averagePuffs: Int {
        guard !chartData.isEmpty else { return 0 }
        let sum = chartData.reduce(0) { $0 + $1.value }
        return sum / chartData.count
    }
    
    private var maxPuffs: Int {
        chartData.map { $0.value }.max() ?? 0
    }
    
    
    // Colors
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

// Custom speech balloon shape
struct BalloonShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Bubble
        let bubbleRect = CGRect(x: 0, y: 0, width: rect.width, height: rect.height - 8)
        let cornerRadius: CGFloat = 8
        path.addRoundedRect(in: bubbleRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        
        // Triangle
        path.move(to: CGPoint(x: rect.width * 0.5 - 6, y: rect.height - 8))
        path.addLine(to: CGPoint(x: rect.width * 0.5, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width * 0.5 + 6, y: rect.height - 8))
        
        return path
    }
}
struct StatBox: View {
    let title: String
    let value: String
    let subtitle: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(colorScheme == .dark ? .white : .black)
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
