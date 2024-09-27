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
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                accountSection
                
                vapeDetailsSection
                
                monthlySpendingSection
                
                notificationsSection
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing: Button("Save") {
                saveSettings()
            })
            .background(backgroundColor)
        }
        .accentColor(.red)
        .onAppear(perform: loadCurrentSettings)
        .alert(isPresented: $showLogoutAlert) {
            Alert(
                title: Text("Logout"),
                message: Text("Are you sure you want to logout?"),
                primaryButton: .destructive(Text("Logout")) {
                    socialsViewModel.logout()
                },
                secondaryButton: .cancel()
            )
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
                    showLogoutAlert = true
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
