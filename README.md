# Melo - Memory & Cognitive Assistance Platform

An AI-based cognitive gaming and memory assistance platform for elderly dementia patients in India's North Eastern Region.

## 🎯 Project Overview

Melo is designed to help elderly patients with dementia through:
- Cognitive games and exercises
- Memory assistance tools
- Caregiver monitoring and analytics
- Multi-language support for regional languages

## 📁 Project Structure

```
melo/
├── lib/
│   ├── screens/           # All app screens
│   │   ├── splash_screen.dart
│   │   ├── login_screen.dart
│   │   ├── home_screen.dart
│   │   ├── game_selection_screen.dart
│   │   └── caregiver_dashboard_screen.dart
│   ├── widgets/          # Reusable UI components
│   │   └── elderly_friendly_button.dart
│   ├── models/           # Data models
│   │   ├── user_model.dart
│   │   └── session_model.dart
│   ├── services/         # Firebase and business logic
│   │   ├── auth_service.dart
│   │   └── firestore_service.dart
│   ├── utils/            # Utilities and helpers
│   │   └── app_routes.dart
│   └── main.dart         # App entry point
├── android/              # Android configuration
├── ios/                  # iOS configuration
└── pubspec.yaml          # Dependencies
```

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.8.1 or higher)
- Android Studio / Xcode
- Firebase account
- Git

### Step 1: Firebase Setup

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Click "Add project" and name it "Melo"
   - Follow the setup wizard

2. **Enable Authentication**
   - In Firebase Console, go to Authentication → Sign-in method
   - Enable "Email/Password" sign-in
   - Click Save

3. **Create Firestore Database**
   - In Firebase Console, go to Firestore Database
   - Click "Create database"
   - Choose "Start in test mode" (for development)
   - Select a location (choose closest to your users)

4. **Set up Firestore Collections**
   - Create two collections manually (or let the app create them):
     - `users` - Stores patient information
     - `sessions` - Stores game session data

5. **Get Configuration Files**
   
   **For Android:**
   - In Firebase Console, go to Project Settings
   - Add Android app with package name: `com.example.melo`
   - Download `google-services.json`
   - Place it in: `android/app/google-services.json`

   **For iOS:**
   - In Firebase Console, go to Project Settings
   - Add iOS app with bundle ID: `com.example.melo`
   - Download `GoogleService-Info.plist`
   - Place it in: `ios/Runner/GoogleService-Info.plist`

### Step 2: Install Dependencies

```bash
cd melo
flutter pub get
```

**Note for Windows users:** You may see a message about enabling Developer Mode for symlink support. You can ignore this for now, or enable Developer Mode in Windows settings.

### Step 3: Enable Developer Mode (Windows Only)

If you see the symlink error:
1. Press Windows key + R
2. Type: `ms-settings:developers`
3. Enable "Developer Mode"
4. Retry `flutter pub get`

### Step 4: Run the App

```bash
# For Android
flutter run

# For iOS (macOS only)
flutter run -d ios

# For specific device
flutter devices
flutter run -d <device-id>
```

## 📱 App Navigation Flow

1. **Splash Screen** → Checks if caregiver is logged in
2. **Login Screen** → Caregiver authentication (email/password)
3. **Home Screen** → Patient's main menu (Play Games, Reminders, Settings)
4. **Game Selection** → Choose from available games
5. **Caregiver Dashboard** → Analytics and patient management

## 🎨 Design Principles (Elderly-Friendly)

The app follows these design principles for elderly users:

- **Large Text**: Minimum 20sp font size
- **Large Buttons**: Minimum 60dp height, 80dp for main actions
- **High Contrast**: Dark text on light backgrounds, clear color coding
- **Simple Layout**: Minimal clutter, clear visual hierarchy
- **Touch Targets**: Generous padding and spacing
- **Color Scheme**: Calming green (#4CAF50) as primary color
- **No Small Icons**: Large, clear icons (32px+)

## 🔧 Firebase Services

### Authentication Service (`auth_service.dart`)
- Handles caregiver login/registration
- Email/password authentication
- Session management

### Firestore Service (`firestore_service.dart`)
- User management (create, read, update patients)
- Session tracking (game performance data)
- Analytics queries

## 📊 Data Models

### User Model (`user_model.dart`)
```dart
{
  patientId: String,           // Unique patient ID
  name: String,                // Patient name
  preferredLanguage: String,    // Language preference
  caregiverId: String,         // Associated caregiver
  createdAt: DateTime,         // Profile creation date
  profileImageUrl: String?     // Optional profile picture
}
```

### Session Model (`session_model.dart`)
```dart
{
  sessionId: String,            // Unique session ID
  patientId: String,            // Patient who played
  gameType: String,             // Game type played
  score: int,                   // Game score
  accuracy: double,             // Accuracy (0.0 to 1.0)
  timestamp: DateTime,          // When played
  durationSeconds: int,         // Session duration
  level: int?,                  // Optional difficulty level
  additionalData: Map?          // Game-specific data
}
```

## 🛠️ Development Commands

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Build for Android
flutter build apk

# Build for iOS
flutter build ios

# Run tests
flutter test

# Analyze code
flutter analyze
```

## 📝 Next Steps for Development

1. **Implement Game Logic**
   - Memory Match game
   - Word Puzzle game
   - Picture Quiz game
   - Number Sequence game

2. **Add Reminders Feature**
   - Medication reminders
   - Appointment reminders
   - Daily activity reminders

3. **Enhance Caregiver Dashboard**
   - Patient management UI
   - Progress charts and analytics
   - Session history viewer
   - Report generation

4. **Add Multi-language Support**
   - Assamese
   - Bengali
   - Manipuri
   - Other regional languages

5. **Implement Offline Support**
   - Cache game data
   - Sync when online
   - Offline mode indication

## 🐛 Troubleshooting

### Firebase Initialization Error
- Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are in the correct locations
- Check that Firebase project is properly configured
- Verify package name/bundle ID matches Firebase console

### Build Errors
- Run `flutter clean` then `flutter pub get`
- Ensure Flutter SDK is up to date: `flutter upgrade`
- Check Android/iOS SDK versions

### Permission Issues (Windows)
- Enable Developer Mode in Windows settings
- Run terminal as Administrator

## 📄 License

This project is developed for the hackathon. License details to be determined.

## 👥 Team

- Built for dementia patients in India's North Eastern Region
- Focus on accessibility and cognitive assistance

## 🙏 Acknowledgments

- Firebase for backend services
- Flutter for cross-platform development
- Hackathon organizers and mentors

---

**Note**: This is the foundation setup. Game logic, dashboard analytics, and additional features will be implemented in subsequent phases.