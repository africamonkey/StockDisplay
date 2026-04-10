# 数据源自定义功能实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 移除内置腾讯财经/雪球数据源，改为用户自行添加和管理数据源

**Architecture:** 
- 新增 `DataSourceConfig` SwiftData 模型存储用户数据源
- SettingsView 新增数据源管理区块
- AddEditStockView 改为从用户数据源列表选择或新建
- 数据源测试功能：用户输入股票代码，调用 API 验证

**Tech Stack:** SwiftUI, SwiftData, URLSession

---

## 文件结构

| 文件 | 操作 | 职责 |
|------|------|------|
| `Models/DataSourceConfig.swift` | 创建 | 数据源 SwiftData 模型 |
| `Views/SettingsView.swift` | 修改 | 添加数据源管理 UI |
| `Views/AddEditStockView.swift` | 修改 | 移除模板，改用数据源选择 |
| `Views/DataSourceEditorView.swift` | 创建 | 数据源添加/编辑 Sheet（含测试） |
| `StockDisplayApp.swift` | 修改 | Schema 注册 DataSourceConfig |
| `Services/StockAPIService.swift` | 修改 | 添加测试数据源方法 |

---

## Task 1: 创建 DataSourceConfig 模型

**Files:**
- Create: `StockDisplay/Models/DataSourceConfig.swift`

- [ ] **Step 1: 创建模型文件**

```swift
import Foundation
import SwiftData

@Model
final class DataSourceConfig {
    var id: UUID
    var name: String
    var apiURL: String
    var priceJSONPath: String
    var changeJSONPath: String
    var sortOrder: Int

    init(
        id: UUID = UUID(),
        name: String,
        apiURL: String,
        priceJSONPath: String,
        changeJSONPath: String,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.apiURL = apiURL
        self.priceJSONPath = priceJSONPath
        self.changeJSONPath = changeJSONPath
        self.sortOrder = sortOrder
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add StockDisplay/Models/DataSourceConfig.swift
git commit -m "feat: add DataSourceConfig SwiftData model"
```

---

## Task 2: 注册 DataSourceConfig 到 ModelContainer

**Files:**
- Modify: `StockDisplay/StockDisplayApp.swift:21-23`

- [ ] **Step 1: 修改 Schema 注册**

```swift
let schema = Schema([
    StockConfig.self,
    DataSourceConfig.self,
])
```

- [ ] **Step 2: 提交**

```bash
git add StockDisplay/StockDisplayApp.swift
git commit -m "feat: register DataSourceConfig in model container"
```

---

## Task 3: 添加数据源测试方法到 StockAPIService

**Files:**
- Modify: `StockDisplay/Services/StockAPIService.swift`

- [ ] **Step 1: 添加测试数据源方法**

在 `StockAPIService` actor 中添加:

```swift
func testDataSource(
    apiURL: String,
    priceJSONPath: String,
    changeJSONPath: String,
    stockCode: String
) async throws -> StockData {
    let urlString = apiURL.replacingOccurrences(of: "{code}", with: stockCode)
    guard let url = URL(string: urlString) else {
        throw StockAPIError.invalidURL
    }
    
    let data: Data
    do {
        let (responseData, response) = try await URLSession.shared.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw StockAPIError.invalidResponse
        }
        data = responseData
    } catch let error as StockAPIError {
        throw error
    } catch {
        throw StockAPIError.networkError(error)
    }
    
    let json: Any
    do {
        json = try JSONSerialization.jsonObject(with: data)
    } catch {
        throw StockAPIError.decodingError(error)
    }
    
    do {
        let price = try extractDouble(from: json, path: priceJSONPath)
        let change = try extractDouble(from: json, path: changeJSONPath)
        return StockData(price: price, change: change)
    } catch {
        throw StockAPIError.decodingError(error)
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add StockDisplay/Services/StockAPIService.swift
git commit -m "feat: add testDataSource method to StockAPIService"
```

---

## Task 4: 创建 DataSourceEditorView

**Files:**
- Create: `StockDisplay/Views/DataSourceEditorView.swift`

- [ ] **Step 1: 创建视图文件**

```swift
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
```

- [ ] **Step 2: 提交**

```bash
git add StockDisplay/Views/DataSourceEditorView.swift
git commit -m "feat: add DataSourceEditorView with test functionality"
```

