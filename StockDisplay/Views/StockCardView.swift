import SwiftUI

enum StockLoadState {
    case idle
    case loading
    case loaded(price: Double, change: Double)
    case error(String)
}

struct StockCardView: View {
    @Environment(\.fontScale) private var fontScale
    @AppStorage("stockChangeColorMode") private var stockChangeColorMode: String = StockChangeColorMode.redUpGreenDown.rawValue
    let name: String
    let code: String
    let loadState: StockLoadState
    
    private var colorMode: StockChangeColorMode {
        StockChangeColorMode(rawValue: stockChangeColorMode) ?? .redUpGreenDown
    }
    
    private var changeColor: Color {
        guard case .loaded(_, let change) = loadState else { return .secondary }
        return change >= 0 ? colorMode.colorForChange : colorMode.colorForDecline
    }
    
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
                case .loaded(let price, _):
                    Text(String(format: "$%.2f", price))
                        .font(.system(size: 17 * fontScale, weight: .semibold))
                    Text(String(format: "%+.2f%%", changeValue))
                        .font(.system(size: 15 * fontScale))
                        .foregroundStyle(changeColor)
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
    
    private var changeValue: Double {
        guard case .loaded(_, let change) = loadState else { return 0 }
        return change
    }
}
