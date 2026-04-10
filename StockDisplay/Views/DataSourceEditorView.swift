import SwiftUI
import SwiftData

struct DataSourceEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let dataSource: DataSourceConfig?
    
    @State private var name: String = ""
    @State private var apiURL: String = ""
    @State private var priceJSONPath: String = ""
    @State private var changeJSONPath: String = ""
    @State private var testCode: String = ""
    @State private var testResult: TestResult = .idle
    
    enum TestResult: Equatable {
        case idle
        case testing
        case success(price: Double, change: Double)
        case error(String)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(String(localized: "dataSource.basicInfo")) {
                    LabeledContent(String(localized: "dataSource.name")) {
                        TextField("", text: $name)
                    }
                }
                
                Section(String(localized: "dataSource.apiConfig")) {
                    LabeledContent(String(localized: "dataSource.apiURL")) {
                        TextField("https://api.example.com?q={code}", text: $apiURL)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.URL)
                    }
                    LabeledContent(String(localized: "dataSource.pricePath")) {
                        TextField("data.price", text: $priceJSONPath)
                            .textInputAutocapitalization(.never)
                    }
                    LabeledContent(String(localized: "dataSource.changePath")) {
                        TextField("data.change", text: $changeJSONPath)
                            .textInputAutocapitalization(.never)
                    }
                }
                
                Section(String(localized: "dataSource.test")) {
                    LabeledContent(String(localized: "dataSource.testStockCode")) {
                        TextField("AAPL or 600519", text: $testCode)
                            .textInputAutocapitalization(.never)
                    }
                    
                    Button(String(localized: "dataSource.testButton")) {
                        Task { await testDataSource() }
                    }
                    .disabled(testCode.isEmpty || apiURL.isEmpty || priceJSONPath.isEmpty || changeJSONPath.isEmpty)
                    
                    switch testResult {
                    case .idle:
                        EmptyView()
                    case .testing:
                        ProgressView()
                    case .success(let price, let change):
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(String(format: "Price: %.2f, Change: %.2f%%", price, change))
                        }
                    case .error(let message):
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            Text(message)
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle(dataSource == nil ? String(localized: "dataSource.title.add") : String(localized: "dataSource.title.edit"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "common.cancel")) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "common.save")) {
                        saveDataSource()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let dataSource = dataSource {
                    name = dataSource.name
                    apiURL = dataSource.apiURL
                    priceJSONPath = dataSource.priceJSONPath
                    changeJSONPath = dataSource.changeJSONPath
                }
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty && !apiURL.isEmpty && !priceJSONPath.isEmpty && !changeJSONPath.isEmpty
    }
    
    private func testDataSource() async {
        testResult = .testing
        do {
            let result = try await StockAPIService.shared.testDataSource(
                apiURL: apiURL,
                priceJSONPath: priceJSONPath,
                changeJSONPath: changeJSONPath,
                stockCode: testCode
            )
            testResult = .success(price: result.price, change: result.change)
        } catch {
            testResult = .error(error.localizedDescription)
        }
    }
    
    private func saveDataSource() {
        if let existing = dataSource {
            existing.name = name
            existing.apiURL = apiURL
            existing.priceJSONPath = priceJSONPath
            existing.changeJSONPath = changeJSONPath
        } else {
            let descriptor = FetchDescriptor<DataSourceConfig>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
            let existingDataSources = (try? modelContext.fetch(descriptor)) ?? []
            let newSortOrder = (existingDataSources.first?.sortOrder ?? -1) + 1
            
            let newDataSource = DataSourceConfig(
                name: name,
                apiURL: apiURL,
                priceJSONPath: priceJSONPath,
                changeJSONPath: changeJSONPath,
                sortOrder: newSortOrder
            )
            modelContext.insert(newDataSource)
        }
        dismiss()
    }
}
