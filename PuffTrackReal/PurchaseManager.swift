//
//  PurchaseManager.swift
//  PuffTrack
//
//  Created by Kaan Şenol on 6.10.2024.
//

import StoreKit
import Combine

@MainActor
class PurchaseManager: ObservableObject {
    static let shared = PurchaseManager()
    
    @Published private(set) var subscriptions: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    @Published private(set) var isSubscribed = false
    
    private let productIds = ["pufftracksub199"]
    private var updateTimer: AnyCancellable?
    
    private init() {
        Task {
            await updateSubscriptionStatus()
            await loadProducts()
            await observeTransactionUpdates()
        }
        
        // Set up a timer to check subscription status periodically
        updateTimer = Timer.publish(every: 60 * 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.updateSubscriptionStatus()
                }
            }
    }
    
    func loadProducts() async {
        do {
            subscriptions = try await Product.products(for: productIds)
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verificationResult):
            switch verificationResult {
            case .verified(let transaction):
                await transaction.finish()
                await updateSubscriptionStatus()
            case .unverified:
                throw StoreError.failedVerification
            }
        case .userCancelled:
            throw StoreError.userCancelled
        case .pending:
            throw StoreError.pending
        @unknown default:
            throw StoreError.unknown
        }
    }
    
    func updateSubscriptionStatus() async {
        do {
            var hasActiveSubscription = false
            
            for await result in Transaction.currentEntitlements {
                guard case .verified(let transaction) = result else {
                    continue
                }
                
                if transaction.productType == .autoRenewable {
                    let product = try await Product.products(for: [transaction.productID]).first
                    
                    if let subscription = product {
                        let statuses = try await subscription.subscription?.status ?? []
                        
                        for status in statuses {
                            switch status.state {
                            case .subscribed, .inGracePeriod:
                                hasActiveSubscription = true
                                purchasedSubscriptions = [subscription]
                                break
                            default:
                                continue
                            }
                        }
                        
                        if hasActiveSubscription {
                            break
                        }
                    }
                }
            }
            
            isSubscribed = hasActiveSubscription
        } catch {
            print("Failed to update subscription status: \(error)")
            isSubscribed = false
        }
    }
    
    func restorePurchases() async throws {
        try await AppStore.sync()
        await updateSubscriptionStatus()
    }
    
    private func observeTransactionUpdates() async {
        for await verificationResult in Transaction.updates {
            guard case .verified(let transaction) = verificationResult else {
                continue
            }
            
            await handleVerifiedTransaction(transaction)
        }
    }
    
    private func handleVerifiedTransaction(_ transaction: Transaction) async {
        if transaction.productType == .autoRenewable {
            await updateSubscriptionStatus()
        }
        
        await transaction.finish()
    }
}

enum StoreError: Error {
    case failedVerification
    case userCancelled
    case pending
    case unknown
}
