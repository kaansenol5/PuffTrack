//
//  SettingsView.swift
//  PuffTrackReal
//
//  Created by Kaan Şenol on 26.09.2024.
//

import Foundation
import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: PuffTrackViewModel
    @ObservedObject var socialsViewModel: SocialsViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State var isAuthViewPresented: Bool
    @State private var vapeCost: String = ""
    @State private var puffsPerVape: String = ""
    @State private var monthlySpending: String = ""
    @State private var activeAlert: ActiveAlert?
    @State private var showViewDataSheet = false
    @State private var userData: String = ""
    enum ActiveAlert: Identifiable {
        case logout, deleteAccount, deleteAccountConfirmation
        
        var id: Int {
            switch self {
            case .logout: return 0
            case .deleteAccount: return 1
            case .deleteAccountConfirmation: return 2
            }
        }
    }
    
    
    var body: some View {
        NavigationView {
            Form {
                accountSection
                vapeDetailsSection
                monthlySpendingSection
                notificationsSection
                accountManagementSection
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
            case .logout:
                return Alert(
                    title: Text("Logout"),
                    message: Text("Are you sure you want to logout?"),
                    primaryButton: .destructive(Text("Logout")) {
                        socialsViewModel.logout()
                    },
                    secondaryButton: .cancel()
                )
            case .deleteAccount:
                return Alert(
                    title: Text("Delete Account"),
                    message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                    primaryButton: .destructive(Text("Delete")) {
                        activeAlert = .deleteAccountConfirmation
                    },
                    secondaryButton: .cancel()
                )
            case .deleteAccountConfirmation:
                return Alert(
                    title: Text("Confirm Delete Account"),
                    message: Text("This will permanently delete your account and all associated data. Are you absolutely sure?"),
                    primaryButton: .destructive(Text("Yes, Delete My Account")) {
                        deleteAccount()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .sheet(isPresented: $showViewDataSheet) {
            ViewDataSheet(userData: userData)
        }
    }
    
    private var accountManagementSection: some View {
        Section(header: Text("Account Management").foregroundColor(.red)) {
            Button(action: {
                viewMyData()
            }) {
                Text("View My Data")
                    .foregroundColor(.blue)
            }
            
            Button(action: {
                print("Delete account button clicked")
                activeAlert = .deleteAccount
            }) {
                Text("Delete My Account")
                    .foregroundColor(.red)
            }
        }
    }
    

    
    private func viewMyData() {
        socialsViewModel.accessData { result in
            switch result {
            case .success(let data):
                if let jsonData = try? JSONSerialization.data(withJSONObject: data, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    userData = jsonString
                    showViewDataSheet = true
                } else {
                    userData = "Error: Could not parse data"
                    showViewDataSheet = true
                }
            case .failure(let error):
                userData = "Error: \(error.localizedDescription)"
                showViewDataSheet = true
            }
        }
    }
    
    private func deleteAccount() {
        socialsViewModel.removeData { result in
            switch result {
            case .success:
                socialsViewModel.logout()
                presentationMode.wrappedValue.dismiss()
            case .failure(let error):
                print("Failed to delete account: \(error.localizedDescription)")
                // You might want to show an alert here to inform the user
            }
        }
    }
    
    
    private var accountSection: some View {
        Section(header: Text("Account").foregroundColor(.red)) {
            if socialsViewModel.isUserLoggedIn() {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(socialsViewModel.serverData?.user.name ?? "")
                        .foregroundColor(.gray)
                }
                HStack {
                    Text("Email")
                    Spacer()
                    Text(socialsViewModel.serverData?.user.email ?? "")
                        .foregroundColor(.gray)
                }
                HStack {
                    Text("User ID")
                    Spacer()
                    Text(socialsViewModel.serverData?.user.id ?? "")
                        .foregroundColor(.gray)
                }
                Button(action: {
                    activeAlert = .logout
                }) {
                    Text("Logout")
                        .foregroundColor(.red)
                }
            } else {
                Text("Not signed in")
                    .foregroundColor(.gray)
            }
        }
    }

    
    private var vapeDetailsSection: some View {
        Section(header: Text("Vape Details").foregroundColor(.red)) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .foregroundColor(.red)
                TextField("Cost per vape ($)", text: $vapeCost)
                    .keyboardType(.decimalPad)
            }
            HStack {
                Image(systemName: "numbersign.circle.fill")
                    .foregroundColor(.red)
                TextField("Puffs per vape", text: $puffsPerVape)
                    .keyboardType(.numberPad)
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
