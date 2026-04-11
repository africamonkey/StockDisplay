import SwiftUI
import SwiftData
import UserNotifications

enum AppNavigationDestination: Hashable {
    case settings
    case addStock
    case editStock(StockConfig)
}

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.fontScale) private var fontScale
    @Query(sort: \StockConfig.sortOrder) private var stocks: [StockConfig]
    @Query(sort: \DataSourceConfig.sortOrder) private var dataSources: [DataSourceConfig]
    @AppStorage("stockListTwoColumns") private var stockListTwoColumns: Bool = false
    
    @State private var currentDate = Date()
    @State private var stockStates: [UUID: StockLoadState] = [:]
    @State private var timer: Timer?
    @State private var refreshTask: Task<Void, Never>?
    @State private var lastRefresh: [UUID: Date] = [:]
    @State private var navigationPath = NavigationPath()
    @State private var highlightedStocks: Set<UUID> = []
    @State private var stockToConfirmDeleteAlerts: StockConfig?
    @Query private var allAlerts: [PriceAlert]
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
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
                    HStack(spacing: 16) {
                        Button {
                            refreshAllStocks()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        Button {
                            navigationPath.append(AppNavigationDestination.settings)
                        } label: {
                            Image(systemName: "gear")
                        }
                    }
                }
            }
            .navigationDestination(for: AppNavigationDestination.self) { destination in
                switch destination {
                case .settings:
                    SettingsView(navigationPath: $navigationPath)
                case .addStock:
                    AddEditStockView(mode: .add)
                case .editStock(let stock):
                    AddEditStockView(mode: .edit(stock))
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
        .confirmationDialog(
            String(localized: "dashboard.alert.deleteConfirmTitle"),
            isPresented: Binding(
                get: { stockToConfirmDeleteAlerts != nil },
                set: { if !$0 { stockToConfirmDeleteAlerts = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(String(localized: "dashboard.alert.delete")) {
                if let stock = stockToConfirmDeleteAlerts {
                    deleteTriggeredAlerts(for: stock)
                }
            }
            Button(String(localized: "common.cancel"), role: .cancel) {
                stockToConfirmDeleteAlerts = nil
            }
        } message: {
            Text(String(localized: "dashboard.alert.deleteConfirmMessage"))
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text(String(localized: "dashboard.noStocksAdded"))
                .font(.headline)
            HStack {
                Text(String(localized: "dashboard.tap"))
                Image(systemName: "gear")
                Text(String(localized: "dashboard.toAddStocks"))
            }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var stockList: some View {
        GeometryReader { geometry in
            ScrollView {
                if stockListTwoColumns {
                    twoColumnGrid(geometry: geometry)
                } else {
                    singleColumnList(geometry: geometry)
                }
            }
            .refreshable {
                await refreshAllStocksAsync()
            }
        }
    }
    
    private func singleColumnList(geometry: GeometryProxy) -> some View {
        LazyVStack(spacing: 6) {
            ForEach(stocks) { stock in
                StockCardView(
                    name: stock.name,
                    code: stock.code,
                    loadState: stockStates[stock.id] ?? .idle,
                    isHighlighted: highlightedStocks.contains(stock.id),
                    onTap: highlightedStocks.contains(stock.id) ? { stockToConfirmDeleteAlerts = stock } : nil
                )
            }
        }
        .padding(.horizontal, horizontalPadding(in: geometry.size.width))
    }
    
    private func twoColumnGrid(geometry: GeometryProxy) -> some View {
        let horizontalPadding: CGFloat = 16
        let columnWidth = (geometry.size.width - horizontalPadding * 2 - 6) / 2
        return LazyVGrid(columns: [GridItem(.fixed(columnWidth)), GridItem(.fixed(columnWidth))], spacing: 6) {
            ForEach(stocks) { stock in
                StockCardView(
                    name: stock.name,
                    code: stock.code,
                    loadState: stockStates[stock.id] ?? .idle,
                    isHighlighted: highlightedStocks.contains(stock.id),
                    onTap: highlightedStocks.contains(stock.id) ? { stockToConfirmDeleteAlerts = stock } : nil
                )
            }
        }
        .padding(.horizontal, horizontalPadding)
    }
    
    private func horizontalPadding(in width: CGFloat) -> CGFloat {
        let maxWidth: CGFloat = 600
        if width > maxWidth {
            return (width - maxWidth) / 2 + 16
        }
        return 16
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
        guard let dataSource = dataSources.first(where: { $0.id == stock.dataSourceId }) else {
            stockStates[stock.id] = .error("Data source not found")
            return
        }
        
        do {
            let data = try await StockAPIService.shared.fetchStockData(
                code: stock.code,
                apiURL: dataSource.apiURL,
                priceJSONPath: dataSource.priceJSONPath,
                changeJSONPath: dataSource.changeJSONPath
            )
            stockStates[stock.id] = .loaded(price: data.price, change: data.change)
            if case .loaded(price: let price, change: _) = stockStates[stock.id] {
                checkAlerts(for: stock, currentPrice: price)
            }
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
                guard let dataSource = dataSources.first(where: { $0.id == stock.dataSourceId }) else {
                    stockStates[stock.id] = .error("Data source not found")
                    continue
                }
                
                group.addTask {
                    do {
                        let data = try await StockAPIService.shared.fetchStockData(
                            code: stock.code,
                            apiURL: dataSource.apiURL,
                            priceJSONPath: dataSource.priceJSONPath,
                            changeJSONPath: dataSource.changeJSONPath
                        )
                        return (stock.id, .loaded(price: data.price, change: data.change))
                    } catch {
                        return (stock.id, .error(error.localizedDescription))
                    }
                }
            }
            
            for await (id, state) in group {
                stockStates[id] = state
            }
            
            for stock in stocks {
                if case .loaded(price: let price, change: _) = stockStates[stock.id] {
                    checkAlerts(for: stock, currentPrice: price)
                }
            }
        }
    }
    
    private func checkAlerts(for stock: StockConfig, currentPrice: Double) {
        let stockAlerts = allAlerts.filter {
            $0.stockId == stock.id && $0.isEnabled && !$0.hasTriggered
        }
        
        for alert in stockAlerts {
            var shouldTrigger = false
            switch alert.alertType {
            case .upper:
                shouldTrigger = currentPrice >= alert.targetPrice
            case .lower:
                shouldTrigger = currentPrice <= alert.targetPrice
            }
            
            if shouldTrigger {
                alert.hasTriggered = true
                highlightedStocks.insert(stock.id)
                try? modelContext.save()
                NotificationService.shared.sendAlertNotification(
                    stockName: stock.name,
                    stockCode: stock.code,
                    alertType: alert.alertType,
                    currentPrice: currentPrice,
                    targetPrice: alert.targetPrice
                )
            }
        }
    }
    
    private func deleteTriggeredAlerts(for stock: StockConfig) {
        let triggeredAlerts = allAlerts.filter {
            $0.stockId == stock.id && $0.hasTriggered
        }
        for alert in triggeredAlerts {
            modelContext.delete(alert)
        }
        highlightedStocks.remove(stock.id)
        stockToConfirmDeleteAlerts = nil
    }
}

class NotificationService {
    static let shared = NotificationService()
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }
    
    func sendAlertNotification(stockName: String, stockCode: String, alertType: AlertType, currentPrice: Double, targetPrice: Double) {
        let content = UNMutableNotificationContent()
        content.title = "\(stockName) (\(stockCode))"
        content.body = "[\(alertType.notificationKeyword)] \(stockName) 现价 \(String(format: "%.2f", currentPrice))，已达到您的目标价 \(String(format: "%.2f", targetPrice))"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
