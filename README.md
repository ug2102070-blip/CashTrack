<p align="center">
  <img src="assets/images/app_icon.png" alt="CashTrack Logo" width="120" height="120" style="border-radius: 24px;">
</p>

<h1 align="center">CashTrack</h1>

<p align="center">
  <strong>🇧🇩 Professional Personal Finance Tracker for Bangladesh</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#getting-started">Getting Started</a> •
  <a href="#tech-stack">Tech Stack</a> •
  <a href="#contributing">Contributing</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.2+-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/Dart-3.2+-0175C2?logo=dart&logoColor=white" alt="Dart">
  <img src="https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-brightgreen" alt="Platform">
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License">
  <img src="https://img.shields.io/github/stars/ug2102070-blip/CashTrack?style=social" alt="Stars">
</p>

---

## 📌 Overview

**CashTrack** is a feature-rich, production-grade personal finance management application built with Flutter, specifically designed for users in Bangladesh. It supports **Bangladeshi Taka (BDT)**, **bKash/Nagad/Rocket SMS auto-import**, **Bangla localization**, and provides a comprehensive suite of tools to track income, expenses, budgets, debts, goals, and investments — all from a beautifully crafted mobile interface.

> 🏆 Built for academic competition & real-world use.

---

## ✨ Features

### 💰 Core Finance
- **Transaction Management** — Add, edit, delete income & expense transactions with category tagging
- **Multi-Account Support** — Track Cash, Bank, bKash, Nagad, Rocket, and custom accounts
- **Budget Tracking** — Set monthly budgets per category with automatic rollover support
- **Debt Management** — Track money lent & borrowed with settlement tracking
- **Savings Goals** — Set financial goals with progress visualization
- **Asset & Investment Tracking** — Monitor your assets and investment portfolio

### 🤖 AI-Powered
- **AI Financial Assistant** — Powered by Google Gemini for smart financial insights
- **Voice Input** — Add transactions using voice commands (Speech-to-Text)
- **Smart SMS Import** — Automatically detect & import transactions from bKash, Nagad, Rocket, and bank SMS

### 📊 Analytics & Reports
- **Visual Analytics** — Beautiful charts and graphs powered by FL Chart
- **Expense Breakdown** — Category-wise spending analysis
- **Income vs Expense** — Monthly comparison with savings rate
- **Export Reports** — Generate PDF, CSV, and Excel reports

### 🔐 Security
- **Biometric Authentication** — Fingerprint & Face ID support
- **PIN Lock** — App-level PIN protection
- **Screenshot Protection** — Prevent screenshots of sensitive data
- **Secure Storage** — API keys and credentials stored in encrypted storage

### 🌐 Localization & UX
- **Bilingual Support** — Full English & বাংলা (Bengali) localization
- **Dark Mode** — Beautiful dark theme with accent color customization
- **Onboarding Flow** — Guided setup for first-time users
- **Animations** — Smooth micro-animations and transitions throughout
- **Compact Mode** — Dense list views for power users

### 🔔 Notifications
- **Budget Alerts** — Get notified when approaching budget limits
- **Bill Reminders** — Never miss a payment deadline
- **Debt Due Dates** — Timely reminders for debt settlements
- **Smart Scheduling** — Background task scheduling with WorkManager

---

## 📱 Screenshots

<p align="center">
  <i>Screenshots coming soon — the app features a modern, gradient-rich UI with glassmorphism effects.</i>
</p>

<!--
Add screenshots here:
<p align="center">
  <img src="screenshots/dashboard.png" width="200">
  <img src="screenshots/analytics.png" width="200">
  <img src="screenshots/transactions.png" width="200">
  <img src="screenshots/settings.png" width="200">
</p>
-->

---

## 🏗️ Architecture

CashTrack follows a **clean, layered architecture** with clear separation of concerns:

