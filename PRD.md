# Product Requirement Document (PRD)
## Smart Class Check-in & Learning Reflection App

---

## Problem Statement

Universities need a reliable way to verify student attendance and engagement in class sessions. Traditional roll-call methods are time-consuming and do not capture student learning reflections. A digital solution using GPS verification, QR code scanning, and learning reflections can confirm both physical presence and active participation.

## Target User

- **Primary**: University students attending classes in-person
- **Secondary**: Instructors who want to verify attendance and review student reflections

## Feature List

### 1. Class Check-in (Before Class)
- Capture GPS location to verify physical presence
- Scan classroom QR code for session verification
- Record previous class topic recall
- Record expected learning topic for today
- Capture mood before class (5-point emoji scale)

### 2. Class Completion (After Class)
- Capture GPS location at end of class
- Scan classroom QR code again
- Record what was learned during the session
- Provide feedback about class/instructor

### 3. History View
- View all past check-in/check-out records
- See details of each session

## User Flow

```
[Open App] → [Enter Student ID & Name] → [Home Screen]
                                              │
                    ┌─────────────────────────┼─────────────────────┐
                    ▼                         ▼                     ▼
             [Check-in]               [Finish Class]          [History]
                    │                         │                     │
            ┌───────┤                 ┌───────┤              View past
            ▼       ▼                 ▼       ▼              records
        Get GPS  Scan QR          Get GPS  Scan QR
            │       │                 │       │
            ▼       ▼                 ▼       ▼
        Fill Form:                Fill Form:
        - Previous topic          - What learned
        - Expected topic          - Feedback
        - Mood (1-5)
            │                         │
            ▼                         ▼
      Save to Firestore        Update Firestore
```

## Data Fields

| Field | Type | Phase |
|---|---|---|
| studentId | String | Check-in |
| studentName | String | Check-in |
| checkInTime | Timestamp | Check-in |
| checkInLatitude | Double | Check-in |
| checkInLongitude | Double | Check-in |
| qrCodeData | String | Check-in |
| previousTopic | String | Check-in |
| expectedTopic | String | Check-in |
| moodBefore | Int (1-5) | Check-in |
| checkOutTime | Timestamp | Check-out |
| checkOutLatitude | Double | Check-out |
| checkOutLongitude | Double | Check-out |
| qrCodeDataOut | String | Check-out |
| whatLearned | String | Check-out |
| feedback | String | Check-out |
| isCompleted | Boolean | Both |

## Tech Stack

| Component | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Backend | Firebase (Firestore) |
| Location | Geolocator package |
| QR Scanning | mobile_scanner package |
| Platform | Android, Web |
