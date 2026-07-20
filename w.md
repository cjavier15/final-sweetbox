# Sweet Box — Analytics & Operations App
### Flutter mobile app for role-based POS, inventory, and analytics across Sweet Box's branches

Sweet Box is a pastry shop and restaurant chain operating multiple branches. This repository is the **Flutter mobile companion app** that front-line staff, inventory staff, branch managers, business owners, and system administrators use to run day-to-day operations and view sales performance. It talks directly to **Firebase Cloud Firestore** in real time — sales made at the POS terminal instantly deduct raw-material stock, trigger low-stock alerts on the manager dashboard, and roll up into enterprise-wide revenue charts.

---

## Table of Contents

- [Tech Stack](#tech-stack)
- [User Roles & Screens](#user-roles--screens)
- [Feature Walkthrough](#feature-walkthrough)
- [Data Model](#data-model)
- [Project Structure](#project-structure)
- [Getting Started](#getting-started)
- [Seeding Demo Data](#seeding-demo-data)
- [Building for Release](#building-for-release)
- [Brand Colors](#brand-colors)
- [Known Limitations & Suggested Next Steps](#known-limitations--suggested-next-steps)

---

## Tech Stack

| Layer | Technology | Notes |
|---|---|---|
| Framework | Flutter / Dart (SDK `>=3.0.0 <4.0.0`) | Multi-platform project: Android, iOS, macOS, Windows, Linux, and Web scaffolding all present |
| Backend | Firebase Cloud Firestore | Real-time via `.snapshots()` streams; project id `sweetbox-final` |
| Auth | Custom Firestore lookup (`users` collection) | Not using Firebase Authentication — see [Known Limitations](#known-limitations--suggested-next-steps) |
| Charts | `fl_chart` | Line, bar, and pie charts on the manager and enterprise dashboards |
| Typography/Theme | `google_fonts` (Poppins) + a custom Material theme | See [Brand Colors](#brand-colors) |
| State management | `StatefulWidget` + Firestore `Stream`s | No Provider/Riverpod/Bloc in this codebase yet |

The `pubspec.yaml` also declares `http`, `shared_preferences`, `intl`, and `shimmer`, but none of these are currently imported anywhere in `lib/` — they're available for future work (e.g. local caching, date formatting, loading skeletons) but not wired in yet.

---

## User Roles & Screens

Login routes to a role-specific screen after OTP verification:

| Role | Landing Screen | Route |
|---|---|---|
| Business Owner | Enterprise Analytics Module | `/enterprise` |
| System Administrator | User Management (create/delete accounts) | `/admin` |
| Branch Manager | Branch Manager Dashboard | `/branch-manager` |
| Front Staff / Cashier | POS Terminal | `/pos` |
| Inventory Staff | Inventory & Supply Chain | `/inventory` |

Role matching in `otp_screen.dart` is case-insensitive and accepts a few synonyms per role (e.g. `"owner"`, `"manager"`, `"cashier"`, `"pos"`). Anything unrecognized falls back to the Branch Manager screen with a warning.

---

## Feature Walkthrough

### Authentication (`login_screen.dart` → `otp_screen.dart`)
- Email/password form checks credentials against the `users` collection in Firestore.
- On success, the app moves to a **Two-Factor Authentication** screen: a 6-digit code entry grid with a 5-minute countdown and a "Resend Code" action.
- ⚠️ In the current build, OTP verification is a UI-only simulation — any complete 6-digit numeric entry is accepted. No code is actually generated, emailed, or checked server-side yet.

### POS Terminal — Front Staff (`pos_screen.dart`)
- Product catalogue streamed live from Firestore, filterable by category (`Cakes`, `Pastries`, `Beverages`, `Meals`).
- A visible **real-time stock levels** panel so cashiers can see ingredient availability while selling.
- Running cart with quantity controls, subtotal/discount/total breakdown.
- **PWD/Senior Citizen 20% discount** toggle and a **Cash / Card / E-Wallet** payment selector.
- **Refund mode** toggle that reverses a sale (adds stock back instead of deducting it).
- Checkout calls `TransactionService.processCheckout`, which runs an atomic Firestore transaction: it reads each product's Bill of Materials (BOM), deducts the required raw materials from `inventory`, and writes a record to `transactions`. If a sale would push any ingredient below zero, the whole transaction is rejected and the cashier sees a clear "Transaction Failed" dialog explaining which ingredient is short.

### Inventory & Supply Chain — Inventory Staff (`inventory_screen.dart`)
- Live inventory grid/list with category filter and status filter (`All`, `In Stock`, `Low Stock`, `Critical`), driven by a stock-vs-threshold comparison.
- Visual stock-level indicators (progress-bar style) plus scorecards summarizing low-stock counts.
- Dialogs to **add a new product with its BOM/recipe**, **update an existing raw material** (including its category), and **log a batch restock request** (written to `restock_requests`).

### Branch Manager Dashboard (`branch_manager_screen.dart`)
- Four-tab layout: **Dashboard**, **History**, **Analytics** (deep-links into the Enterprise Analytics Module), **Inventory** (deep-links into the Inventory screen).
- Dashboard tab shows branch-level KPI cards and a low-stock alert list.
- History tab shows a date-filterable transaction log, visually distinguishing sales from refunds.
- A live Firestore listener watches for inventory items crossing the low-stock threshold and pops a snackbar alert in real time.

### Enterprise Analytics Module — Business Owner (`enterprise_dashboard_screen.dart`)
- Summary cards for **Gross Running Revenue** and **Consolidated Tickets** (order count), computed live from the full `transactions` stream.
- **Real-Time Revenue Performance** line chart, a **Payment Methods** pie chart, and a **Transaction Volume** bar chart, all built with `fl_chart`.
- Currently aggregates *all* transactions system-wide — see [Known Limitations](#known-limitations--suggested-next-steps) regarding per-branch segmentation.

### System Administrator — User Management (`user_management_screen.dart`)
- Live list of all accounts in the `users` collection.
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
│   ├── main.dart                        # App entry point, Firebase init, named routes
│   ├── firebase_options.dart            # Generated FlutterFire config (project: sweetbox-final)
│   ├── theme/
│   │   └── app_theme.dart               # Brand colors + Material theme (Poppins via google_fonts)
│   ├── models/
│   │   └── models.dart                  # RawMaterial, Product, BillOfMaterials, OrderItem, TransactionRecord
│   ├── services/
│   │   ├── firestore_service.dart       # Main Firestore access layer (streams, auth, users, transactions)
│   │   ├── transaction_service.dart     # Checkout transaction logic used by the POS screen
│   │   ├── inventory_service.dart       # Legacy/local BOM deduction helper (not Firestore-backed)
│   │   └── database_seeder.dart         # One-shot demo data seeder for inventory/products/transactions
│   └── screens/
│       ├── login_screen.dart            # Email/password sign-in
│       ├── otp_screen.dart              # Simulated 6-digit 2FA step
│       ├── pos_screen.dart              # POS Terminal — Front Staff
│       ├── inventory_screen.dart        # Inventory & Supply Chain — Inventory Staff
│       ├── branch_manager_screen.dart   # Branch dashboard, history, alerts — Branch Manager
│       ├── enterprise_dashboard_screen.dart  # Cross-branch analytics — Business Owner
│       └── user_management_screen.dart  # Account management — System Administrator
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

- **Flutter SDK** — install per platform: https://docs.flutter.dev/get-started/install, then run `flutter doctor` and resolve anything not green.
- **An editor** — Android Studio (with Flutter/Dart plugins) or VS Code (with the Flutter and Dart extensions).
- **An emulator or device** — an Android Virtual Device, iOS Simulator (macOS only), or a physical device with USB debugging enabled.
- **Access to the Firebase project** — this app is already pointed at a Firebase project called `sweetbox-final` (see `firebase.json`). To run it against live data you'll need appropriate access/credentials for that project, or you can repoint the app at your own Firebase project (see below).

### 2. Get the code and install dependencies

```bash
cd final-sweetbox-main
flutter pub get
```

### 3. Create the missing assets folder

`pubspec.yaml` declares `assets/images/` as an asset path, but only `assets/logo.png` exists at the moment — the `images` subfolder isn't in this archive. Create it before your first `flutter run`/`build` to avoid a missing-directory error:

```bash
mkdir -p assets/images        # macOS/Linux
mkdir assets\images           # Windows
```

### 4. Firebase setup

Android is already configured — `android/app/google-services.json` and `lib/firebase_options.dart` are committed, pointing at the `sweetbox-final` project. To run on **iOS, macOS, or another Firebase project**, install the FlutterFire CLI and re-run configuration:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This regenerates `lib/firebase_options.dart` and drops the platform config files (`GoogleService-Info.plist`, etc.) you're missing.

### 5. Run the app

```bash
flutter devices          # list available emulators/devices
flutter run               # launches on the first available device
flutter run -d <device-id>  # target a specific one
```

In VS Code: open the folder, run **Flutter: Select Device** from the Command Palette, then press `F5`.
In Android Studio: **Open** the folder, pick a device from the toolbar dropdown, then press the Run button.

---

## Seeding Demo Data

`lib/services/database_seeder.dart` contains a `DatabaseSeeder.seedAllData()` static method that populates `inventory`, `products`, and sample `transactions` in Firestore — useful for a fresh Firebase project with no data yet.

The call site in `login_screen.dart` is currently **commented out**. To seed data, either:
- Temporarily uncomment the "Seed Products to Database" button in `login_screen.dart`, run the app, tap it once, then re-comment it and remove it before shipping, **or**
- Call `await DatabaseSeeder.seedAllData();` once from a throwaway script or from `main()` before `runApp(...)`, run the app once, then remove the call.

Re-running the seeder will add duplicate documents rather than overwrite existing ones — seed against an empty project or clear the collections first.

---

## Building for Release

```bash
flutter build apk --release        # Android APK → build/app/outputs/flutter-apk/app-release.apk
flutter build appbundle --release  # Android App Bundle, for Google Play
flutter build ios --release        # iOS (macOS + Xcode + Apple Developer account required)
```

---

## Brand Colors

Defined in `lib/theme/app_theme.dart`:

| Name | Hex | Usage |
|---|---|---|
| Chocolate Brown | `#3D1F0A` | Primary — headers, sidebar, buttons |
| Golden Amber | `#F5A623` | Accent — highlights, active states, CTAs |
| Warm Cream | `#FDF6EC` | Page background |
| White | `#FFFFFF` | Cards and panels |
| Success Green | `#2E7D32` | Healthy stock, confirmed sales |
| Warning Orange | `#F57C00` | Low stock, caution states |
| Danger Red | `#C62828` | Critical stock, refunds, failures |
| Info Blue | `#1565C0` | Informational accents |

---

## Known Limitations & Suggested Next Steps

These are worth knowing before treating this as production-ready:

- **OTP is simulated.** Any 6-digit numeric input passes; no code is actually generated or emailed. A real implementation needs a backend (Cloud Function, etc.) to generate, send, and verify a code.
- **Passwords are stored and compared in plaintext** in the `users` collection (`FirestoreService.authenticateUser`). Migrating to Firebase Authentication (or at least hashing credentials) is recommended before any real user data is involved.
- **No Firestore security rules are included** in this repository. Without rules configured in the Firebase console, the database may be more open than intended.
- **No branch segmentation yet.** Products, inventory, and transactions aren't tagged with a branch ID, so the Enterprise Analytics Module currently reports on all transactions combined rather than per-branch, despite the multi-branch design intent.
- **Some duplicated logic**: `FirestoreService.processTransaction` and `TransactionService.processCheckout` implement nearly identical checkout logic. The POS screen currently uses `TransactionService`; the `FirestoreService` copy appears to be leftover from an earlier refactor.
- **`InventoryService.processSale`** is a standalone, non-Firestore-backed helper (it only prints to the console) and doesn't appear to be called from any screen — likely superseded by the Firestore transaction logic above.
- **Declared but unused packages**: `http`, `shared_preferences`, `intl`, and `shimmer` are in `pubspec.yaml` but not yet imported anywhere in `lib/`.

---

## License

Academic/capstone project. All rights reserved by the authors.
