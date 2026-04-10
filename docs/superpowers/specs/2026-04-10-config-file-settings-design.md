# Config File Settings Design

## Overview

Add a "Config File" option in "Other Settings" to allow users to import/export application configuration (stocks and data sources) as JSON files.

## Data Structure

### Export Format
```json
{
  "version": 1,
  "stocks": [
    {
      "id": "uuid",
      "name": "Apple",
      "code": "AAPL",
      "dataSourceId": "uuid",
      "refreshInterval": 60,
      "sortOrder": 0
    }
  ],
  "dataSources": [
    {
      "id": "uuid",
      "name": "Tencent",
      "apiURL": "https://...",
      "priceJSONPath": "data.price",
      "changeJSONPath": "data.change",
      "sortOrder": 0
    }
  ]
}
```

## UI Components

### SettingsView.swift
Add NavigationLink to ConfigFileSettingsView in "Other Settings" section:
```
Section("settings.otherSettings") {
    Toggle(...)
    NavigationLink(destination: AppearanceSettingsView()) { ... }
    NavigationLink(destination: ConfigFileSettingsView()) {
        Label(String(localized: "settings.configFile"), systemImage: "doc.fill")
    }
}
```

### ConfigFileSettingsView.swift (New File)
Two sections:

**Import Section:**
- "从URL下载" (Import from URL) — TextField for URL + Download button
- "从剪贴板导入" (Import from Clipboard) — Button to read clipboard
- "从文件导入" (Import from File) — Document picker for .json files

**Export Section:**
- "导出到文件" (Export to File) — Save JSON to file
- "导出到剪贴板" (Export to Clipboard) — Copy JSON to clipboard

## Import Logic

### Conflict Detection
- **Stock conflict:** Same `code` exists
- **DataSource conflict:** Same `name` exists

### Import Flow
1. Parse incoming JSON
2. Compare with existing data:
   - **No conflicts:** Auto-merge silently
   - **Conflicts exist:** For each conflicting item, show per-item alert with options:
     - **替换 (Replace)** — Replace existing with imported
     - **跳过 (Skip)** — Keep existing, discard imported
     - **取消全部 (Cancel All)** — Stop import, discard all imported

### Per-Item Conflict Alert
```
Alert title: "股票冲突" / "Stock Conflict"
Message: "股票 "{name}" ({code}) 已存在"
Buttons:
- "替换" (destructive) — Replace this item
- "跳过" — Skip this item  
- "取消全部" — Cancel entire import
```

## Localization Strings

| Key | English | 简体中文 |
|-----|---------|----------|
| settings.configFile | Config File | 配置文件 |
| configFile.title | Config File | 配置文件 |
| configFile.import | Import | 导入 |
| configFile.importFromURL | Import from URL | 从URL下载 |
| configFile.importFromClipboard | Import from Clipboard | 从剪贴板导入 |
| configFile.importFromFile | Import from File | 从文件中导入 |
| configFile.export | Export | 导出 |
| configFile.exportToFile | Export to File | 导出到文件 |
| configFile.exportToClipboard | Export to Clipboard | 导出到剪贴板 |
| configFile.importing | Importing... | 导入中... |
| configFile.exporting | Exporting... | 导出中... |
| configFile.importSuccess | Import successful | 导入成功 |
| configFile.exportSuccess | Export successful | 导出成功 |
| configFile.importError | Import failed | 导入失败 |
| configFile.exportError | Export failed | 导出失败 |
| configFile.stockConflict | Stock Conflict | 股票冲突 |
| configFile.dataSourceConflict | Data Source Conflict | 数据源冲突 |
| configFile.stockConflictMessage | Stock "{name}" ({code}) already exists | 股票 "{name}" ({code}) 已存在 |
| configFile.dataSourceConflictMessage | Data source "{name}" already exists | 数据源 "{name}" 已存在 |
| configFile.replace | Replace | 替换 |
| configFile.skip | Skip | 跳过 |
| configFile.cancelAll | Cancel All | 取消全部 |
| configFile.urlPlaceholder | Enter URL... | 输入URL... |

## Technical Approach

- Use SwiftData `ModelContext` for CRUD operations
- Use `URLSession` for URL downloads
- Use `UIPasteboard` (via `Clipboard` utility) for clipboard operations
- Use `UIDocumentPickerViewController` for file import
- Use `NSItemProvider` for file export
- Encode/decode using `Codable`
