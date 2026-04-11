import Foundation
import StoreKit
import SwiftUI
import Combine

enum StoreKitPurchaseError: Error {
    case productNotFound
    case verificationFailed
}

class StoreKitManager: ObservableObject {
    @Published var isPremium: Bool = false
    
    private let premiumProductID = "premium"
    
    init() {
        if let storedValue = UserDefaults.standard.object(forKey: "isPremium") as? Bool {
            isPremium = storedValue
        }
        Task {
            await loadProducts()
            await updatePremiumStatus()
            await listenForTransactions()
        }
    }
    
    @MainActor
    func loadProducts() async {
        do {
            let productIDs = [premiumProductID]
            let products = try await Product.products(for: Set(productIDs))
            for product in products {
                print("Found product: \(product.id)")
            }
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    @MainActor
    func purchase() async throws -> StoreKit.Transaction? {
        let productIDs = [premiumProductID]
        let products = try await Product.products(for: Set(productIDs))
        guard let product = products.first else {
            throw StoreKitPurchaseError.productNotFound
        }
        
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePremiumStatus()
            await transaction.finish()
            return transaction
        case .userCancelled:
            return nil
        case .pending:
            return nil
        @unknown default:
            return nil
        }
    }
    
    @MainActor
    func restorePurchases() async {
        isPremium = false
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == premiumProductID {
                    isPremium = true
                    UserDefaults.standard.set(true, forKey: "isPremium")
                    try? await transaction.finish()
                    break
                }
            }
        }
    }
    
    @MainActor
    private func updatePremiumStatus() async {
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productID == premiumProductID {
                    isPremium = true
                    UserDefaults.standard.set(true, forKey: "isPremium")
                    return
                }
            }
        }
        isPremium = false
        UserDefaults.standard.set(false, forKey: "isPremium")
    }
    
    private func listenForTransactions() async {
        for await result in Transaction.updates {
            if case .verified(let transaction) = result {
                if transaction.productID == premiumProductID {
                    await MainActor.run {
                        isPremium = true
                        UserDefaults.standard.set(true, forKey: "isPremium")
                    }
                }
                await transaction.finish()
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitPurchaseError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}
