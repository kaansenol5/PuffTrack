//
//  SettingsView.swift
//  PuffTrackReal
//
//  Created by Kaan Şenol on 26.09.2024.
//
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
    @State private var dailyPuffLimit: String = ""
    @State private var activeAlert: ActiveAlert?
    @State private var showViewDataSheet = false
    @State private var userData: String = ""
    @State private var isEditingName = false
    @State private var newName = ""
    @State private var isUpdatingName = false
    
    enum ActiveAlert: Identifiable {
        case logout, deleteAccount, deleteAccountConfirmation, resetData, resetDataConfirmation, resetDataSuccess
        
        var id: Int {
            switch self {
            case .logout: return 0
            case .deleteAccount: return 1
            case .deleteAccountConfirmation: return 2
            case .resetData: return 3
            case .resetDataConfirmation: return 4
            case .resetDataSuccess: return 5
            }
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                accountSection
                if(socialsViewModel.isUserLoggedIn()){
                    accountManagementSection
                }
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
        private var accountManagementSection: some View {
        Section(header: Text("Account Management").foregroundColor(.red)) {
            if socialsViewModel.isUserLoggedIn(){
                Button(action: {
                    activeAlert = .logout
                }) {
                    Text("Logout")
                        .foregroundColor(.red)
                }
                Button(action: {
                    activeAlert = .deleteAccount
                }) {
                    Text("Delete My Account")
                        .foregroundColor(.red)
                }
            } else {
                Text("Not signed in")
                    .foregroundColor(.gray)
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
        if(socialsViewModel.isUserLoggedIn()){
            socialsViewModel.removeAllPuffs { result in
                switch result {
                case .success(let count):
                    print("Successfully deleted \(count) puffs")
                    DispatchQueue.main.async {
                        activeAlert = .resetDataSuccess
                    }
                case .failure(let error):
                    print("Failed to delete puffs: \(error.localizedDescription)")
                    // Error handling is already done by the function through isErrorDisplayed and errorMessage
                }
            }
        }
    }
    
    private var accountSection: some View {
        Section(header: Text("Account").foregroundColor(.red)) {
            if socialsViewModel.isUserLoggedIn() {
                if isEditingName {
                    HStack {
                        TextField("Name", text: $newName)
                        
                        if isUpdatingName {
                            ProgressView()
                                .padding(.horizontal, 4)
                        } else {
                            Button("Save") {
                                updateName()
                            }
                            .disabled(newName.isEmpty || newName == socialsViewModel.serverData?.user.name)
                            .foregroundColor(.red)
                            
                            Button("Cancel") {
                                isEditingName = false
                                newName = socialsViewModel.serverData?.user.name ?? ""
                            }
                            .foregroundColor(.gray)
                        }
                    }
                } else {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(socialsViewModel.serverData?.user.name ?? "")
                            .foregroundColor(.gray)
                        Button(action: {
                            newName = socialsViewModel.serverData?.user.name ?? ""
                            isEditingName = true
                        }) {
                            Image(systemName: "pencil")
                                .foregroundColor(.red)
                        }
                    }
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
            } else {
                Text("Not signed in")
                    .foregroundColor(.gray)
            }
        }
    }

    private func updateName() {
        guard !newName.isEmpty else { return }
        isUpdatingName = true
        
        socialsViewModel.changeName(newName: newName) { result in
            DispatchQueue.main.async {
                isUpdatingName = false
                switch result {
                case .success:
                    isEditingName = false
                case .failure:
                    // Error is already handled by socialsViewModel's error display
                    newName = socialsViewModel.serverData?.user.name ?? ""
                }
            }
        }
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
            }
        }
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