```
lib/
├── core/                    # App-wide utilities & configurations
│   ├── constants/           # App constants, currencies, limits
│   ├── l10n/                # Localization (English + Bengali)
│   ├── routes/              # GoRouter navigation setup
│   ├── theme/               # Dynamic theming (light/dark + accent)
│   └── utils/               # Formatters, helpers, logger
│
├── data/                    # Data layer
│   ├── models/              # Freezed data models with Hive adapters
│   │   ├── transaction_model.dart
│   │   ├── account_model.dart
│   │   ├── budget_model.dart
│   │   ├── category_model.dart
│   │   ├── debt_model.dart
│   │   ├── goal_model.dart
│   │   ├── asset_model.dart
│   │   ├── investment_model.dart
│   │   └── user_model.dart
│   └── repositories/        # Data access layer (Hive + Firebase)
│
├── presentation/            # UI layer
│   ├── dashboard/           # Home screen with summary widgets
│   ├── transactions/        # Add/edit/list transactions
│   ├── analytics/           # Charts & financial analysis
│   ├── budget/              # Budget management
│   ├── accounts/            # Multi-account management
│   ├── debts/               # Debt tracking
│   ├── goals/               # Savings goals
│   ├── categories/          # Category management
│   ├── ai_assistant/        # Gemini AI chat
│   ├── reports/             # Export & report generation
│   ├── settings/            # App preferences
│   ├── auth/                # Authentication screens
│   ├── onboarding/          # First-time user flow
│   ├── security/            # App lock gate
│   ├── tools/               # Calculator & notes
│   ├── providers/           # Riverpod state providers
│   └── widgets/             # Shared UI components
│
└── services/                # Business logic services
    ├── ai_service.dart      # Google Gemini integration
    ├── auth_service.dart    # Firebase Authentication
    ├── sms_service.dart     # MFS SMS auto-import
    ├── sync_service.dart    # Cloud sync with Firestore
    ├── notification_service.dart
    └── screenshot_protection_service.dart
```

### State Management

- **Riverpod** for reactive state management
- **Freezed** for immutable data models with union types
- **Hive** for fast local storage with type adapters

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>= 3.2.0`
- [Dart SDK](https://dart.dev/get-dart) `>= 3.2.0`
- Android Studio / VS Code
- Firebase project (for auth & cloud sync)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/ug2102070-blip/CashTrack.git
   cd CashTrack
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code** (Freezed, JSON serialization, Hive adapters)
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Firebase Setup**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Enable Authentication (Email/Password, Phone)
   - Enable Cloud Firestore

5. **Run the app**
   ```bash
   flutter run
   ```

### Environment Variables

For the AI Assistant feature, set your Gemini API key through the app's Settings page, which stores it securely using `flutter_secure_storage`.

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| **Framework** | Flutter 3.2+ |
| **Language** | Dart 3.2+ |
| **State Management** | Riverpod + Hooks |
| **Local Database** | Hive |
| **Cloud Backend** | Firebase (Auth, Firestore, Storage, Analytics) |
| **Navigation** | GoRouter |
| **Data Models** | Freezed + JSON Serializable |
| **AI** | Google Generative AI (Gemini) |
| **Charts** | FL Chart |
| **Notifications** | Flutter Local Notifications + WorkManager |
| **Security** | Local Auth (Biometric) + Flutter Secure Storage |
| **Export** | PDF, CSV, Excel |
| **Voice** | Speech-to-Text + Flutter TTS |
| **Fonts** | Poppins, Baloo Da 2, Noto Sans Bengali |

---

## 🧪 Testing

Run the test suite:

```bash
flutter test
```

Available test files:
- `transaction_repository_test.dart` — Transaction CRUD operations
- `category_repository_test.dart` — Category management
- `account_goal_repository_test.dart` — Account & goal operations
- `asset_investment_repository_test.dart` — Asset & investment tracking
- `add_transaction_form_test.dart` — Form validation & submission
- `dashboard_summary_provider_test.dart` — Dashboard state aggregation
- `settings_notifier_test.dart` — Settings state management

---

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting a pull request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/) — Beautiful native apps in record time
- [Firebase](https://firebase.google.com/) — Backend infrastructure
- [Riverpod](https://riverpod.dev/) — Reactive state management
- [Google Gemini](https://ai.google.dev/) — AI capabilities

---

<p align="center">
  Made with ❤️ in Bangladesh 🇧🇩
</p>
