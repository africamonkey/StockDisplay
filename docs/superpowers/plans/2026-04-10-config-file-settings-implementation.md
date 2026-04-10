# Config File Settings Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add "Config File" option in "Other Settings" for import/export stocks and data sources as JSON.

**Architecture:** New ConfigFileSettingsView with import (URL, clipboard, file) and export (file, clipboard) functionality. Data appended directly without conflict handling.

**Tech Stack:** SwiftUI, SwiftData, URLSession, UIDocumentPickerViewController, Codable

---

## File Structure

- Create: `StockDisplay/Views/ConfigFileSettingsView.swift`
- Modify: `StockDisplay/Views/SettingsView.swift`
- Modify: `StockDisplay/Localizable.xcstrings`

---

### Task 1: Add localization strings

**Files:**
- Modify: `StockDisplay/Localizable.xcstrings`

- [ ] **Step 1: Add localization strings**

Add the following entries to `Localizable.xcstrings` (insert before the closing `}` at line 1343):

```json
    "settings.configFile" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Config File"
          }
        },
        "zh-Hans" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "配置文件"
          }
        }
      }
    },
    "configFile.title" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Config File"
          }
        },
        "zh-Hans" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "配置文件"
          }
        }
      }
    },
    "configFile.import" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Import"
          }
        },
        "zh-Hans" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "导入"
          }
        }
      }
    },
    "configFile.importFromURL" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Import from URL"
          }
        },
        "zh-Hans" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "从URL下载"
          }
        }
      }
    },
    "configFile.importFromClipboard" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Import from Clipboard"
          }
        },
        "zh-Hans" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "从剪贴板导入"
          }
        }
      }
    },
    "configFile.importFromFile" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Import from File"
          }
        },
        "zh-Hans" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "从文件中导入"
          }
        }
      }
    },
    "configFile.export" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Export"
          }
        },
        "zh-Hans" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "导出"
          }
        }
      }
    },
    "configFile.exportToFile" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Export to File"
          }
        },
        "zh-Hans" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "导出到文件"
          }
        }
      }
    },
    "configFile.exportToClipboard" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Export to Clipboard"
          }
        },
        "zh-Hans" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "导出到剪贴板"
          }
        }
      }
    },
    "configFile.importing" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Importing..."
          }
        },
        "zh-Hans" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "导入中..."
          }
        }
      }
    },
    "configFile.exporting" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Exporting..."
          }
        },
        "zh-Hans" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "导出中..."
          }
        }
      }
    },
    "configFile.importSuccess" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Import successful"
          }
        },
        "zh-Hans" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "导入成功"
          }
        }
      }
    },
    "configFile.exportSuccess" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Export successful"
          }
        },
        "zh-Hans" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "导出成功"
          }
        }
      }
    },
    "configFile.importError" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Import failed"
          }
        },
        "zh-Hans" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "导入失败"
          }
        }
      }
    },
    "configFile.exportError" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Export failed"
          }
        },
        "zh-Hans" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "导出失败"
          }
        }
      }
    },
    "configFile.urlPlaceholder" : {
      "localizations" : {
        "en" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "Enter URL..."
          }
        },
        "zh-Hans" : {
          "stringUnit" : {
            "state" : "translated",
            "value" : "输入URL..."
          }
        }
      }
    }
```

- [ ] **Step 2: Verify JSON is valid**

Run: `cd /Users/africamonkey/work/StockDisplay && python3 -c "import json; json.load(open('StockDisplay/Localizable.xcstrings'))" && echo "Valid JSON"`

- [ ] **Step 3: Commit**

```bash
git add StockDisplay/Localizable.xcstrings && git commit -m "feat: add config file localization strings"
```

---

### Task 2: Create ConfigFileSettingsView

**Files:**
- Create: `StockDisplay/Views/ConfigFileSettingsView.swift`

- [ ] **Step 1: Write ConfigFileSettingsView.swift**

