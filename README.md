### Centralized Analytics System with Inventory Management and Decision Support for Operations of Sweet Box

A Flutter mobile application for the Sweet Box branch analytics system and inventory management modules.

---

## User Roles & Screens

Login routes to a role-specific screen after OTP verification:

| Role | Landing Screen |
|---|---|---|
| Business Owner | Enterprise Analytics Module |
| System Administrator | User Management (create/delete accounts) |
| Branch Manager | Branch Manager Dashboard |
| Front Staff / Cashier | POS Terminal |
| Inventory Staff | Inventory & Supply Chain |
|---|---|---|
---

## Features

### Authentication (`login_screen.dart` → `otp_screen.dart`)
- Email/password form checks credentials against the `users` collection in Firestore.
- On success, the app moves to a **Two-Factor Authentication** screen with a 6 digit PIN input box


### POS Terminal — Front Staff (`pos_screen.dart`)
- Product catalogue fetched from Firestore, filterable by category (`Cakes`, `Pastries`, `Beverages`, `Meals`).
- Running cart with quantity controls, subtotal/discount/total breakdown.
- **PWD/Senior Citizen 20% discount** toggle and a **Cash / Card / E-Wallet** payment selector.
- Checkout calls `TransactionService.processCheckout`, which runs an atomic Firestore transaction: it reads each product's Bill of Materials (BOM), deducts the required raw materials from `inventory`, and writes a record to `transactions`. If a sale would push any ingredient below zero, the whole transaction is rejected and the cashier sees a clear "Transaction Failed" dialog explaining which ingredient is short.

### Inventory & Supply Chain — Inventory Staff (`inventory_screen.dart`)
- Live inventory grid with category filter and status filter (`All`, `In Stock`, `Low Stock`, `Critical`)
- Visual stock-level indicators (progress-bar style) plus scorecards summarizing low-stock counts.
- Controls for adding new ingrediets, configuring Bill-of-Materials configs for each product to be presented in the POS Terminal.

### Branch Manager Dashboard (`branch_manager_screen.dart`)
- Four-tab layout: **Dashboard**, **History**, **Analytics** (deep-links into the Enterprise Analytics Module), **Inventory** (deep-links into the Inventory screen).
- Dashboard tab shows branch-level KPI cards and a stock alert list.
- History tab shows a date-filterable transaction log, visually distinguishing sales from refunds.

### Enterprise Analytics Module — Business Owner (`enterprise_dashboard_screen.dart`)
- Summary cards for **Gross Running Revenue** and **Consolidated Tickets** (order count), computed live from the full `transactions` stream.
- **Real-Time Revenue Performance** line chart, a **Payment Methods** pie chart, and a **Transaction Volume** bar chart, all built with `fl_chart`.

### System Administrator — User Management (`user_management_screen.dart`)
- List of all accounts in the `users` collection.
- "Add User" dialog to create an account with email, password, and role (`Branch Manager`, `Inventory Staff`, `Front Staff`).
- Delete-account flow with a confirmation dialog.

---

## Data Model

Defined in `lib/models/models.dart`:

| Class | Purpose |
|---|---|
| `RawMaterial` | An inventory ingredient: id, name, stock quantity, unit, cost per unit, category |
| `BillOfMaterials` | A recipe line: which raw material and how much of it a product needs |
| `Product` | A sellable item: id, name, price, category, and its `recipe` (list of `BillOfMaterials`) |
| `OrderItem` | A product + quantity inside a cart, with a computed `total` |
| `TransactionRecord` | A completed sale/refund: id, timestamp, items, total, cashier |

### Firestore Collections

| Collection | Written by | Description |
|---|---|---|
| `users` | Admin screen, seeder | Accounts: email, password (plaintext — see limitations), role |
| `inventory` | Inventory screen, seeder | Raw materials with `currentStock`, `unit`, `costPerUnit`, `category` |
| `products` | Inventory screen ("Add Product"), seeder | Sellable products with an embedded `recipe` (BOM) |
| `transactions` | POS checkout, seeder | One doc per sale/refund, including a snapshot of items sold |
| `restock_requests` | Inventory screen ("Log Reorder Request") | Pending restock requests with ingredient, quantity, unit, status |

---

## Project Structure

```
final-sweetbox-main/
├── lib/
│   ├── main.dart                        # App entry point
│   ├── firebase_options.dart            # Generated FlutterFire config (project: sweetbox-final)
│   ├── theme/
│   │   └── app_theme.dart               # Brand colors + Material theme (Poppins via google_fonts)
│   ├── models/
│   │   └── models.dart                  # RawMaterial, Product, BillOfMaterials, OrderItem, TransactionRecord
│   ├── services/
│   │   ├── firestore_service.dart       # Main Firestore service access layer
│   │   ├── transaction_service.dart     # Checkout transaction logic used by the POS screen
│   │   ├── inventory_service.dart       # BOM deduction helper (not Firestore-backed, but is stored)
│   │   └── database_seeder.dart         # One-shot demo data seeder for inventory/products/transactions
│   └── screens/
│       ├── login_screen.dart            
│       ├── otp_screen.dart             
│       ├── pos_screen.dart             
│       ├── inventory_screen.dart        
│       ├── branch_manager_screen.dart  
│       ├── enterprise_dashboard_screen.dart 
│       └── user_management_screen.dart  
├── android/                             # Already wired to Firebase (google-services.json committed)
├── ios/ macos/ windows/ linux/ web/      # Standard Flutter platform scaffolding
├── assets/
│   └── logo.png                         # App icon / splash source image
├── firebase.json                        # FlutterFire project mapping (sweetbox-final)
└── pubspec.yaml
```

---

## Getting Started

### 1. Prerequisites

- **Flutter SDK** — install per platform: https://docs.flutter.dev/get-started/install
- **An IDE** — VS Code (with the Flutter and Dart extensions).
- **An emulator or device** — an Android Virtual Device or a physical device with USB debugging enabled.


### 2. Download code as zip, create a new app "final-sweetbox-main", install zip in your IDE's active workspace folder, and install dependencies

```
cd final-sweetbox-main
flutter pub get
```

### 3. Create assets folder

```
mkdir -p assets/images        # macOS/Linux
mkdir assets\images           # Windows
```

### 4. Run the app

```bash
flutter devices          # list emulators/devices
flutter run -d <device-id>  # target a specific one
```

---

## Brand Colors

Defined in `lib/theme/app_theme.dart`:

| Name | Hex | Usage |
|---|---|---|
| Chocolate Brown | `#3D1F0A` | Primary |
| Golden Amber | `#F5A623` | Accent |
| Warm Cream | `#FDF6EC` | Page background |
| White | `#FFFFFF` | Cards and panels |
| Success Green | `#2E7D32` | Healthy stock, confirmed sales |
| Warning Orange | `#F57C00` | Low stock, caution states |
| Danger Red | `#C62828` | Critical stock, refunds, failures |
| Info Blue | `#1565C0` | Informational accents |

---

## Known Limitations

- **OTP is simulated.** Any 6-digit numeric input passes; no code is actually generated or emailed.
- **Passwords are stored and compared in plaintext** in the `users` collection (`FirestoreService.authenticateUser`).
- **No Firestore security rules are included** in this repository.
- **No branch segmentation yet.** Products, inventory, and transactions aren't tagged with a branch ID, so the Enterprise Analytics Module currently reports on all transactions combined rather than per-branch

---

