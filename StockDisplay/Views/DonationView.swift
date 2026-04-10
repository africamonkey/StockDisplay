import SwiftUI
import StoreKit

struct DonationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var donationManager = DonationManager()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(String(localized: "donation.subtitle"))
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                
                if donationManager.products.isEmpty {
                    ProgressView()
                        .padding()
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(donationManager.products, id: \.id) { product in
                            DonationButton(product: product) {
                                Task {
                                    await donationManager.purchase(product)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                if case .success = donationManager.purchaseState {
                    Text(String(localized: "donation.success"))
                        .foregroundStyle(.green)
                        .font(.headline)
                } else if case .error(let message) = donationManager.purchaseState {
                    Text(message)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                
                Button(String(localized: "donation.close")) {
                    dismiss()
                }
                .padding(.bottom, 20)
            }
            .navigationTitle(String(localized: "donation.title"))
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await donationManager.loadProducts()
            }
            .onChange(of: donationManager.purchaseState) { _, newValue in
                if case .success = newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        donationManager.resetState()
                    }
                }
            }
        }
    }
}

struct DonationButton: View {
    let product: Product
    let action: () -> Void
    
    private var displayPrice: String {
        product.displayPrice
    }
    
    private var donationTier: String {
        switch product.id {
        case "donation_1": return String(localized: "donation.tier1")
        case "donation_10": return String(localized: "donation.tier2")
        case "donation_30": return String(localized: "donation.tier3")
        case "donation_100": return String(localized: "donation.tier4")
        default: return displayPrice
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(displayPrice)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(donationTier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DonationView()
}