---

## Task 5: 修改 SettingsView 添加数据源管理

**Files:**
- Modify: `StockDisplay/Views/SettingsView.swift`

- [ ] **Step 1: 添加数据源 Section**

在 `SettingsView.swift` 中:

1. 添加 `@Query` 获取数据源:
```swift
@Query(sort: \DataSourceConfig.sortOrder) private var dataSources: [DataSourceConfig]
```

2. 添加 state 和 sheet:
```swift
@State private var showingDataSourceEditor = false
@State private var editingDataSource: DataSourceConfig?
```

3. 在 `Section(String(localized: "settings.otherSettings"))` 前添加新 Section:
```swift
Section(String(localized: "settings.dataSourceSettings")) {
    if dataSources.isEmpty {
        Text(String(localized: "settings.noDataSources"))
            .foregroundStyle(.secondary)
    } else {
        ForEach(dataSources) { dataSource in
            Button {
                editingDataSource = dataSource
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(dataSource.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(dataSource.apiURL)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
        .onDelete(perform: deleteDataSources)
    }
    
    Button {
        editingDataSource = nil
        showingDataSourceEditor = true
    } label: {
        Label(String(localized: "settings.addDataSource"), systemImage: "plus")
    }
}
.sheet(isPresented: $showingDataSourceEditor) {
    DataSourceEditorView(dataSource: editingDataSource)
}
```

4. 添加 `deleteDataSources` 方法:
```swift
private func deleteDataSources(offsets: IndexSet) {
    withAnimation {
        for index in offsets {
            modelContext.delete(dataSources[index])
        }
    }
}
```

- [ ] **Step 2: 提交**

```bash
git add StockDisplay/Views/SettingsView.swift
git commit -m "feat: add data source management section to SettingsView"
```

---

## Task 6: 修改 AddEditStockView 使用数据源

**Files:**
- Modify: `StockDisplay/Views/AddEditStockView.swift`

- [ ] **Step 1: 移除 StockTemplate 枚举和模板相关代码**

移除 `StockTemplate` 枚举 (lines 4-8)

- [ ] **Step 2: 添加数据源相关状态**

```swift
@Query(sort: \DataSourceConfig.sortOrder) private var dataSources: [DataSourceConfig]
@State private var selectedDataSource: DataSourceConfig?
@State private var showingDataSourceEditor = false
```

- [ ] **Step 3: 重写 body - 用数据源选择替换模板选择**

将整个 Form 内容替换为:

```swift
Form {
    Section(String(localized: "addEditStock.dataSource")) {
        Picker(String(localized: "addEditStock.selectDataSource"), selection: $selectedDataSource) {
            Text(String(localized: "addEditStock.selectDataSourcePlaceholder"))
                .tag(nil as DataSourceConfig?)
            ForEach(dataSources) { ds in
                Text(ds.name).tag(ds as DataSourceConfig?)
            }
        }
        
        Button {
            showingDataSourceEditor = true
        } label: {
            Label(String(localized: "addEditStock.addNewDataSource"), systemImage: "plus.circle")
        }
    }
    
    if let dataSource = selectedDataSource {
        Section(String(localized: "addEditStock.stockInfo")) {
            LabeledContent(String(localized: "addEditStock.displayName")) {
                TextField("", text: $name)
            }
            LabeledContent(String(localized: "addEditStock.code")) {
                TextField("", text: $code)
                    .textInputAutocapitalization(.never)
            }
        }
        
        Section(String(localized: "addEditStock.apiConfig")) {
            LabeledContent(String(localized: "addEditStock.apiURL")) {
                Text(dataSource.apiURL.replacingOccurrences(of: "{code}", with: code.isEmpty ? "{code}" : code))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            LabeledContent(String(localized: "addEditStock.pricePath")) {
                Text(dataSource.priceJSONPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            LabeledContent(String(localized: "addEditStock.changePath")) {
                Text(dataSource.changeJSONPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        
        Section(String(localized: "addEditStock.refreshInterval")) {
            Picker(String(localized: "addEditStock.refresh"), selection: $refreshInterval) {
                Text(String(localized: "addEditStock.10seconds")).tag(10)
                Text(String(localized: "addEditStock.30seconds")).tag(30)
                Text(String(localized: "addEditStock.1minute")).tag(60)
                Text(String(localized: "addEditStock.5minutes")).tag(300)
            }
        }
    }
}
.sheet(isPresented: $showingDataSourceEditor) {
    DataSourceEditorView(dataSource: nil)
}
.onChange(of: dataSources) { _, newValue in
    if selectedDataSource == nil && !newValue.isEmpty {
        selectedDataSource = newValue.first
    }
}
```

