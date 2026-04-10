# StockDisplay

A minimal iOS dashboard for tracking real-time stock prices with custom API support.

<img width="508" height="140" alt="Image" src="https://github.com/user-attachments/assets/7990cad1-0ad7-4f79-a7c6-30406f9f6549" />

<img width="550" height="412" alt="Image" src="https://github.com/user-attachments/assets/81b7eb3a-0393-46b1-96b9-53bed6422f6b" />
<img width="248" height="538" alt="Image" src="https://github.com/user-attachments/assets/d540272c-c6ca-4433-9830-554875b138a2" />

## Features

- **Real-time stock prices** - Track multiple stocks with live price updates
- **Custom API support** - Use Yahoo Finance or configure your own API endpoint
- **Configurable refresh** - Auto-refresh every 10s, 30s, 1min, 5min, or manual
- **Multiple data sources** - Support different API providers for different stocks
- **Light/Dark theme** - Follows system appearance or choose your preference
- **Adjustable font size** - Small, Medium, Large, Extra Large
- **Keep screen on** - Prevent screen dimming while viewing
- **Import/Export config** - Backup and restore your stock list via JSON files

## Installation

### Build from Source

1. Clone the repository
2. Open `StockDisplay.xcodeproj` in Xcode
3. Select an iOS Simulator (iOS 17.0+)
4. Press `Cmd + R` to build and run

### Requirements

- iOS 17.0 or later
- Xcode 15.0 or later

## Usage

### Adding a Stock

1. Tap the **gear icon** in the top-right corner
2. Tap **+** to add a new stock
3. Select a **Data Source** (or create a new one)
4. Enter the stock **Name** and **Symbol/Code**
5. Choose a **Refresh Interval**
6. Tap **Save**

### Data Sources

StockDisplay uses **Data Sources** to fetch stock prices. Each data source defines:

- **API URL** - The endpoint URL (use `{code}` as a placeholder for the stock symbol)
- **Price JSON Path** - Dot-notation path to extract the price (e.g., `chart.result[0].meta.regularMarketPrice`)
- **Change JSON Path** - Dot-notation path to extract the price change (e.g., `chart.result[0].meta.regularMarketChangePercent`)

#### Custom Data Source

To use a custom API:

1. Go to **Settings** → **Data Sources**
2. Tap **+** to add a new data source
3. Enter a **Name** for the data source
4. Enter the full **API URL** (use `{code}` for the stock symbol)
5. Enter the **JSON paths** for price and change values
6. Save

### Import/Export

Export your stock configuration to share or backup:

1. Go to **Settings** → **Config File**
2. Tap **Export** to save your stocks and data sources as JSON
3. Tap **Import** to load a previously exported configuration

## Settings

| Setting | Description |
|---------|-------------|
| **Theme** | System, Light, or Dark |
| **Font Size** | Small, Medium, Large, Extra Large |
| **Keep Screen On** | Prevent screen dimming |
| **Data Sources** | Manage API configurations |
| **Stocks** | View, edit, delete stocks |
| **About** | GitHub repo, Donation, App info |

## About

| Item | Description |
|------|-------------|
| GitHub | [africamonkey/StockDisplay](https://github.com/africamonkey/StockDisplay) |
| Donate | Support development via in-app purchase (1元、10元、30元、100元) |
| Version | Displayed in Settings → About |

## Architecture

Built with native iOS technologies:

- **SwiftUI** - Modern declarative UI framework
- **SwiftData** - Persistent storage for stocks and settings
- **async/await** - Asynchronous data fetching
- **URLSession** - Network requests

## File Structure

```
StockDisplay/
├── StockDisplayApp.swift      # App entry point
├── ContentView.swift          # Root view
├── Views/
│   ├── DashboardView.swift    # Main stock list
│   ├── StockCardView.swift    # Individual stock card
│   ├── SettingsView.swift     # Settings screen
│   ├── AddEditStockView.swift # Add/edit stock form
│   ├── AppearanceSettingsView.swift
│   ├── ConfigFileSettingsView.swift
│   ├── DataSourceEditorView.swift
│   ├── AboutView.swift           # About screen
│   └── DonationView.swift        # Donation sheet
├── Models/
│   ├── StockConfig.swift      # Stock data model
│   └── DataSourceConfig.swift # API configuration model
├── Services/
│   ├── StockAPIService.swift  # API fetching logic
│   └── DonationManager.swift   # StoreKit donation handling
└── Utils/
    ├── JSONPath.swift         # JSON path extraction
    ├── LocaleManager.swift    # Localization
    └── FontScale.swift        # Font scaling
```

## License

MIT License - see [LICENSE](LICENSE)
