# Sweet Box — Mobile Companion App
### Centralized Analytics System with Inventory Management and Decision Support for Operations of Sweet Box
---

## Project Overview

This Flutter app provides a mobile interface for the Sweet Box centralized analytics system, covering five screens:

| Screen | Role | Description |
|---|---|---|
| Login | All | Email, password, and role selection with OTP redirect |
| OTP Verification | All | 6-digit Two-Factor Authentication with countdown timer |
| POS Terminal | Front Staff | Product catalogue, cart, split payment processing |
| Inventory Dashboard | Inventory Staff | Stock levels, restock requests, threshold alerts |
| Branch Manager Dashboard | Branch Manager | KPIs, sales chart, AI production targets, approve/override |
---

## Prerequisites

Before running the app, make sure you have the following installed on your machine:

Flutter SDK — install per platform: https://docs.flutter.dev/get-started/install
An editor —  VS Code (with the Flutter and Dart extensions).
An emulator or device — an Android Virtual Device or a physical device with USB debugging enabled.

## Installation and Setup

### Step 1 — Clone or Copy the Project

If you received this as a folder, copy the entire `sweet_box_flutter` folder to your preferred location. If using Git:

```bash
git clone <repository-url>
cd sweet_box_flutter
```

### Step 2 — Verify Flutter Installation

Open a terminal in the project folder and run:

```bash
flutter doctor
```

This checks your environment. You should see green checkmarks for:
- Flutter (Channel stable)
- Android toolchain
- Android Studio or VS Code
- Connected device

If any items show errors, follow the instructions Flutter provides to resolve them.

### Step 3 — Install Dependencies

In the project root directory (where `pubspec.yaml` is located), run:

```bash
flutter pub get
```

This downloads all required packages including:
- `fl_chart` — for data visualization charts
- `http` — for API communication
- `google_fonts` — for Poppins typography
- `shared_preferences` — for local storage
- `intl` — for date formatting
- `shimmer` — for loading animations

### Step 4 — Create Assets Folder

The pubspec.yaml references an assets folder. Create it to avoid build errors:

```bash
mkdir -p assets/images
```

On Windows:
```
mkdir assets\images
```

---

## Running the App

### Option A — Using Terminal

Make sure your emulator is running or your device is connected, then run:

```bash
flutter run
```

Flutter will detect available devices and launch the app. If multiple devices are connected, select the target device from the list.

For a specific device:
```bash
flutter run -d emulator-5554    # Android emulator
flutter run -d <device-id>       # Physical device
```

To find available device IDs:
```bash
flutter devices
```

### Option B — Using VS Code

1. Open the `sweet_box_flutter` folder in VS Code
2. Open the Command Palette with `Ctrl+Shift+P` (Windows/Linux) or `Cmd+Shift+P` (macOS)
3. Type `Flutter: Select Device` and choose your emulator or device
4. Press `F5` or go to `Run > Start Debugging`

### Option C — Using Android Studio

1. Open Android Studio
2. Select `Open` and navigate to the `sweet_box_flutter` folder
3. Wait for the project to index
4. Select your target device from the device dropdown in the toolbar
5. Click the green Run button or press `Shift+F10`

---

## Building for Release

### Android APK (for installing on Android devices)

```bash
flutter build apk --release
```

The APK will be generated at:
```
build/app/outputs/flutter-apk/app-release.apk
```

Transfer this APK to an Android device and install it directly.

### Android App Bundle (for Google Play Store)

```bash
flutter build appbundle --release
```

### iOS (macOS only)

```bash
flutter build ios --release
```

Requires an Apple Developer account for distribution.

---

## Project Structure

```
sweet_box_flutter/
├── lib/
│   ├── main.dart                          # App entry point and routing
│   ├── theme/
│   │   └── app_theme.dart                 # Sweet Box brand colors and theme
│   └── screens/
│       ├── login_screen.dart              # Login with role selection
│       ├── otp_screen.dart                # Two-Factor Authentication
│       ├── pos_screen.dart                # POS Terminal — Front Staff
│       ├── inventory_screen.dart          # Stock management — Inventory Staff
│       ├── branch_manager_screen.dart     # Branch KPIs and production targets
│       ├── prescriptions_screen.dart      # AI prescriptive outputs — all types
│       ├── chatbot_screen.dart            # Gemini AI chatbot assistant
│       └── enterprise_dashboard_screen.dart # Cross-branch view — Business Owner
├── assets/
│   └── images/                            # Image assets folder
└── pubspec.yaml                           # Project dependencies
```

