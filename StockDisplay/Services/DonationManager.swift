import Foundation
import StoreKit

@MainActor
final class DonationManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseState: PurchaseState = .idle
    
    enum PurchaseState {
        case idle
        case loading
        case success
        case error(String)
    }
    
    private let productIds = [
        "donation_1",
        "donation_10",
        "donation_30",
        "donation_100"
    ]
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIds)
                .sorted { product1, product2 in
                    let order = productIds
                    let index1 = order.firstIndex(of: product1.id) ?? 0
                    let index2 = order.firstIndex(of: product2.id) ?? 0
                    return index1 < index2
                }
        } catch {
            purchaseState = .error(error.localizedDescription)
        }
    }
    
    func purchase(_ product: Product) async {
        purchaseState = .loading
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                purchaseState = .success
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .error(error.localizedDescription)
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    func resetState() {
        purchaseState = .idle
    }
}
