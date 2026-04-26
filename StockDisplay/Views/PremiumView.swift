import SwiftUI
import StoreKit
import Combine

struct PremiumView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var storeKitManager = StoreKitManager()
    @State private var isPurchasing: Bool = false
    @State private var purchaseError: String?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.yellow)
                    .padding(.top, 40)
                
                Text(String(localized: "premium.title"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(String(localized: "premium.subtitle"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(
                        icon: "bolt.fill",
                        title: String(localized: "premium.feature.refresh1"),
                        description: String(localized: "premium.feature.refresh1.desc")
                    )
                    
                    FeatureRow(
                        icon: "bell.fill",
                        title: String(localized: "premium.feature.alerts"),
                        description: String(localized: "premium.feature.alerts.desc")
                    )
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                if storeKitManager.isPremium {
                    Text(String(localized: "premium.unlocked"))
                        .font(.headline)
                        .foregroundStyle(.green)
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        Button {
                            Task {
                                isPurchasing = true
                                purchaseError = nil
                                do {
                                    _ = try await storeKitManager.purchase()
                                } catch {
                                    purchaseError = error.localizedDescription
                                }
                                isPurchasing = false
                            }
                        } label: {
                            HStack {
                                if isPurchasing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    if let product = storeKitManager.premiumProduct {
                                        Text("\(String(localized: "premium.purchase")) - \(product.displayPrice)")
                                    } else {
                                        Text(String(localized: "premium.purchase"))
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isPurchasing)
                        
                        Button {
                            Task {
                                await storeKitManager.restorePurchases()
                            }
                        } label: {
                            Text(String(localized: "premium.restore"))
                        }
                        
                        if let error = purchaseError {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle(String(localized: "premium.navTitle"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PremiumView()
    }
}
