struct TrendAnalysis: View {
    @ObservedObject var viewModel: PuffTrackViewModel
    let timeRange: String
    
    private var trend: Double {
        guard chartData.count > 1 else { return 0 }
        let firstHalf = chartData.prefix(chartData.count / 2).map { $0.value }
        let secondHalf = chartData.suffix(chartData.count / 2).map { $0.value }
        let firstAvg = Double(firstHalf.reduce(0, +)) / Double(firstHalf.count)
        let secondAvg = Double(secondHalf.reduce(0, +)) / Double(secondHalf.count)
        return secondAvg - firstAvg
    }
    
    private var trendPercentage: Double {
        let maxCount = chartData.map { $0.value }.max() ?? 0
        return abs(trend * 100 / Double(max(1, maxCount)))
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.05)
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Trend Analysis")
                    .font(.headline)
                    .foregroundColor(textColor)
                
                Spacer()
                
                Text(timeRange)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // 2x2 Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                // Overall Trend Card
                trendCard(
                    icon: trend > 0 ? "arrow.up.right" :
                          trend < 0 ? "arrow.down.right" : "arrow.right",
                    color: trend > 0 ? .red :
                           trend < 0 ? .green : .gray,
                    title: trend > 0 ? "Increasing" :
                           trend < 0 ? "Decreasing" : "Steady",
                    detail: "\(String(format: "%.1f", trendPercentage))%"
                )
                
                // Pattern Card
                let pattern = identifyPattern()
                trendCard(
                    icon: pattern.icon,
                    color: .blue,
                    title: pattern.title,
                    detail: pattern.peak
                )
                
                // Goal Progress Card
                let progress = calculateGoalProgress()
                trendCard(
                    icon: progress.icon,
                    color: progress.color,
                    title: progress.title,
                    detail: progress.value
                )
                
                // Weekly Comparison Card
                let weekComp = calculateWeeklyComparison()
                trendCard(
                    icon: weekComp.trend > 0 ? "arrow.up.circle.fill" :
                          weekComp.trend < 0 ? "arrow.down.circle.fill" : "equal.circle.fill",
                    color: weekComp.trend > 0 ? .red :
                           weekComp.trend < 0 ? .green : .gray,
                    title: "vs Last Week",
                    detail: "\(abs(weekComp.percentage))%"
                )
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .cornerRadius(15)
    }
    
    private func trendCard(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(textColor)
                
                Text(detail)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
    
    private var chartData: [(label: String, value: Int)] {
        viewModel.model.puffs.reduce(into: [:]) { dict, puff in
            let hour = Calendar.current.component(.hour, from: puff.timestamp)
            dict[hour, default: 0] += 1
        }.map { (String($0), $1) }
        .sorted { $0.0 < $1.0 }
    }
    
    private func identifyPattern() -> (icon: String, title: String, peak: String) {
        let hourlyData = chartData
        let morning = hourlyData.filter { Int($0.label) ?? 0 >= 6 && Int($0.label) ?? 0 < 12 }
        let afternoon = hourlyData.filter { Int($0.label) ?? 0 >= 12 && Int($0.label) ?? 0 < 18 }
        let evening = hourlyData.filter { Int($0.label) ?? 0 >= 18 }
        
        let morningSum = morning.reduce(0) { $0 + $1.value }
        let afternoonSum = afternoon.reduce(0) { $0 + $1.value }
        let eveningSum = evening.reduce(0) { $0 + $1.value }
        
        let max = Swift.max(morningSum, afternoonSum, eveningSum)
        
        switch max {
        case morningSum:
            return ("sunrise.fill", "Peak Time", "6-12 AM")
        case afternoonSum:
            return ("sun.max.fill", "Peak Time", "12-6 PM")
        case eveningSum:
            return ("moon.stars.fill", "Peak Time", "6-12 PM")
        default:
            return ("clock.fill", "Peak Time", "All Day")
        }
    }
    
    private func calculateGoalProgress() -> (icon: String, title: String, value: String, color: Color) {
        let percentage = Double(viewModel.puffCount) / Double(viewModel.settings.dailyPuffLimit) * 100
        
        switch percentage {
        case 100...:
            return ("exclamationmark.triangle.fill", "Over Limit", "\(Int(percentage))%", .red)
        case 80...:
            return ("exclamationmark.circle.fill", "Near Limit", "\(Int(percentage))%", .orange)
        case 50...:
            return ("hourglass.bottomhalf.fill", "Halfway", "\(Int(percentage))%", .yellow)
        default:
            return ("checkmark.circle.fill", "On Track", "\(Int(percentage))%", .green)
        }
    }
    
    private func calculateWeeklyComparison() -> (trend: Double, percentage: Int) {
        let calendar = Calendar.current
        let now = Date()
        
        let thisWeekStart = calendar.date(byAdding: .day, value: -7, to: now)!
        let thisWeekPuffs = viewModel.model.puffs.filter { $0.timestamp >= thisWeekStart }
        let thisWeekAvg = Double(thisWeekPuffs.count) / 7.0
        
        let lastWeekStart = calendar.date(byAdding: .day, value: -14, to: thisWeekStart)!
        let lastWeekPuffs = viewModel.model.puffs.filter {
            $0.timestamp >= lastWeekStart && $0.timestamp < thisWeekStart
        }
        let lastWeekAvg = Double(lastWeekPuffs.count) / 7.0
        
        let trend = thisWeekAvg - lastWeekAvg
        let percentage = lastWeekAvg > 0 ? Int((trend / lastWeekAvg) * 100) : 0
        
        return (trend, percentage)
    }
}