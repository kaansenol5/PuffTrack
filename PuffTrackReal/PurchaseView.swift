//
//  PurchaseView.swift
//  PuffTrack
//
//  Created by Kaan Şenol on 6.10.2024.
//

import SwiftUI

struct PurchaseView: View {
    @StateObject private var purchaseManager = PurchaseManager.shared
    @State private var isLoading = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 30) {
            header
            
            subscriptionInfo
            
            buyButton
            
            restorePurchaseButton
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .red))
                    .scaleEffect(1.5)
            }
        }
        .padding()
        .background(backgroundColor.edgesIgnoringSafeArea(.all))
    }
    
    private var header: some View {
        VStack(spacing: 10) {
            Image("pufftracklogo")
                .resizable() // Makes the image resizable
                .aspectRatio(contentMode: .fit) // Maintains aspect ratio
                .frame(width: 60, height: 60) // Sets the size of the image
                .foregroundColor(.red) // Apply a color overlay if needed, or remove this if you don't want to tint the image
            
            Text("Unlock PuffTrack Premium")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(textColor)
            
            Text("Track your progress, connect with friends, and stay motivated on your journey to quit vaping.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(textColor.opacity(0.8))
                .padding(.horizontal)
        }
    }
    private var subscriptionInfo: some View {
        VStack(spacing: 15) {
            Text("Monthly Subscription")
                .font(.headline)
                .foregroundColor(textColor)
            
            if let subscription = purchaseManager.subscriptions.first {
                Text(subscription.displayPrice)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.red)
            } else {
                Text("Loading...")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                featureRow(icon: "chart.bar.fill", text: "Track your daily puff count")
                featureRow(icon: "person.3.fill", text: "Connect with friends for support")
                featureRow(icon: "dollarsign.circle.fill", text: "See your potential savings")
                featureRow(icon: "bell.badge.fill", text: "Personalized notifications")
            }
            .padding()
            .background(cardBackgroundColor)
            .cornerRadius(15)
        }
    }
    
    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(.red)
                .font(.system(size: 22))
            Text(text)
                .font(.subheadline)
                .foregroundColor(textColor)
        }
    }
    
    private var buyButton: some View {
        Button(action: {
            Task {
                await purchaseSubscription()
            }
        }) {
            Text("Subscribe Now")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
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
                .foregroundColor(.red)
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
            // Here you could show an alert to the user about the failure
        }
        isLoading = false
    }
    
    private func restorePurchases() async {
        isLoading = true
        do {
            try await purchaseManager.restorePurchases()
        } catch {
            print("Failed to restore purchases: \(error)")
            // Here you could show an alert to the user about the failure
        }
        isLoading = false
    }
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    var textColor: Color {
        colorScheme == .dark ? Color.white : Color.black
    }
    
    var cardBackgroundColor: Color {
        colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1)
    }
}

struct PurchaseView_Previews: PreviewProvider {
    static var previews: some View {
        PurchaseView()
    }
}