```swift
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ConfigFileSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StockConfig.sortOrder) private var stocks: [StockConfig]
    @Query(sort: \DataSourceConfig.sortOrder) private var dataSources: [DataSourceConfig]
    
    @State private var urlText: String = ""
    @State private var isImporting: Bool = false
    @State private var isExporting: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showingImporter: Bool = false
    @State private var showingExporter: Bool = false
    @State private var exportedData: Data?
    
    var body: some View {
        List {
            Section(String(localized: "configFile.import")) {
                Button {
                    importFromURL()
                } label: {
                    HStack {
                        Label(String(localized: "configFile.importFromURL"), systemImage: "link")
                        Spacer()
                        if isImporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isImporting || urlText.isEmpty)
                
                HStack {
                    TextField(String(localized: "configFile.urlPlaceholder"), text: $urlText)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Button {
                    importFromClipboard()
                } label: {
                    Label(String(localized: "configFile.importFromClipboard"), systemImage: "doc.on.clipboard")
                }
                
                Button {
                    showingImporter = true
                } label: {
                    Label(String(localized: "configFile.importFromFile"), systemImage: "doc.badge.plus")
                }
            }
            
            Section(String(localized: "configFile.export")) {
                Button {
                    exportToFile()
                } label: {
                    HStack {
                        Label(String(localized: "configFile.exportToFile"), systemImage: "square.and.arrow.up")
                        Spacer()
                        if isExporting {
                            ProgressView()
                        }
                    }
                }
                .disabled(isExporting)
                
                Button {
                    exportToClipboard()
                } label: {
                    Label(String(localized: "configFile.exportToClipboard"), systemImage: "clipboard")
                }
                .disabled(isExporting)
            }
        }
        .navigationTitle(String(localized: "configFile.title"))
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingImporter) {
            DocumentPicker(contentTypes: [.json]) { data in
                importData(data)
            }
        }
        .sheet(isPresented: $showingExporter) {
            DocumentExporter(data: exportedData) { success in
                if success {
                    alertTitle = String(localized: "configFile.exportSuccess")
                    alertMessage = ""
                    showingAlert = true
                }
            }
        }
    }
    
    private func importFromURL() {
        guard let url = URL(string: urlText) else {
            alertTitle = String(localized: "configFile.importError")
            alertMessage = "Invalid URL"
            showingAlert = true
            return
        }
        
        isImporting = true
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isImporting = false
                if let error = error {
                    alertTitle = String(localized: "configFile.importError")
                    alertMessage = error.localizedDescription
                    showingAlert = true
                    return
                }
                guard let data = data else {
                    alertTitle = String(localized: "configFile.importError")
                    alertMessage = "No data received"
                    showingAlert = true
                    return
                }
                importData(data)
            }
        }.resume()
    }
    
    private func importFromClipboard() {
        #if os(iOS)
        if let string = UIPasteboard.general.string, let data = string.data(using: .utf8) {
            importData(data)
        } else {
            alertTitle = String(localized: "configFile.importError")
            alertMessage = "Clipboard is empty or invalid"
            showingAlert = true
        }
        #endif
    }
    
    private func importData(_ data: Data) {
        do {
            let config = try JSONDecoder().decode(ConfigFileData.self, from: data)
            importStocks(config.stocks)
            importDataSources(config.dataSources)
            alertTitle = String(localized: "configFile.importSuccess")
            alertMessage = ""
            showingAlert = true
        } catch {
            alertTitle = String(localized: "configFile.importError")
            alertMessage = error.localizedDescription
            showingAlert = true
        }
    }
    
    private func importStocks(_ stockConfigs: [StockConfigData]) {
        let maxSortOrder = stocks.map(\.sortOrder).max() ?? 0
        for (index, stockData) in stockConfigs.enumerated() {
            let stock = StockConfig(
                id: UUID(),
                name: stockData.name,
                code: stockData.code,
                dataSourceId: stockData.dataSourceId,
                refreshInterval: stockData.refreshInterval,
                sortOrder: maxSortOrder + index + 1
            )
            modelContext.insert(stock)
        }
    }
    
    private func importDataSources(_ dataSourceConfigs: [DataSourceConfigData]) {
        let maxSortOrder = dataSources.map(\.sortOrder).max() ?? 0
        for (index, dsData) in dataSourceConfigs.enumerated() {
            let dataSource = DataSourceConfig(
                id: UUID(),
                name: dsData.name,
                apiURL: dsData.apiURL,
                priceJSONPath: dsData.priceJSONPath,
                changeJSONPath: dsData.changeJSONPath,
                sortOrder: maxSortOrder + index + 1
            )
            modelContext.insert(dataSource)
        }
    }
    
    private func exportToFile() {
        isExporting = true
        let data = buildExportData()
        exportedData = data
        isExporting = false
        showingExporter = true
    }
    
    private func exportToClipboard() {
        isExporting = true
        let data = buildExportData()
        #if os(iOS)
        UIPasteboard.general.string = String(data: data, encoding: .utf8)
        #endif
        isExporting = false
        alertTitle = String(localized: "configFile.exportSuccess")
        alertMessage = ""
        showingAlert = true
    }
    
    private func buildExportData() -> Data {
        let stockData = stocks.map { stock in
            StockConfigData(
                id: stock.id,
                name: stock.name,
                code: stock.code,
                dataSourceId: stock.dataSourceId,
                refreshInterval: stock.refreshInterval,
                sortOrder: stock.sortOrder
            )
        }
        let dataSourceData = dataSources.map { ds in
            DataSourceConfigData(
                id: ds.id,
                name: ds.name,
                apiURL: ds.apiURL,
                priceJSONPath: ds.priceJSONPath,
                changeJSONPath: ds.changeJSONPath,
                sortOrder: ds.sortOrder
            )
        }
        let config = ConfigFileData(version: 1, stocks: stockData, dataSources: dataSourceData)
        return (try? JSONEncoder().encode(config)) ?? Data()
    }
}

struct ConfigFileData: Codable {
    let version: Int
    let stocks: [StockConfigData]
    let dataSources: [DataSourceConfigData]
}

struct StockConfigData: Codable {
    let id: UUID
    let name: String
    let code: String
    let dataSourceId: UUID?
    let refreshInterval: Int
    let sortOrder: Int
}

struct DataSourceConfigData: Codable {
    let id: UUID
    let name: String
    let apiURL: String
    let priceJSONPath: String
    let changeJSONPath: String
    let sortOrder: Int
}

struct DocumentPicker: UIViewControllerRepresentable {
    let contentTypes: [UTType]
    let onPick: (Data) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (Data) -> Void
        
        init(onPick: @escaping (Data) -> Void) {
            self.onPick = onPick
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            guard let data = try? Data(contentsOf: url) else { return }
            onPick(data)
        }
    }
}

struct DocumentExporter: UIViewControllerRepresentable {
    let data: Data?
    let onFinish: (Bool) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("stock_config.json")
        if let data = data {
            try? data.write(to: tempURL)
        }
        let picker = UIDocumentPickerViewController(forExporting: [tempURL])
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: onFinish)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onFinish: (Bool) -> Void
        
        init(onFinish: @escaping (Bool) -> Void) {
            self.onFinish = onFinish
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onFinish(true)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onFinish(false)
        }
    }
}
```

