import SwiftUI

struct StatisticsView: View {
    @ObservedObject var viewModel: PuffTrackViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @State private var animateCards = false
    
    private var financialMetrics: [StatMetric] {
        [
            StatMetric(
                title: "Previous Monthly Spend",
                value: viewModel.settings.monthlySpending.currencyFormatted,
                icon: "dollarsign.circle.fill",
                color: .red,
                gradient: [Color.red, Color.orange]
            ),
            StatMetric(
                title: "Current Monthly Spend",
                value: (viewModel.settings.monthlySpending - viewModel.moneySaved).currencyFormatted,
                icon: "creditcard.fill",
                color: .green,
                gradient: [Color.green, Color.mint]
            ),
            StatMetric(
                title: "Monthly Savings",
                value: viewModel.moneySaved.currencyFormatted,
                icon: "arrow.down.circle.fill",
                color: .blue,
                gradient: [Color.blue, Color.cyan]
            ),
            StatMetric(
                title: "Yearly Savings Projection",
                value: (viewModel.moneySaved * 12).currencyFormatted,
                icon: "chart.line.uptrend.xyaxis.circle.fill",
                color: .purple,
                gradient: [Color.purple, Color.indigo]
            )
        ]
    }
    
    private var usageMetrics: [StatMetric] {
        let trackingMode = viewModel.settings.trackingMode
        
        var unitAmount = viewModel.model.puffs.count / viewModel.settings.puffsPerVape
        if(unitAmount < 1){
            unitAmount = 1
        }
        let unitsLeft = (viewModel.settings.puffsPerVape * unitAmount) - (viewModel.puffCount % viewModel.settings.puffsPerVape)
        let averageDailyUnits = Double(viewModel.puffCount) / max(1.0, Double(viewModel.streak))
        let daysUntilEmpty = Double(unitsLeft) / max(1.0, averageDailyUnits)
        let lifetimeUnits = viewModel.model.puffs.count
        let averageCostPerUnit = viewModel.settings.vapeCost / Double(viewModel.settings.puffsPerVape)
        
        let unitsLeftTitle = trackingMode == .vaping ? "Estimated Puffs Left" : "Estimated \(trackingMode.unitNamePlural.capitalized) Left"
        let unitsBoughtTitle = trackingMode == .vaping ? "Vapes Bought" : "Packs Bought"
        let costPerUnitTitle = trackingMode == .vaping ? "Cost Per Puff" : "Cost Per \(trackingMode.unitName.capitalized)"
        let averageDailyTitle = trackingMode == .vaping ? "Average Daily Puffs" : "Average Daily \(trackingMode.unitNamePlural.capitalized)"
        let totalTitle = trackingMode == .vaping ? "Total Puffs in 30 Days" : "Total \(trackingMode.unitNamePlural.capitalized) in 30 Days"
        let reductionTitle = trackingMode == .vaping ? "Puff Reduction" : "\(trackingMode.unitName.capitalized) Reduction"
        let unitsSavedTitle = trackingMode == .vaping ? "Vapes Saved" : "Packs Saved"
        
        return [
            StatMetric(
                title: unitsLeftTitle,
                value: "\(unitsLeft)",
                icon: "lungs.fill",
                color: .orange,
                gradient: [Color.orange, Color.yellow]
            ),
            StatMetric(title: unitsBoughtTitle, value: "\(unitAmount)", icon: "circle.fill", color: .red, gradient: [Color.red, Color.pink]),
            StatMetric(
                title: "Days Until Empty",
                value: String(format: "%.1f days", daysUntilEmpty),
                icon: "clock.fill",
                color: .red,
                gradient: [Color.red, Color.pink]
            ),
            StatMetric(
                title: costPerUnitTitle,
                value: averageCostPerUnit.currencyFormattedShort,
                icon: "atom.circle.fill",
                color: .indigo,
                gradient: [Color.indigo, Color.purple]
            ),
            StatMetric(
                title: averageDailyTitle,
                value: String(format: "%.1f", averageDailyUnits),
                icon: "waveform.path.ecg.rectangle.fill",
                color: .pink,
                gradient: [Color.pink, Color.red]
            ),
            StatMetric(
                title: totalTitle,
                value: "\(lifetimeUnits)",
                icon: "number.circle.fill",
                color: .gray,
                gradient: [Color.gray, Color.gray.opacity(0.6)]
            ),
            StatMetric(
                title: reductionTitle,
                value: "\(calculateReduction())%",
                icon: "arrow.down.right.circle.fill",
                color: .green,
                gradient: [Color.green, Color.mint]
            ),
            StatMetric(
                title: "Daily Limit Progress",
                value: "\(viewModel.puffCount)/\(viewModel.settings.dailyPuffLimit)",
                icon: "gauge.with.dots.needle.bottom.50percent",
                color: .blue,
                gradient: [Color.blue, Color.cyan]
            ),
            StatMetric(
                title: unitsSavedTitle,
                value: String(format: "%.1f", calculateUnitsSaved()),
                icon: "leaf.circle.fill",
                color: .teal,
                gradient: [Color.teal, Color.green]
            )
        ]
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    financialStatsSection
                    usageStatsSection
                }
                .padding()
            }
            .background(backgroundColor.edgesIgnoringSafeArea(.all))
            .navigationTitle("Statistics")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animateCards = true
                }
            }
        }
    }
    
    private var financialStatsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Financial Statistics")
                .font(.headline)
                .foregroundColor(.red)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(financialMetrics.indices, id: \.self) { index in
                    StatisticsCard(metric: financialMetrics[index])
                        .offset(y: animateCards ? 0 : 50)
                        .opacity(animateCards ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1),
                                 value: animateCards)
                }
            }
        }
    }
    
    private var usageStatsSection: some View {
        let trackingMode = viewModel.settings.trackingMode
        let sectionTitle = "\(trackingMode.displayName) Statistics"
        
        return VStack(alignment: .leading, spacing: 15) {
            Text(sectionTitle)
                .font(.headline)
                .foregroundColor(.red)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(usageMetrics.indices, id: \.self) { index in
                    StatisticsCard(metric: usageMetrics[index])
                        .offset(y: animateCards ? 0 : 50)
                        .opacity(animateCards ? 1 : 0)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1),
                                 value: animateCards)
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    // Helper calculation functions
    private func calculateReduction() -> Int {
        let previousAverage = viewModel.settings.monthlySpending / viewModel.settings.vapeCost * Double(viewModel.settings.puffsPerVape) / 30
        let currentAverage = Double(viewModel.puffCount)
        let reduction = ((previousAverage - currentAverage) / previousAverage * 100).rounded()
        return max(0, Int(reduction))
    }
    
    private func calculateUnitsSaved() -> Double {
        let expectedUnits = viewModel.settings.monthlySpending / viewModel.settings.vapeCost
        let actualUnits = Double(viewModel.puffCount) / Double(viewModel.settings.puffsPerVape)
        return max(0, expectedUnits - actualUnits)
    }
}

struct StatMetric: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let color: Color
    let gradient: [Color]
}

struct StatisticsCard: View {
    let metric: StatMetric
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = false
                }
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: metric.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: metric.icon)
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .semibold))
                }
                
                Text(metric.value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.7)
                
                Text(metric.title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardBackground)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
            .scaleEffect(isPressed ? 0.95 : 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white
    }
}

#Preview {
    StatisticsView(viewModel: PuffTrackViewModel())
}
