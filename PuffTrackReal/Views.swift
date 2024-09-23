//
//  Views.swift
//  PuffTrackReal
//
//  Created by Kaan Şenol on 27.08.2024.
//

import Foundation
import SwiftUI

import SwiftUI

import SwiftUI

struct MilestonesView: View {
    @ObservedObject var viewModel: PuffTrackViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(viewModel.milestones) { milestone in
                        MilestoneCard(milestone: milestone)
                    }
                }
                .padding()
            }
            .background(backgroundColor.edgesIgnoringSafeArea(.all))
            .navigationTitle("Milestones")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black.opacity(0.9) : Color.white
    }
}

struct MilestoneCard: View {
    let milestone: Milestone
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(milestone.isAchieved ? Color.red : Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .overlay(
                    Group {
                        if milestone.isAchieved {
                            Image(systemName: "checkmark")
                                .foregroundColor(.white)
                                .font(.system(size: 30, weight: .bold))
                        } else {
                            Text("\(milestone.days)")
                                .foregroundColor(.secondary)
                                .font(.system(size: 20, weight: .bold))
                        }
                    }
                )
            
            Text(milestone.title)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text(milestone.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(height: 180)
        .padding()
        .background(cardBackground)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    private var cardBackground: Color {
        colorScheme == .dark ? Color.gray.opacity(0.2) : Color.white
    }
}
struct FinancesView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Summary")) {
                    financeSummaryRow(title: "Total Saved", value: "$420")
                    financeSummaryRow(title: "Monthly Average", value: "$140")
                }
                
                Section(header: Text("Savings Goals")) {
                    savingsGoalRow(title: "New Phone", target: "$1000", current: "$420", progress: 0.42)
                    savingsGoalRow(title: "Vacation", target: "$2000", current: "$0", progress: 0)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Finances")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .accentColor(.red)
    }
    
    private func financeSummaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(.bold)
        }
    }
    
    private func savingsGoalRow(title: String, target: String, current: String, progress: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
            HStack {
                Text(current)
                Text(" / ")
                Text(target)
                    .foregroundColor(.gray)
            }
            .font(.subheadline)
            ProgressView(value: progress)
                .accentColor(.red)
        }
    }
}


struct SettingsView: View {
    @ObservedObject var viewModel: PuffTrackViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var vapeCost: String = ""
    @State private var puffsPerVape: String = ""
    @State private var monthlySpending: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Vape Details")) {
                    TextField("Cost per vape ($)", text: $vapeCost)
                        .keyboardType(.decimalPad)
                    TextField("Puffs per vape", text: $puffsPerVape)
                        .keyboardType(.numberPad)
                }
                
                Section(header: Text("Monthly Spending")) {
                    TextField("Monthly vape spending ($)", text: $monthlySpending)
                        .keyboardType(.decimalPad)
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $viewModel.notificationsEnabled)
                }
                
                Section {
                    Button("Reset All Data") {
                        // Implement reset functionality
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Save") {
                saveSettings()
            })
        }
        .onAppear(perform: loadCurrentSettings)
    }
    

    private func loadCurrentSettings() {
        vapeCost = String(format: "%.2f", viewModel.settings.vapeCost)
        puffsPerVape = "\(viewModel.settings.puffsPerVape)"
        monthlySpending = String(format: "%.2f", viewModel.settings.monthlySpending)
    }
    
    private func saveSettings() {
        if let cost = Double(vapeCost),
           let puffs = Int(puffsPerVape),
           let spending = Double(monthlySpending) {
            viewModel.updateSettings(vapeCost: cost, puffsPerVape: puffs, monthlySpending: spending)
        }
        presentationMode.wrappedValue.dismiss()
    }
}
