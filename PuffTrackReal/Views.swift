//
//  Views.swift
//  PuffTrackReal
//
//  Created by Kaan Şenol on 27.08.2024.
//

import Foundation
import SwiftUI

struct MilestonesView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Achieved")) {
                    milestoneRow(title: "First Day Clean", description: "24 hours without a puff", date: "May 1, 2023")
                    milestoneRow(title: "Week Warrior", description: "7 days puff-free", date: "May 7, 2023")
                }
                
                Section(header: Text("Upcoming")) {
                    milestoneRow(title: "Month Master", description: "30 days without a puff", progress: 0.6)
                    milestoneRow(title: "Quarter Champion", description: "90 days smoke-free", progress: 0.2)
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Milestones")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .accentColor(.red)
    }
    
    private func milestoneRow(title: String, description: String, date: String? = nil, progress: CGFloat? = nil) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.headline)
            Text(description)
                .font(.subheadline)
                .foregroundColor(.gray)
            if let date = date {
                Text("Achieved: \(date)")
                    .font(.caption)
                    .foregroundColor(.green)
            } else if let progress = progress {
                ProgressView(value: progress)
                    .accentColor(.red)
            }
        }
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

struct FriendsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var newFriendName = ""
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Add Friend")) {
                    HStack {
                        TextField("Friend's name", text: $newFriendName)
                        Button(action: {
                            // Add friend logic here
                            newFriendName = ""
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("Your Friends")) {
                    ForEach(1...5, id: \.self) { _ in
                        friendRow()
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Friends")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .accentColor(.red)
    }
    
    private func friendRow() -> some View {
        HStack {
            Circle()
                .fill(Color.red)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading) {
                Text("Friend Name")
                    .font(.headline)
                Text("15 puffs today")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text("-5%")
                .foregroundColor(.green)
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
