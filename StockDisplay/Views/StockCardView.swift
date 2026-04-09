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
                    .font(.system(size: 20 * fontScale, weight: .bold))
                Text(code)
                    .font(.system(size: 15 * fontScale))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            priceAndChangeView
        }
        .padding()
        .background(Color.gray.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var priceAndChangeView: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            priceContent
                .frame(minWidth: 150 * fontScale, alignment: .trailing)
            changeContent
                .frame(minWidth: 150 * fontScale, alignment: .trailing)
        }
    }
    
    @ViewBuilder
    private var priceContent: some View {
        switch loadState {
        case .idle, .loading:
            Text(String(localized: "dashboard.loading"))
                .font(.system(size: 17 * fontScale, weight: .bold))
                .foregroundStyle(.secondary)
        case .loaded(let price, _):
            Text(String(format: "%.2f", price))
                .font(.system(size: 30 * fontScale, weight: .bold).monospacedDigit())
        case .error:
            Text(String(localized: "dashboard.error"))
                .font(.system(size: 17 * fontScale, weight: .bold))
                .foregroundStyle(.red)
        }
    }
    
    @ViewBuilder
    private var changeContent: some View {
        switch loadState {
        case .idle, .loading:
            EmptyView()
        case .loaded(_, let change):
            Text(String(format: "%+.2f%%", change))
                .font(.system(size: 28 * fontScale, weight: .semibold).monospacedDigit())
                .foregroundStyle(changeColor)
        case .error(let message):
            Text(message)
                .font(.system(size: 12 * fontScale, weight: .semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }
}
