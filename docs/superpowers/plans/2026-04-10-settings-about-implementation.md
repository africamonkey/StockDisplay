# Settings About Section Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add "About" section to Settings with GitHub link, donation (StoreKit), and about app info.

**Architecture:** Add about section to existing SettingsView using native SwiftUI NavigationLink and sheet patterns. StoreKit 2 for donations with async/await.

**Tech Stack:** SwiftUI, StoreKit 2, SwiftData (existing)

---

## File Structure

| File | Action | Responsibility |
|------|--------|-----------------|
| `StockDisplay/Views/SettingsView.swift` | Modify | Add about section with 3 rows |
| `StockDisplay/Views/AboutView.swift` | Create | Display app info |
| `StockDisplay/Views/DonationView.swift` | Create | Donation UI with preset amounts |
| `StockDisplay/Services/DonationManager.swift` | Create | StoreKit wrapper for IAP |
| `StockDisplay/Localizable.xcstrings` | Modify | Add new strings |

---

## Task 1: Add About Section to SettingsView

**Files:**
- Modify: `StockDisplay/Views/SettingsView.swift:88-96`

- [ ] **Step 1: Add state variable for donation sheet**

Find line 10 (`@State private var showingDataSourceEditor = false`) and add after it:

```swift
@State private var showDonationView = false
```

- [ ] **Step 2: Add About section before closing List**

Find line 96 (closing brace of otherSettings Section) and add after it:

```swift
Section(String(localized: "settings.about")) {
    Link(destination: URL(string: "https://github.com/africamonkey/StockDisplay")!) {
        Label(String(localized: "settings.github"), systemImage: "link")
    }
    
    Button {
        showDonationView = true
    } label: {
        Label(String(localized: "settings.donate"), systemImage: "heart")
    }
    
    NavigationLink(destination: AboutView()) {
        Label(String(localized: "settings.aboutApp"), systemImage: "info.circle")
    }
}
```

- [ ] **Step 3: Add donation sheet modifier**

Find line 110 (closing brace of body) and add after `.sheet` modifier:

```swift
.sheet(isPresented: $showDonationView) {
    DonationView()
}
```

- [ ] **Step 4: Commit**

```bash
git add StockDisplay/Views/SettingsView.swift
git commit -m "feat(settings): add about section with github, donation, and about links"
```

---

## Task 2: Create AboutView

**Files:**
- Create: `StockDisplay/Views/AboutView.swift`

- [ ] **Step 1: Write AboutView implementation**

```swift
import SwiftUI

struct AboutView: View {
    private var appName: String {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
            ?? Bundle.main.infoDictionary?["CFBundleName"] as? String
            ?? "StockDisplay"
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 60))
                        .foregroundStyle(.blue)
                    
                    Text(appName)
                        .font(.title)
                        .fontWeight(.bold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            
            Section(String(localized: "aboutApp.info")) {
                LabeledContent(String(localized: "aboutApp.version")) {
                    Text(appVersion)
                }
                LabeledContent(String(localized: "aboutApp.build")) {
                    Text(buildNumber)
                }
                LabeledContent(String(localized: "aboutApp.developer")) {
                    Text("Africamonkey")
                }
            }
        }
        .navigationTitle(String(localized: "settings.about"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add StockDisplay/Views/AboutView.swift
git commit -m "feat: add AboutView with app info display"
```

---

## Task 3: Create DonationManager (StoreKit Service)

**Files:**
- Create: `StockDisplay/Services/DonationManager.swift`

- [ ] **Step 1: Write DonationManager with StoreKit 2**

```swift
import Foundation
import StoreKit

@MainActor
final class DonationManager: ObservableObject {
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchaseState: PurchaseState = .idle
    
    enum PurchaseState {
        case idle
        case loading
        case success
        case error(String)
    }
    
    private let productIds = [
        "donation_1",
        "donation_10",
        "donation_30",
        "donation_100"
    ]
    
    func loadProducts() async {
        do {
            products = try await Product.products(for: productIds)
                .sorted { product1, product2 in
                    let order = productIds
                    let index1 = order.firstIndex(of: product1.id) ?? 0
                    let index2 = order.firstIndex(of: product2.id) ?? 0
                    return index1 < index2
                }
        } catch {
            purchaseState = .error(error.localizedDescription)
        }
    }
    
    func purchase(_ product: Product) async {
        purchaseState = .loading
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                purchaseState = .success
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .error(error.localizedDescription)
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreKitError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
    
    func resetState() {
        purchaseState = .idle
    }
}
```

- [ ] **Step 2: Commit**

```bash
git add StockDisplay/Services/DonationManager.swift
git commit -m "feat: add DonationManager with StoreKit 2 integration"
```

---

## Task 4: Create DonationView

