import SwiftUI
import SwiftData

enum StockTemplate: String, CaseIterable {
    case tencentFinance = "Tencent"
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
    
    @State private var template: StockTemplate = .tencentFinance
    @State private var name: String = ""
    @State private var code: String = ""
    @State private var apiURL: String = ""
    @State private var priceJSONPath: String = ""
    @State private var changeJSONPath: String = ""
    @State private var refreshInterval: Int = 60
    
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
            
            if template == .tencentFinance {
                Section("Stock Info") {
                    LabeledContent("Display Name") {
                        TextField("", text: $name)
                    }
                    LabeledContent("Code") {
                        TextField("", text: $code).autocapitalization(UITextAutocapitalizationType.none)
                        Text("Example: usAAPL.OQ, hk00700, sh000001")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("API Configuration") {
                    LabeledContent("API URL") {
                        Text("https://web.ifzq.gtimg.cn/portable/mobile/qt/data?code={code}")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Price Path") {
                        Text("data.newpri")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    LabeledContent("Change Path") {
                        Text("data.zdf")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Refresh Interval") {
                    Picker("Refresh", selection: $refreshInterval) {
                        Text("10 seconds").tag(10)
                        Text("30 seconds").tag(30)
                        Text("1 minute").tag(60)
                        Text("5 minutes").tag(300)
                    }
                }
            } else {
                Section("Stock Info") {
                    LabeledContent("Display Name") {
                        TextField("", text: $name)
                    }
                    LabeledContent("Code") {
                        TextField("", text: $code)
                    }
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
                        Text("10 seconds").tag(10)
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
        if template == .tencentFinance {
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
        template = stock.apiURL.contains("web.ifzq.gtimg.cn") ? .tencentFinance : .custom
    }
    
    private func saveStock() {
        let config: StockConfig
        
        if template == .tencentFinance {
            let url = "https://web.ifzq.gtimg.cn/portable/mobile/qt/data?code=\(code)"
            if case .edit(let existing) = mode {
                existing.name = name
                existing.code = code
                existing.apiURL = url
                existing.priceJSONPath = "data.newpri"
                existing.changeJSONPath = "data.zdf"
                existing.refreshInterval = refreshInterval
                dismiss()
                return
            }
            
            config = StockConfig(
                name: name,
                code: code,
                apiURL: url,
                priceJSONPath: "data.newpri",
                changeJSONPath: "data.zdf",
                refreshInterval: refreshInterval
            )
        } else {
            if case .edit(let existing) = mode {
                existing.name = name
                existing.code = code
                existing.apiURL = apiURL
                existing.priceJSONPath = priceJSONPath
                existing.changeJSONPath = changeJSONPath
                existing.refreshInterval = refreshInterval
                dismiss()
                return
            }
            
            config = StockConfig(
                name: name,
                code: code,
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