- [ ] **Step 2: Verify build**

Run: `cd /Users/africamonkey/work/StockDisplay && xcodebuild -scheme StockDisplay -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add StockDisplay/Views/ConfigFileSettingsView.swift && git commit -m "feat: add ConfigFileSettingsView with import/export functionality"
```

---

### Task 3: Add navigation link in SettingsView

**Files:**
- Modify: `StockDisplay/Views/SettingsView.swift:88-93`

- [ ] **Step 1: Add NavigationLink to SettingsView**

In `SettingsView.swift`, find the "Other Settings" section (lines 88-93):

```swift
Section(String(localized: "settings.otherSettings")) {
    Toggle(String(localized: "settings.keepScreenOn"), systemImage: "display", isOn: $keepScreenOn)
    NavigationLink(destination: AppearanceSettingsView()) {
        Label(String(localized: "settings.appearance"), systemImage: "paintbrush")
    }
}
```

Replace with:

```swift
Section(String(localized: "settings.otherSettings")) {
    Toggle(String(localized: "settings.keepScreenOn"), systemImage: "display", isOn: $keepScreenOn)
    NavigationLink(destination: AppearanceSettingsView()) {
        Label(String(localized: "settings.appearance"), systemImage: "paintbrush")
    }
    NavigationLink(destination: ConfigFileSettingsView()) {
        Label(String(localized: "settings.configFile"), systemImage: "doc.fill")
    }
}
```

- [ ] **Step 2: Verify build**

Run: `cd /Users/africamonkey/work/StockDisplay && xcodebuild -scheme StockDisplay -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -20`

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add StockDisplay/Views/SettingsView.swift && git commit -m "feat: add navigation to ConfigFileSettingsView"
```

---

## Spec Coverage

| Requirement | Status |
|-------------|--------|
| Add "Config File" in Other Settings | ✅ Task 3 |
| Import from URL | ✅ Task 2 |
| Import from Clipboard | ✅ Task 2 |
| Import from File | ✅ Task 2 |
| Export to File | ✅ Task 2 |
| Export to Clipboard | ✅ Task 2 |
| JSON format with version | ✅ Task 2 |
| Direct append (no conflict handling) | ✅ Task 2 |

---

**Plan complete.** Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?