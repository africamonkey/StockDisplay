# Settings About Section - Design Spec

## 1. Concept & Vision

Add an "About" section at the bottom of the Settings page with three sub-items: GitHub Repository, Donation, and About. This provides users with quick access to app information, the source code, and an option to support development.

## 2. Design Language

- **Aesthetic**: Native iOS (SwiftUI), consistent with existing SettingsView style
- **Color Palette**: System colors (primary text, secondary for subtitles)
- **Typography**: System font, standard iOS settings hierarchy
- **Layout**: List with NavigationLink rows, sheet for donation

## 3. Architecture

### Components

#### SettingsView Changes
- Add new `Section("关于")` at bottom of SettingsView
- Three rows inside the section:
  1. `NavigationLink` → GitHub URL (opens Safari)
  2. `Button` → Opens donation sheet
  3. `NavigationLink` → AboutView

#### AboutView
- Display-only view (no edits)
- Shows: App name, Version, Build number, Developer
- Uses `Bundle.main.infoDictionary` for dynamic values

#### DonationView (Sheet)
- StoreKit integration (In-App Purchase)
- 4 preset donation amounts: 1元, 10元, 30元, 100元
- Products loaded from App Store Connect
- Shows product name and price
- Purchase button with loading/success/error states

### Data Flow

```
SettingsView
├── Section("关于")
│   ├── NavigationLink → GitHub URL (UIApplication.shared.open)
│   ├── Button → donationViewSheet = true
│   └── NavigationLink → AboutView()
│
└── .sheet(isPresented: $showDonationView) → DonationView()
```

## 4. UI Components

### SettingsView - New Section
```swift
Section(String(localized: "settings.about")) {
    // GitHub Repository
    Link(destination: URL(string: "https://github.com/africamonkey/StockDisplay")!) {
        Label(String(localized: "settings.github"), systemImage: "link")
    }
    
    // Donation
    Button {
        showDonationView = true
    } label: {
        Label(String(localized: "settings.donate"), systemImage: "heart")
    }
    
    // About
    NavigationLink(destination: AboutView()) {
        Label(String(localized: "settings.aboutApp"), systemImage: "info.circle")
    }
}
```

### AboutView
```
┌─────────────────────────────┐
│ StockDisplay                │
│                             │
│ Version        1.0.0 (1)   │
│ Developer      Africamonkey │
│                             │
└─────────────────────────────┘
```

### DonationView
```
┌─────────────────────────────┐
│         捐赠支持             │
│                             │
│  您的支持是我开发的动力      │
│                             │
│  ┌─────────┐ ┌─────────┐   │
│  │  ¥1    │ │  ¥10   │   │
│  └─────────┘ └─────────┘   │
│  ┌─────────┐ ┌─────────┐   │
│  │  ¥30   │ │ ¥100   │   │
│  └─────────┘ └─────────┘   │
│                             │
│  [  捐赠  ]                  │
│                             │
│         [ 关闭  ]           │
└─────────────────────────────┘
```

## 5. Technical Approach

### StoreKit Integration
- Use `StoreKit` framework (StoreKit 2 with async/await)
- `Product.products(for:)` to fetch donation products
- `Transaction.currentEntitlements` to check purchase status
- Store product IDs in code or configuration

### Required Imports
- `StoreKit` - For In-App Purchase
- `SafariServices` - For opening GitHub URL (optional, Link works too)

### Strings (Localizable.xcstrings)
- `settings.about` = "关于"
- `settings.github` = "GitHub 仓库"
- `settings.donate` = "捐赠"
- `settings.aboutApp` = "关于"
- `donation.title` = "捐赠支持"
- `donation.subtitle` = "您的支持是我开发的动力"
- `donation.button` = "捐赠"
- `donation.close` = "关闭"
- `donation.success` = "感谢您的捐赠！"
- `donation.error` = "捐赠失败，请重试"

## 6. File Structure

```
StockDisplay/
├── Views/
│   ├── SettingsView.swift      # Add about section
│   ├── AboutView.swift         # NEW - About screen
│   └── DonationView.swift      # NEW - Donation sheet
└── Services/
    └── DonationManager.swift   # NEW - StoreKit wrapper
```

## 7. Out of Scope

- Receipt validation server
- Restoring purchases (donations are consumables)
- Analytics for donations
