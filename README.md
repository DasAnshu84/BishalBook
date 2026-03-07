# BishalBook

A Flutter-based ledger management app for tracking clients and transactions with document scanning capabilities.

## Features

- **Client Management** — Create, read, update, and delete clients
- **Transaction Log** — Record and browse transactions with filters (date range, client)
- **Document Scanner** — Scan ledger pages via camera or gallery, extract data as CSV
- **CSV Export** — Share extracted data via the native share sheet (mobile) or download (web)

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (>= 3.11.1)
- Android Studio / Xcode (for emulators)
- A running backend API (see `.env` configuration below)

## Setup & Launch

### 1. Clone the repository

```bash
git clone <your-repo-url>
cd bishalbook
```

### 2. Create the `.env` file

Create a `.env` file in the project root with:

```env
API_BASE_URL=https://your-api-domain.com
EXTRACTION_ENDPOINT=/extract-ledger/
```

### 3. Install dependencies

```bash
flutter pub get
```

### 4. Run in debug mode

```bash
flutter run
```

### 5. Build release APK (Android)

```bash
flutter build apk
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

### 6. Build for iOS

```bash
flutter build ios
```

## Project Structure

```
lib/
├── main.dart                  # App entry point
├── constants.dart             # API URLs from .env
├── home_page.dart             # Main dashboard
├── clients_page.dart          # Client CRUD page
├── transactions_page.dart     # Transaction log with filters
├── confirm_delete_dialog.dart # Reusable delete confirmation
├── web_download.dart          # Conditional export for file download
├── web_download_stub.dart     # Mobile download (share sheet)
└── web_download_web.dart      # Web download (browser save)
```

## API Endpoints

The app expects a REST API with the following endpoints:

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/clients/` | List all clients |
| POST | `/api/clients/` | Create a client |
| PUT | `/api/clients/<id>` | Update a client |
| DELETE | `/api/clients/<id>` | Delete a client |
| GET | `/api/transactions/` | List transactions (supports `skip`, `limit`, `client_id`, `start_date`, `end_date`) |
| POST | `/api/transactions/` | Create a transaction |
| DELETE | `/api/transactions/<uuid>` | Delete a transaction |
| POST | `/extract-ledger/` | Upload image, returns CSV |