- [ ] **Step 4: 更新 isValid 计算属性**

```swift
private var isValid: Bool {
    selectedDataSource != nil && !name.isEmpty && !code.isEmpty
}
```

- [ ] **Step 5: 更新 populateFromStock 方法**

```swift
private func populateFromStock(_ stock: StockConfig) {
    name = stock.name
    code = stock.code
    refreshInterval = stock.refreshInterval
    
    selectedDataSource = dataSources.first { ds in
        ds.apiURL == stock.apiURL &&
        ds.priceJSONPath == stock.priceJSONPath &&
        ds.changeJSONPath == stock.changeJSONPath
    }
}
```

- [ ] **Step 6: 更新 saveStock 方法**

替换整个 saveStock 方法体:

```swift
private func saveStock() {
    guard let dataSource = selectedDataSource else { return }
    
    let url = dataSource.apiURL.replacingOccurrences(of: "{code}", with: code)
    
    if case .edit(let existing) = mode {
        existing.name = name
        existing.code = code
        existing.apiURL = url
        existing.priceJSONPath = dataSource.priceJSONPath
        existing.changeJSONPath = dataSource.changeJSONPath
        existing.refreshInterval = refreshInterval
        dismiss()
        return
    }
    
    let newSortOrder: Int = {
        let descriptor = FetchDescriptor<StockConfig>(sortBy: [SortDescriptor(\.sortOrder, order: .reverse)])
        let existingStocks = (try? modelContext.fetch(descriptor)) ?? []
        return (existingStocks.first?.sortOrder ?? -1) + 1
    }()
    
    let config = StockConfig(
        name: name,
        code: code,
        apiURL: url,
        priceJSONPath: dataSource.priceJSONPath,
        changeJSONPath: dataSource.changeJSONPath,
        refreshInterval: refreshInterval,
        sortOrder: newSortOrder
    )
    
    modelContext.insert(config)
    dismiss()
}
```

- [ ] **Step 7: 提交**

```bash
git add StockDisplay/Views/AddEditStockView.swift
git commit -m "feat: refactor AddEditStockView to use user-defined data sources"
```

---

## Task 7: 添加本地化字符串

**Files:**
- 需要在 Localizable.xcstrings 中添加以下 key:
  - `dataSource.basicInfo`
  - `dataSource.name`
  - `dataSource.apiConfig`
  - `dataSource.apiURL`
  - `dataSource.pricePath`
  - `dataSource.changePath`
  - `dataSource.test`
  - `dataSource.testStockCode`
  - `dataSource.testButton`
  - `dataSource.title.add`
  - `dataSource.title.edit`
  - `settings.dataSourceSettings`
  - `settings.noDataSources`
  - `settings.addDataSource`
  - `addEditStock.dataSource`
  - `addEditStock.selectDataSource`
  - `addEditStock.selectDataSourcePlaceholder`
  - `addEditStock.addNewDataSource`
  - `common.cancel`
  - `common.save`

- [ ] **Step 1: 添加 Localizable strings（如果项目使用 xcstrings）**

根据项目现有格式添加 strings，或告知用户需要手动添加

- [ ] **Step 2: 提交**

---

## Task 8: 验证构建

**Files:**
- 无

- [ ] **Step 1: 运行 Xcode 构建**

```bash
xcodebuild -project StockDisplay.xcodeproj -scheme StockDisplay -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -50
```

---

## 实施检查清单

- [ ] Task 1: DataSourceConfig 模型创建
- [ ] Task 2: ModelContainer 注册
- [ ] Task 3: StockAPIService 测试方法
- [ ] Task 4: DataSourceEditorView 创建
- [ ] Task 5: SettingsView 数据源管理
- [ ] Task 6: AddEditStockView 重构
- [ ] Task 7: 本地化字符串
- [ ] Task 8: 构建验证
