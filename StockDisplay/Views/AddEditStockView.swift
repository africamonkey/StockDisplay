import SwiftUI
import SwiftData

enum StockTemplate: String, CaseIterable {
    case yahooFinance = "Yahoo Finance"
    case custom = "Custom"
}

enum AddEditMode {
    case add
    case edit(StockConfig)
}

struct AddEditStockView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let mode: AddEditMode
    
    @State private var template: StockTemplate = .yahooFinance
    @State private var name: String = ""
    @State private var code: String = ""
    @State private var apiURL: String = ""
    @State private var priceJSONPath: String = ""
    @State private var changeJSONPath: String = ""
    @State private var refreshInterval: Int = 60
    
    let refreshOptions = [0, 30, 60, 300]
    
    var body: some View {
        Form {
            Section("Template") {
                Picker("API Template", selection: $template) {
                    ForEach(StockTemplate.allCases, id: \.self) { t in
                        Text(t.rawValue).tag(t)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            if template == .yahooFinance {
                Section("Stock Info") {
                    TextField("Symbol (e.g., AAPL)", text: $code)
                        .textInputAutocapitalization(.characters)
                    TextField("Display Name", text: $name)
                }
                
                Section("API Configuration") {
                    LabeledContent("API URL") {
                        Text("https://query1.finance.yahoo.com/v8/finance/chart/{symbol}")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Price Path") {
                        Text("chart.result[0].meta.regularMarketPrice")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Change Path") {
                        Text("chart.result[0].meta.regularMarketChangePercent")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Refresh Interval") {
                    Picker("Refresh", selection: $refreshInterval) {
                        Text("Manual").tag(0)
                        Text("30 seconds").tag(30)
                        Text("1 minute").tag(60)
                        Text("5 minutes").tag(300)
                    }
                }
            } else {
                Section("Stock Info") {
                    TextField("Display Name", text: $name)
                    TextField("Symbol / Code", text: $code)
                        .textInputAutocapitalization(.characters)
                }
                
                Section("API Configuration") {
                    TextField("API URL", text: $apiURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                    TextField("Price JSON Path (e.g., data.price)", text: $priceJSONPath)
                        .textInputAutocapitalization(.never)
                    TextField("Change JSON Path (e.g., data.changePercent)", text: $changeJSONPath)
                        .textInputAutocapitalization(.never)
                }
                
                Section("Refresh Interval") {
                    Picker("Refresh", selection: $refreshInterval) {
                        Text("Manual").tag(0)
                        Text("30 seconds").tag(30)
                        Text("1 minute").tag(60)
                        Text("5 minutes").tag(300)
                    }
                }
            }
        }
        .navigationTitle(mode.isAdd ? "Add Stock" : "Edit Stock")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveStock()
                }
                .disabled(!isValid)
            }
        }
        .onAppear {
            if case .edit(let stock) = mode {
                populateFromStock(stock)
            }
        }
    }
    
    private var isValid: Bool {
        if template == .yahooFinance {
            return !name.isEmpty && !code.isEmpty
        } else {
            return !name.isEmpty && !code.isEmpty && !apiURL.isEmpty && !priceJSONPath.isEmpty && !changeJSONPath.isEmpty
        }
    }
    
    private func populateFromStock(_ stock: StockConfig) {
        name = stock.name
        code = stock.code
        apiURL = stock.apiURL
        priceJSONPath = stock.priceJSONPath
        changeJSONPath = stock.changeJSONPath
        refreshInterval = stock.refreshInterval
        template = stock.apiURL.contains("yahoo.com") ? .yahooFinance : .custom
    }
    
    private func saveStock() {
        let config: StockConfig
        
        if template == .yahooFinance {
            let url = "https://query1.finance.yahoo.com/v8/finance/chart/\(code)"
            config = StockConfig(
                name: name,
                code: code.uppercased(),
                apiURL: url,
                priceJSONPath: "chart.result[0].meta.regularMarketPrice",
                changeJSONPath: "chart.result[0].meta.regularMarketChangePercent",
                refreshInterval: refreshInterval
            )
        } else {
            if case .edit(let existing) = mode {
                existing.name = name
                existing.code = code.uppercased()
                existing.apiURL = apiURL
                existing.priceJSONPath = priceJSONPath
                existing.changeJSONPath = changeJSONPath
                existing.refreshInterval = refreshInterval
                dismiss()
                return
            }
            
            config = StockConfig(
                name: name,
                code: code.uppercased(),
                apiURL: apiURL,
                priceJSONPath: priceJSONPath,
                changeJSONPath: changeJSONPath,
                refreshInterval: refreshInterval
            )
        }
        
        modelContext.insert(config)
        dismiss()
    }
}

extension AddEditMode {
    var isAdd: Bool {
        if case .add = self { return true }
        return false
    }
}
