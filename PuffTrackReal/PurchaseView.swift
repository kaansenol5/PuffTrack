//
//  PurchaseView.swift
//  PuffTrack
//
//  Created by Kaan Şenol on 6.10.2024.
//

import SwiftUI

import SwiftUI

struct PurchaseView: View {
    @StateObject private var purchaseManager = PurchaseManager.shared
    @Environment(\.colorScheme) var colorScheme
    @State private var isLoading = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundColor.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: geometry.size.height * 0.04) {
                    headerSection
                    
                    premiumFeatures(size: geometry.size)
                    
                    freeTrialButton
                        .frame(height: geometry.size.height * 0.07)
                    
                    
                    
                    restorePurchaseButton
                }
                .padding(.horizontal, geometry.size.width * 0.06)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .red))
                        .scaleEffect(1.5)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 10) {
            Image("pufftracklogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 60)
                .foregroundColor(.red)
            
            Text("PuffTrack Premium")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(textColor)
            
            Text("Unlock advanced features to help you quit vaping for good.")
                .font(.headline)
                .foregroundColor(textColor.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    private func premiumFeatures(size: CGSize) -> some View {
        VStack(spacing: size.height * 0.02) {
            HStack(spacing: size.width * 0.05) {
                featureItem(icon: "chart.bar.fill", text: "Track progress")
                
                featureItem(icon: "person.3.fill", text: "Social support")
            }
            
            HStack(spacing: size.width * 0.05) {
                featureItem(icon: "dollarsign.circle", text: "Savings tracker")
                
                featureItem(icon: "bell.badge.fill", text: "Custom alerts")
            }
        }
    }
    
    private func featureItem(icon: String, text: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.gray.opacity(0.1))
            
            VStack(spacing: 15) {
                Image(systemName: icon)
                    .foregroundColor(.red)
                    .font(.system(size: 34))
                
                Text(text)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(textColor)
            }
            .padding()
        }
        .fixedSize(horizontal: false, vertical: true)
    }
    
    private var freeTrialButton: some View {
        Button(action: {
            Task {
                await purchaseSubscription()
            }
        }) {
            VStack(spacing: 4) {
                Text("Start Free Trial")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text("3 days free, then \(purchaseManager.subscriptions.first?.displayPrice ?? "") / month")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.red)
            .cornerRadius(30)
        }
        .disabled(isLoading || purchaseManager.subscriptions.isEmpty)
    }
    
    
    private var restorePurchaseButton: some View {
        Button(action: {
            Task {
                await restorePurchases()
            }
        }) {
            Text("Restore Purchase")
                .font(.subheadline)
                .foregroundColor(.red)
                .padding(.bottom)
        }
        .disabled(isLoading)
    }
    
    private func purchaseSubscription() async {
        guard let subscription = purchaseManager.subscriptions.first else { return }
        
        isLoading = true
        do {
            try await purchaseManager.purchase(subscription)
        } catch {
            print("Failed to purchase: \(error)")
        }
        isLoading = false
    }
    
    private func restorePurchases() async {
        isLoading = true
        do {
            try await purchaseManager.restorePurchases()
        } catch {
            print("Failed to restore purchases: \(error)")
        }
        isLoading = false
    }
    
    private var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
}

struct PurchaseView_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseView()
    }
}
