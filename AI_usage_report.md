# AI Usage Report

**Project:** Smart Class Check-in & Learning Reflection App
**Author:** 6731503119 Waritpon Kokong

## What AI Tools I Used
- **Google Gemini (Integration within IDE)**
- Used for generating boilerplate code, assisting with complex integrations (Firebase, Camera), and refactoring UI styling.

## What AI Helped Me Generate
- **Flutter UI Scaffolding:** Generated the initial layout and structure for the 4 main screens (Home, Check-in, Finish Class, History).
- **QR Scanner Integration:** Helped integrate the `mobile_scanner` package and set up the camera overlay logic.
- **Firestore CRUD Operations:** Generated the base `FirestoreService` class to handle data creation, updating, and querying from Firebase Cloud Firestore.
- **Theme Generation:** Assisted in creating the modern dark theme palette and centralized `ThemeData` based on my design requirements.

## What I Modified or Implemented Myself
While the AI generated the foundational code, I applied significant engineering judgment to fix bugs, improve logic, and meet specific project requirements:

1. **Custom QR Code Validation (Engineering Judgment):** 
   - *Problem:* The raw AI/package code accepted *any* scanned QR code (e.g., PromptPay QR codes).
   - *My Implementation:* I manually wrote a Regular Expression (`^[67]\d{9}$`) validation check to intercept the scan. The system now strictly rejects invalid codes, shows a red warning SnackBar, and resets the scanner state without breaking the UI flow.

2. **Fixing Firestore Composite Index Errors:**
   - *Problem:* Initial queries using multiple `.where()` and `.orderBy()` clauses triggered exceptions because Firestore requires manually generated composite indexes.
   - *My Implementation:* To streamline the MVP and prevent deployment friction, I refactored the queries. I removed the `.orderBy()` clauses from the Firestore query and instead implemented client-side sorting algorithms in Dart (e.g., `records.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));`).

3. **Lifecycle Bug Fixes (setState after dispose):**
   - *Problem:* When awaiting async actions (like GPS `getCurrentLocation` or Firestore network calls), pressing the back button caused "setState called after dispose" memory leak crashes.
   - *My Implementation:* I systematically went through every asynchronous gap in the codebase and inserted `if (!mounted) return;` or `if (!context.mounted) return;` checks to ensure safe state updates.

4. **Preventing Duplicate Check-ins:**
   - *Problem:* Students could press "Check-in" multiple times and create redundant "In Progress" sessions.
   - *My Implementation:* I implemented a pre-check validation step on the Home screen. Before navigating to the Check-in screen, the app now queries Firestore to see if an active session exists. If it does, navigation is blocked and an error is shown.
