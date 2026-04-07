import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var stocks: [StockConfig]
    
    @State private var currentDate = Date()
    @State private var stockStates: [UUID: StockLoadState] = [:]
    @State private var timer: Timer?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dateTimeHeader
                    .padding()
                
                if stocks.isEmpty {
                    emptyState
                } else {
                    stockList
                }
            }
            .navigationTitle("Stock Display")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gear")
                    }
                }
            }
        }
        .onAppear {
            initializeStockStates()
            startTimer()
            refreshAllStocks()
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: stocks) { _, newStocks in
            let newIds = Set(newStocks.map { $0.id })
            let existingIds = Set(stockStates.keys)
            if newIds != existingIds {
                initializeStockStates()
            }
        }
    }
    
    private var dateTimeHeader: some View {
        VStack(spacing: 4) {
            Text(currentDate, format: .dateTime.weekday(.wide).month().day().year())
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(currentDate, format: .dateTime.hour().minute().second())
                .font(.title)
                .fontWeight(.bold)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 8)
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("No stocks added")
                .font(.headline)
            Text("Tap ⚙️ to add stocks")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var stockList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(stocks) { stock in
                    StockCardView(
                        name: stock.name,
                        code: stock.code,
                        loadState: stockStates[stock.id] ?? .idle
                    )
                }
            }
            .padding()
        }
        .refreshable {
            await refreshAllStocksAsync()
        }
    }
    
    private func initializeStockStates() {
        for stock in stocks {
            if stockStates[stock.id] == nil {
                stockStates[stock.id] = .idle
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            currentDate = Date()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func refreshAllStocks() {
        Task {
            await refreshAllStocksAsync()
        }
    }
    
    private func refreshAllStocksAsync() async {
        for stock in stocks {
            stockStates[stock.id] = .loading
        }
        
        await withTaskGroup(of: (UUID, StockLoadState).self) { group in
            for stock in stocks {
                group.addTask {
                    do {
                        let data = try await StockAPIService.shared.fetchStockData(config: stock)
                        return (stock.id, .loaded(price: data.price, change: data.change))
                    } catch {
                        return (stock.id, .error(error.localizedDescription))
                    }
                }
            }
            
            for await (id, state) in group {
                stockStates[id] = state
            }
        }
    }
}