---

## Navigation Flow

```
Login Screen
    ↓
OTP Verification Screen
    ↓ (routes by role)
┌─────────────────────────────────────────┐
│ Front Staff     → POS Terminal          │
│ Inventory Staff → Inventory Dashboard   │
│ Branch Manager  → Branch Mgr Dashboard  │
│ Business Owner  → Enterprise Dashboard  │
│ System Admin    → Branch Mgr Dashboard  │
└─────────────────────────────────────────┘
    ↓ (from any dashboard)
Prescriptions Screen ←→ Chatbot Screen
```

For quick demo access without authentication, the Login Screen provides Quick Demo Access chips at the bottom that navigate directly to each screen.

---

## Brand Colors

| Name | Hex | Usage |
|---|---|---|
| Chocolate Brown | `#3D1F0A` | Primary — sidebar, headers, buttons |
| Golden Amber | `#F5A623` | Accent — highlights, CTAs, active states |
| Warm Cream | `#FDF6EC` | Background — page backgrounds |
| White | `#FFFFFF` | Cards and panels |

---

## Key Features Demonstrated

- **Role-Based Navigation** — Login routes to the correct dashboard based on selected role
- **Two-Factor Authentication** — OTP screen with countdown timer and resend functionality
- **POS Transaction Flow** — Full cart system with product selection, quantity management, PWD discount, and multi-payment support
- **Real-Time Stock Monitoring** — Ingredient stock levels with visual progress bars and status badges
- **AI Production Targets** — Prescriptive production recommendations with approve and override controls
- **Prescriptive Outputs** — Four tabs covering Production, Restock, Pricing, and Classifications with full justification text
- **Human-in-the-Loop Architecture** — Every AI prescription has Approve and Override buttons; overrides trigger a logging dialog
- **AI Chatbot** — Interactive chat interface with suggested queries and prescriptive-labeled responses
- **Enterprise KPI Dashboard** — Cross-branch KPI cards, Recommended Actions panel, branch performance ranking, and revenue charts

---

## Common Issues and Fixes

**`flutter pub get` fails with network error**
Make sure you have an active internet connection. If behind a proxy, configure Flutter's proxy settings.

**`Gradle build failed` on Android**
Open `android/local.properties` and verify the `sdk.dir` path points to your Android SDK location. On Windows this is typically `C:\\Users\\YourName\\AppData\\Local\\Android\\Sdk`.

**`No devices found`**
Make sure your emulator is running or your device is connected and USB debugging is enabled. Run `flutter devices` to confirm.

**`Package not found` error after flutter pub get**
Delete the `.dart_tool` folder and `pubspec.lock` file, then run `flutter pub get` again.

**Google Fonts not loading**
The app uses Poppins from Google Fonts which requires an internet connection on first run to cache the font. Make sure the emulator or device has internet access.

**Build error: `assets/images/` not found**
Run `mkdir -p assets/images` (macOS/Linux) or `mkdir assets\images` (Windows) in the project root.

---

## Academic Context

This Flutter application was developed as part of:

**Course:** Human-Computer Interaction / Mobile Development
**Capstone Title:** Centralized Analytics System with AI-Driven Prescriptive Inventory Management and Decision Support for Multi-Branch Operations of Sweet Box
**Institution:** Batangas State University — The National Engineering University, Alangilan Campus
**Program:** Bachelor of Science in Information Technology — Business Analytics
**Authors:** Brent Draniel R. Aclan, John Paolo H. Claveria, Cristian Joshua V. Javier

The full system backend is built using Python, Django, Django REST Framework, MySQL, and the Google Gemini AI API. This Flutter app serves as the mobile companion interface demonstrating the HCI design principles applied to the system's role-based user experience.

---

## License

This project is developed for academic purposes. All rights reserved by the authors.
