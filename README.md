# Smart Class Check-in & Learning Reflection App

A Flutter mobile application that allows university students to check in to class and reflect on their learning experience. Built for Mobile Application Development course (1305216).

## Features

- **Class Check-in (Before Class)**
  - GPS location capture (verifies physical presence)
  - QR Code scanning (session verification)
  - Pre-class reflection: previous topic, expected topic, mood rating (1-5 emoji scale)

- **Class Completion (After Class)**
  - GPS location capture
  - QR Code scanning
  - Post-class reflection: what learned, instructor/class feedback

- **History View**
  - View all past check-in/check-out sessions
  - Expandable details for each record

- **Cloud Storage**
  - All data stored in Firebase Cloud Firestore

## Tech Stack

| Component | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Backend | Firebase Cloud Firestore |
| Location | Geolocator package |
| QR Scanning | mobile_scanner package |
| Platforms | Android, Web |

## Prerequisites

- Flutter SDK (>=3.11.1)
- Android Studio or VS Code with Flutter extension
- Firebase project configured
- A physical device or emulator with camera (for QR scanning)

## Setup Instructions

### 1. Clone the repository

```bash
git clone https://github.com/6731503119Waritpon/smart_class_checkin_learning_reflection_app.git
cd smart_class_checkin_learning_reflection_app
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Firebase Configuration

This project is pre-configured with Firebase. If you need to reconfigure:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create or select your Firebase project
3. **Enable Cloud Firestore**:
   - Navigate to Build → Firestore Database
   - Click "Create database"
   - Select **Start in test mode**
   - Choose a location (e.g., `asia-southeast1`)
   - Click Enable

Firebase configuration files are already included:
- `lib/firebase_options.dart` — Firebase config for Flutter
- `android/app/google-services.json` — Android Firebase config

### 4. Android Permissions

The following permissions are already configured in the Android manifest:
- `ACCESS_FINE_LOCATION` — GPS location
- `ACCESS_COARSE_LOCATION` — Approximate location
- `CAMERA` — QR code scanning
- `INTERNET` — Firebase connectivity

## How to Run

### Android

```bash
flutter run
```

### Web

```bash
flutter run -d chrome
```

### Build APK

```bash
flutter build apk --debug
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── firebase_options.dart        # Firebase configuration
├── models/
│   └── checkin_record.dart      # Data model
├── screens/
│   ├── home_screen.dart         # Home with student info input
│   ├── checkin_screen.dart      # Check-in form (before class)
│   ├── finish_class_screen.dart # Finish class form (after class)
│   ├── history_screen.dart      # View past records
│   └── qr_scanner_screen.dart   # QR code scanner
└── services/
    ├── firestore_service.dart   # Firestore CRUD operations
    └── location_service.dart    # GPS location service
```

## Firebase Configuration Notes

- **Project ID**: `checkinlearningreflection`
- **Firestore Collection**: `checkins` (auto-created on first write)
- **Security Rules**: Currently set to test mode (allow all reads/writes)
- **Supported Platforms**: Android, Web

### Firestore Data Schema

| Field | Type | Description |
|---|---|---|
| studentId | string | Student identifier |
| studentName | string | Student full name |
| checkInTime | timestamp | Check-in timestamp |
| checkInLatitude | number | GPS latitude at check-in |
| checkInLongitude | number | GPS longitude at check-in |
| qrCodeData | string | Scanned QR data at check-in |
| previousTopic | string | Previous class topic |
| expectedTopic | string | Expected learning topic |
| moodBefore | number (1-5) | Pre-class mood |
| checkOutTime | timestamp | Check-out timestamp |
| checkOutLatitude | number | GPS latitude at check-out |
| checkOutLongitude | number | GPS longitude at check-out |
| qrCodeDataOut | string | Scanned QR data at check-out |
| whatLearned | string | What student learned |
| feedback | string | Class/instructor feedback |
| isCompleted | boolean | Session completion status |

## AI Usage Report

AI tools were used to assist in building this application:

- **What AI tools were used**: Gemini (coding assistant)
- **What AI helped generate**:
  - Flutter UI scaffolding and screen layouts
  - Firestore service integration code
  - GPS and QR scanner integration
  - Project documentation (PRD, README)
- **What was modified/implemented manually**:
  - Firebase project setup and configuration
  - Form validation logic and data flow design
  - User flow design and requirement interpretation
  - Testing and debugging on target devices
  - Firestore data structure design
