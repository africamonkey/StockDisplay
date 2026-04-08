import SwiftUI

enum StockLoadState {
    case idle
    case loading
    case loaded(price: Double, change: Double)
    case error(String)
}

struct StockCardView: View {
    @Environment(\.fontScale) private var fontScale
    let name: String
    let code: String
    let loadState: StockLoadState
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 17 * fontScale, weight: .semibold))
                Text(code)
                    .font(.system(size: 15 * fontScale))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                switch loadState {
                case .idle, .loading:
                    Text(String(localized: "dashboard.loading"))
                        .font(.system(size: 17 * fontScale, weight: .semibold))
                        .foregroundStyle(.secondary)
                case .loaded(let price, let change):
                    Text(String(format: "$%.2f", price))
                        .font(.system(size: 17 * fontScale, weight: .semibold))
                    Text(String(format: "%+.2f%%", change))
                        .font(.system(size: 15 * fontScale))
                        .foregroundStyle(change >= 0 ? .green : .red)
                case .error(let message):
                    Text(String(localized: "dashboard.error"))
                        .font(.system(size: 17 * fontScale, weight: .semibold))
                        .foregroundStyle(.red)
                    Text(message)
                        .font(.system(size: 12 * fontScale))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
