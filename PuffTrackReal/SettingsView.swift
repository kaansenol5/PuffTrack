//
//  SettingsView.swift
//  PuffTrackReal
//
//  Created by Kaan Şenol on 26.09.2024.
//
import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: PuffTrackViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var vapeCost: String = ""
    @State private var puffsPerVape: String = ""
    @State private var monthlySpending: String = ""
    @State private var dailyPuffLimit: String = ""
    @State private var activeAlert: ActiveAlert?
    @State private var showViewDataSheet = false
    @State private var userData: String = ""
    
    enum ActiveAlert: Identifiable {
        case resetData, resetDataConfirmation, resetDataSuccess
        
        var id: Int {
            switch self {
            case .resetData: return 3
            case .resetDataConfirmation: return 4
            case .resetDataSuccess: return 5
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                vapeDetailsSection
                dailyPuffLimitSection
                monthlySpendingSection
                notificationsSection
                resetDataSection
                legalSection
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Save") {
                saveSettings()
            })
            .background(backgroundColor)
        }
        .accentColor(.red)
        .onAppear(perform: loadCurrentSettings)
        .alert(item: $activeAlert) { alertType in
            switch alertType {
            case .resetData:
                return Alert(
                    title: Text("Reset All Data"),
                    message: Text("Are you sure you want to reset all your puff data? This action cannot be undone."),
                    primaryButton: .destructive(Text("Reset")) {
                        activeAlert = .resetDataConfirmation
                    },
                    secondaryButton: .cancel()
                )
            case .resetDataConfirmation:
                return Alert(
                    title: Text("Confirm Reset"),
                    message: Text("This will permanently delete all your logged puffs. Are you absolutely sure?"),
                    primaryButton: .destructive(Text("Yes, Reset All Data")) {
                        resetAllData()
                    },
                    secondaryButton: .cancel()
                )
            case .resetDataSuccess:
                return Alert(
                    title: Text("Success"),
                    message: Text("All data has been successfully reset."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .sheet(isPresented: $showViewDataSheet) {
            ViewDataSheet(userData: userData)
        }
    }
    
    private var legalSection: some View {
        Section(header: Text("Legal").foregroundColor(.red)) {
            if let url = URL(string: "https://www.pufftrack.app/privacy-policy") {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.red)
                        Text("Privacy Policy")
                    }
                }
            }
            if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                Link(destination: url) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.red)
                        Text("Terms of Service")
                    }
                }
            }
        }
    }
    
    private var resetDataSection: some View {
        Section(header: Text("Data Management").foregroundColor(.red)) {
            Button(action: {
                activeAlert = .resetData
            }) {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                    Text("Reset All Data")
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private func resetAllData() {
        viewModel.model.puffs = []
        viewModel.model.removeOldPuffs() // This will trigger the save
        activeAlert = .resetDataSuccess
    }
    
    private var vapeDetailsSection: some View {
        Section(header: Text("Vape Details").foregroundColor(.red)) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.red)
                VStack(alignment: .leading) {
                    Text("Cost per vape ($)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("0.00", text: $vapeCost)
                        .keyboardType(.decimalPad)
                }
            }
            HStack {
                Image(systemName: "number.circle.fill")
                    .foregroundColor(.red)
                VStack(alignment: .leading) {
                    Text("Puffs per vape")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("0", text: $puffsPerVape)
                        .keyboardType(.numberPad)
                }
            }
        }
    }

    private var dailyPuffLimitSection: some View {
        Section(header: Text("Daily Puff Limit").foregroundColor(.red)) {
            HStack {
                Image(systemName: "lungs.fill")
                    .foregroundColor(.red)
                VStack(alignment: .leading) {
                    Text("Daily Puff Limit")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("0", text: $dailyPuffLimit)
                        .keyboardType(.numberPad)
                }
            }
        }
    }

    private var monthlySpendingSection: some View {
        Section(header: Text("Monthly Spending").foregroundColor(.red)) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.red)
                TextField("Monthly vape spending ($)", text: $monthlySpending)
                    .keyboardType(.decimalPad)
            }
        }
    }
    
    private var notificationsSection: some View {
        Section(header: Text("Notifications").foregroundColor(.red)) {
            Toggle(isOn: $viewModel.notificationsEnabled) {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.red)
                    Text("Enable Notifications")
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    private func loadCurrentSettings() {
        vapeCost = String(format: "%.2f", viewModel.settings.vapeCost)
        puffsPerVape = "\(viewModel.settings.puffsPerVape)"
        monthlySpending = String(format: "%.2f", viewModel.settings.monthlySpending)
        dailyPuffLimit = "\(viewModel.settings.dailyPuffLimit)"
    }
    
    private func saveSettings() {
        if let cost = Double(vapeCost),
           let puffs = Int(puffsPerVape),
           let spending = Double(monthlySpending),
           let puffLimit = Int(dailyPuffLimit) {
            viewModel.updateSettings(vapeCost: cost, puffsPerVape: puffs, monthlySpending: spending, dailyPuffLimit: puffLimit)
        }
        presentationMode.wrappedValue.dismiss()
    }
}

struct ViewDataSheet: View {
    let userData: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(userData)
                    .padding()
                    .font(.system(.body, design: .monospaced))
            }
            .navigationBarTitle("My Data", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