**Files:**
- Create: `StockDisplay/Views/DonationView.swift`

- [ ] **Step 1: Write DonationView implementation**

```swift
import SwiftUI
import StoreKit

struct DonationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var donationManager = DonationManager()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text(String(localized: "donation.subtitle"))
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                
                if donationManager.products.isEmpty {
                    ProgressView()
                        .padding()
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(donationManager.products, id: \.id) { product in
                            DonationButton(product: product) {
                                Task {
                                    await donationManager.purchase(product)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                if case .success = donationManager.purchaseState {
                    Text(String(localized: "donation.success"))
                        .foregroundStyle(.green)
                        .font(.headline)
                } else if case .error(let message) = donationManager.purchaseState {
                    Text(message)
                        .foregroundStyle(.red)
                        .font(.caption)
                }
                
                Button(String(localized: "donation.close")) {
                    dismiss()
                }
                .padding(.bottom, 20)
            }
            .navigationTitle(String(localized: "donation.title"))
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await donationManager.loadProducts()
            }
            .onChange(of: donationManager.purchaseState) { _, newValue in
                if case .success = newValue {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        donationManager.resetState()
                    }
                }
            }
        }
    }
}

struct DonationButton: View {
    let product: Product
    let action: () -> Void
    
    private var displayPrice: String {
        product.displayPrice
    }
    
    private var donationTier: String {
        switch product.id {
        case "donation_1": return String(localized: "donation.tier1")
        case "donation_10": return String(localized: "donation.tier2")
        case "donation_30": return String(localized: "donation.tier3")
        case "donation_100": return String(localized: "donation.tier4")
        default: return displayPrice
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(displayPrice)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(donationTier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DonationView()
}
```

- [ ] **Step 2: Commit**

```bash
git add StockDisplay/Views/DonationView.swift
git commit -m "feat: add DonationView with preset donation amounts"
```

---

## Task 5: Add Localized Strings

**Files:**
- Modify: `StockDisplay/Localizable.xcstrings`

- [ ] **Step 1: Add new strings to Localizable.xcstrings**

Add these entries to the `strings` dictionary in `Localizable.xcstrings`:

```json
"settings.about" : {
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "About" } },
    "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "关于" } }
  }
},
"settings.github" : {
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "GitHub Repository" } },
    "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "GitHub 仓库" } }
  }
},
"settings.donate" : {
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "Donate" } },
    "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "捐赠" } }
  }
},
"settings.aboutApp" : {
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "About" } },
    "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "关于" } }
  }
},
"aboutApp.info" : {
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "Information" } },
    "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "信息" } }
  }
},
"aboutApp.version" : {
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "Version" } },
    "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "版本" } }
  }
},
"aboutApp.build" : {
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "Build" } },
    "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "构建" } }
  }
},
"aboutApp.developer" : {
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "Developer" } },
    "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "开发者" } }
  }
},
"donation.title" : {
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "Donation" } },
    "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "捐赠支持" } }
  }
},
"donation.subtitle" : {
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "Your support motivates me to keep developing" } },
    "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "您的支持是我开发的动力" } }
  }
},
"donation.close" : {
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "Close" } },
    "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "关闭" } }
  }
},
"donation.success" : {
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "Thank you for your donation!" } },
    "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "感谢您的捐赠！" } }
  }
},
"donation.tier1" : {
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "Coffee" } },
    "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "咖啡" } }
  }
},
"donation.tier2" : {
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "Meal" } },
    "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "餐食" } }
  }
},
"donation.tier3" : {
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "Dinner" } },
    "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "晚餐" } }
  }
},
"donation.tier4" : {
  "localizations" : {
    "en" : { "stringUnit" : { "state" : "translated", "value" : "Premium" } },
    "zh-Hans" : { "stringUnit" : { "state" : "translated", "value" : "高级支持" } }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add StockDisplay/Localizable.xcstrings
git commit -m "feat: add localized strings for about section and donation"
```

---

## Task 6: Update README.md

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update README with new settings info**

Add to the Settings section in README.md:

```markdown
| **About** | GitHub repo, Donation, App info |
```

Add a new section:

```markdown
## About

| Item | Description |
|------|-------------|
| GitHub | [africamonkey/StockDisplay](https://github.com/africamonkey/StockDisplay) |
| Donate | Support development via in-app purchase |
| Version | Displayed in Settings → About |
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: update README with about section info"
```

---

## Verification

After implementation, verify:
1. Build succeeds: `xcodebuild -project StockDisplay.xcodeproj -scheme StockDisplay -sdk iphonesimulator -configuration Debug build`
2. Settings shows new "About" section at bottom
3. GitHub link opens Safari
4. Donation opens sheet with 4 preset amounts
5. About view shows app name, version, build, developer
