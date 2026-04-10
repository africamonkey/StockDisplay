# 数据源自定义功能设计

## 概述

移除内置的腾讯财经和雪球数据源，改为用户自行添加和管理数据源。

## 数据模型

### 新增 DataSourceConfig (SwiftData)

```swift
@Model
final class DataSourceConfig {
    var id: UUID
    var name: String           // 显示名称
    var apiURL: String        // 包含 {code} 占位符
    var priceJSONPath: String // JSON 路径
    var changeJSONPath: String
    var sortOrder: Int
}
```

### 修改 StockConfig

- 移除 `template` 属性（之前用于区分内置模板）
- 现有使用内置模板的股票，通过 URL 识别并自动关联

## SettingsView 改动

新增 **"数据源设置"** Section：

| 操作 | 行为 |
|------|------|
| 列表 | 显示所有用户数据源，支持左滑删除 |
| 添加 | "+" 按钮 → Sheet 表单 |
| 编辑 | 点击 → Sheet 表单 |

### 添加/编辑数据源表单

字段：
- 名称 (TextField)
- API URL (TextField, placeholder: `https://api.example.com?q={code}`)
- 价格 JSON 路径 (TextField, placeholder: `data.price`)
- 涨跌 JSON 路径 (TextField, placeholder: `data.change`)
- **测试按钮**

### 测试流程

1. 用户输入股票代码
2. 点击"测试"
3. 替换 URL 中的 `{code}` 为输入的代码
4. 发起请求，解析 JSONPath
5. 显示成功（价格+涨跌）或错误信息

## AddEditStockView 改动

- **移除** StockTemplate 枚举和内置模板 Picker
- 数据源选择改为 Picker：
  - 选项：已有数据源列表 + "新建数据源"
- 选"新建数据源"：展开内联表单（含测试功能）
- 保存时：若选"新建数据源"→ 先保存到 DataSourceConfig，再关联到 StockConfig

### 已有股票迁移

- 现有股票的 `apiURL` 包含 `web.ifzq.gtimg.cn` → 标记为腾讯财经兼容
- 包含 `stock.xueqiu.com` → 标记为雪球兼容
- 显示时使用原名称"腾讯财经"或"雪球"，用户可编辑

## 实现步骤

1. 创建 `DataSourceConfig` SwiftData 模型
2. 在 App 模型容器中注册
3. 在 SettingsView 添加数据源管理 UI
4. 修改 AddEditStockView 数据源选择逻辑
5. 实现数据源测试功能
6. 迁移/清理内置模板相关代码
