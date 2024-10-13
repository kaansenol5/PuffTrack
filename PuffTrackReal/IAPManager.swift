//
//  IAPManager.swift
//  PuffTrack
//
//  Created by Kaan Şenol on 6.10.2024.
//
import StoreKit
import SwiftUI

@MainActor
class IAPManager: ObservableObject {
    static let shared = IAPManager()
    
    @Published var isSubscribed: Bool = false {
        didSet {
            print("isSubscribed set to \(isSubscribed)")
        }
    }    
    private let productID = "pufftracksub199"
    private let userDefaults = UserDefaults.standard
    private let subscriptionKey = "isSubscribed"
    private var updateListenerTask: Task<Void, Error>?
    
    private init() {
        updateListenerTask = listenForTransactionUpdates()
        Task {
            await updateSubscriptionStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    private func listenForTransactionUpdates() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    
                    // Always finish a transaction.
                    await transaction.finish()
                    
                    // Update the subscription status
                    await self.updateSubscriptionStatus()
                    
                } catch {
                    // StoreKit has a receipt it can read but it failed verification. Don't deliver content to the user.
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    func buySubscription() async throws {
        guard let product = try? await Product.products(for: [productID]).first else {
            print("Failed to get product info")
            return
        }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updateSubscriptionStatus()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }
    
    func updateSubscriptionStatus() async {
        do {
            print("Starting subscription status update")
            var foundValidSubscription = false
            for await result in Transaction.currentEntitlements {
                do {
                    let transaction = try checkVerified(result)
                    print("Found transaction: ProductID: \(transaction.productID), PurchaseDate: \(transaction.purchaseDate), ExpirationDate: \(String(describing: transaction.expirationDate))")
                    if transaction.productID == productID {
                        let isValid = transaction.revocationDate == nil && (transaction.expirationDate ?? Date.distantPast) > Date()
                        print("Matching product found. Valid: \(isValid)")
                        foundValidSubscription = isValid
                        break
                    }
                } catch {
                    print("Error verifying transaction: \(error)")
                    continue
                }
            }
            print("Setting subscription status to: \(foundValidSubscription)")
            setSubscriptionStatus(foundValidSubscription)
        } catch {
            print("Error checking subscription status: \(error)")
            isSubscribed = userDefaults.bool(forKey: subscriptionKey)
        }
    }
    
    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
        } catch {
            print("Failed to restore purchases: \(error)")
            // If restore fails (likely due to being offline), use the stored value
            isSubscribed = userDefaults.bool(forKey: subscriptionKey)
        }
    }
    
    private func setSubscriptionStatus(_ status: Bool) {
        isSubscribed = status
        userDefaults.set(status, forKey: subscriptionKey)
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
