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
                value: String(format: "$%.2f", viewModel.settings.monthlySpending),
                icon: "dollarsign.circle.fill",
                color: .red,
                gradient: [Color.red, Color.orange]
            ),
            StatMetric(
                title: "Current Monthly Spend",
                value: String(format: "$%.2f", viewModel.settings.monthlySpending - viewModel.moneySaved),
                icon: "creditcard.fill",
                color: .green,
                gradient: [Color.green, Color.mint]
            ),
            StatMetric(
                title: "Monthly Savings",
                value: String(format: "$%.2f", viewModel.moneySaved),
                icon: "arrow.down.circle.fill",
                color: .blue,
                gradient: [Color.blue, Color.cyan]
            ),
            StatMetric(
                title: "Yearly Savings Projection",
                value: String(format: "$%.2f", viewModel.moneySaved * 12),
                icon: "chart.line.uptrend.xyaxis.circle.fill",
                color: .purple,
                gradient: [Color.purple, Color.indigo]
            )
        ]
    }
    
    private var vapeMetrics: [StatMetric] {
        var vapeAmount = viewModel.model.puffs.count / viewModel.settings.puffsPerVape
        if(vapeAmount < 1){
            vapeAmount = 1
        }
        let puffsLeft = (viewModel.settings.puffsPerVape * vapeAmount) - (viewModel.puffCount % viewModel.settings.puffsPerVape)
        let averageDailyPuffs = Double(viewModel.puffCount) / max(1.0, Double(viewModel.streak))
        let daysUntilEmpty = Double(puffsLeft) / max(1.0, averageDailyPuffs)
        let lifetimePuffs = viewModel.model.puffs.count
        let averageCostPerPuff = viewModel.settings.vapeCost / Double(viewModel.settings.puffsPerVape)
        
        return [
            StatMetric(
                title: "Estimated Puffs Left",
                value: "\(puffsLeft)",
                icon: "lungs.fill",
                color: .orange,
                gradient: [Color.orange, Color.yellow]
            ),
            StatMetric(title: "Vapes Bought", value: "\(vapeAmount)", icon: "circle.fill", color: .red, gradient: [Color.red, Color.pink]),
            StatMetric(
                title: "Days Until Empty",
                value: String(format: "%.1f days", daysUntilEmpty),
                icon: "clock.fill",
                color: .red,
                gradient: [Color.red, Color.pink]
            ),
            StatMetric(
                title: "Cost Per Puff",
                value: String(format: "$%.3f", averageCostPerPuff),
                icon: "atom.circle.fill",
                color: .indigo,
                gradient: [Color.indigo, Color.purple]
            ),
            StatMetric(
                title: "Average Daily Puffs",
                value: String(format: "%.1f", averageDailyPuffs),
                icon: "waveform.path.ecg.rectangle.fill",
                color: .pink,
                gradient: [Color.pink, Color.red]
            ),
            StatMetric(
                title: "Total Puffs in 30 Days",
                value: "\(lifetimePuffs)",
                icon: "number.circle.fill",
                color: .gray,
                gradient: [Color.gray, Color.gray.opacity(0.6)]
            ),
            StatMetric(
                title: "Puff Reduction",
                value: "\(calculatePuffReduction())%",
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
                title: "Vapes Saved",
                value: String(format: "%.1f", calculateVapesSaved()),
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
                    vapeStatsSection
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
    
    private var vapeStatsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Vape Statistics")
                .font(.headline)
                .foregroundColor(.red)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                ForEach(vapeMetrics.indices, id: \.self) { index in
                    StatisticsCard(metric: vapeMetrics[index])
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
    private func calculatePuffReduction() -> Int {
        let previousAverage = viewModel.settings.monthlySpending / viewModel.settings.vapeCost * Double(viewModel.settings.puffsPerVape) / 30
        let currentAverage = Double(viewModel.puffCount)
        let reduction = ((previousAverage - currentAverage) / previousAverage * 100).rounded()
        return max(0, Int(reduction))
    }
    
    private func calculateVapesSaved() -> Double {
        let expectedVapes = viewModel.settings.monthlySpending / viewModel.settings.vapeCost
        let actualVapes = Double(viewModel.puffCount) / Double(viewModel.settings.puffsPerVape)
        return max(0, expectedVapes - actualVapes)
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
