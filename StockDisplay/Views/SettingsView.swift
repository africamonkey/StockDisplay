import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var stocks: [StockConfig]
    
    var body: some View {
        List {
            Section(String(localized: "settings.stockSettings")) {
                if stocks.isEmpty {
                    Text(String(localized: "settings.noStocksConfigured"))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(stocks) { stock in
                        NavigationLink(destination: AddEditStockView(mode: .edit(stock))) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(stock.name)
                                        .font(.headline)
                                    Text(stock.code)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(stock.refreshInterval == 0 ? String(localized: "stockCard.manual") : "\(stock.refreshInterval)s")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteStocks)
                }
                
                NavigationLink(destination: AddEditStockView(mode: .add)) {
                    Label(String(localized: "settings.addStock"), systemImage: "plus")
                }
            }
            
            Section(String(localized: "settings.otherSettings")) {
                NavigationLink(destination: AppearanceSettingsView()) {
                    Label(String(localized: "settings.appearance"), systemImage: "paintbrush")
                }
                NavigationLink(destination: LanguageSettingsView()) {
                    Label(String(localized: "settings.language"), systemImage: "globe")
                }
            }
        }
        .navigationTitle(String(localized: "settings.title"))
    }
    
    private func deleteStocks(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(stocks[index])
            }
        }
    }
}
