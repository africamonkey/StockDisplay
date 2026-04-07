import SwiftUI
import UIKit

enum StockLoadState {
    case idle
    case loading
    case loaded(price: Double, change: Double)
    case error(String)
}

struct StockCardView: View {
    let name: String
    let code: String
    let loadState: StockLoadState
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                Text(code)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                switch loadState {
                case .idle, .loading:
                    Text("Loading...")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                case .loaded(let price, let change):
                    Text(String(format: "$%.2f", price))
                        .font(.headline)
                    Text(String(format: "%+.2f%%", change))
                        .font(.subheadline)
                        .foregroundStyle(change >= 0 ? .green : .red)
                case .error(let message):
                    Text("Error")
                        .font(.headline)
                        .foregroundStyle(.red)
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color(uiColor: UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}