import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.fontScale) private var fontScale
    @Query private var stocks: [StockConfig]
    
    @State private var currentDate = Date()
    @State private var stockStates: [UUID: StockLoadState] = [:]
    @State private var timer: Timer?
    @State private var refreshTask: Task<Void, Never>?
    @State private var lastRefresh: [UUID: Date] = [:]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if stocks.isEmpty {
                    emptyState
                } else {
                    stockList
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text(currentDate, format: .dateTime.weekday(.wide).month().day().year())
                            .font(.system(size: 14 * fontScale))
                            .foregroundStyle(.secondary)
                        Text(currentDate, format: .dateTime.hour().minute().second())
                            .font(.system(size: 22 * fontScale, weight: .bold))
                            .monospacedDigit()
                    }
                }
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
            startAutoRefresh()
            refreshAllStocks()
        }
        .onDisappear {
            stopTimer()
            refreshTask?.cancel()
        }
        .onChange(of: stocks) { _, newStocks in
            let newIds = Set(newStocks.map { $0.id })
            let existingIds = Set(stockStates.keys)
            if newIds != existingIds {
                initializeStockStates()
            }
            refreshTask?.cancel()
            startAutoRefresh()
        }
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
            LazyVStack(spacing: 6) {
                ForEach(stocks) { stock in
                    StockCardView(
                        name: stock.name,
                        code: stock.code,
                        loadState: stockStates[stock.id] ?? .idle
                    )
                }
            }
            .padding(.horizontal)
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
            if lastRefresh[stock.id] == nil {
                lastRefresh[stock.id] = .distantPast
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.currentDate = Date()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func startAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                let now = Date()
                for stock in self.stocks {
                    if stock.refreshInterval > 0 {
                        let last = self.lastRefresh[stock.id] ?? .distantPast
                        if now.timeIntervalSince(last) >= Double(stock.refreshInterval) {
                            self.lastRefresh[stock.id] = now
                            await self.refreshStock(stock)
                        }
                    }
                }
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
    
    private func refreshStock(_ stock: StockConfig) async {
        do {
            let data = try await StockAPIService.shared.fetchStockData(config: stock)
            stockStates[stock.id] = .loaded(price: data.price, change: data.change)
        } catch {
            stockStates[stock.id] = .error(error.localizedDescription)
        }
    }
    
    private func refreshAllStocks() {
        Task {
            await refreshAllStocksAsync()
        }
    }
    
    private func refreshAllStocksAsync() async {
        for stock in stocks {
            stockStates[stock.id] = .loading
            lastRefresh[stock.id] = Date()
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
