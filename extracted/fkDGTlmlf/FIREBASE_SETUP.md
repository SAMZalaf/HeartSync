# 🔥 Firebase Setup Instructions

## Quick Setup Guide

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add Project" or "Create a Project"
3. Enter project name: **heartsync** (or your preferred name)
4. Enable Google Analytics (optional but recommended)
5. Click "Create Project"

### Step 2: Add Android App to Firebase

1. In your Firebase project, click the **Android icon** (⚙️)
2. Register app with package name: `com.heartsync.app`
3. App nickname (optional): "HeartSync Android"
4. Debug signing certificate SHA-1 (optional for now)
5. Click "Register app"

### Step 3: Download google-services.json

1. Click "Download google-services.json"
2. Move the downloaded file to: `android/app/google-services.json`
   ```bash
   mv ~/Downloads/google-services.json android/app/
   ```

### Step 4: Enable Firebase Services

In Firebase Console, enable these services:

#### Firestore Database
1. Go to "Firestore Database"
2. Click "Create database"
3. Start in **test mode** (for development)
4. Choose location closest to you
5. Click "Enable"

#### Authentication
1. Go to "Authentication"
2. Click "Get Started"
3. Enable "Anonymous" sign-in method (for testing)
4. Click "Save"

#### Cloud Messaging (FCM)
1. Go to "Cloud Messaging"
2. No setup needed - it's enabled by default
3. Note: FCM tokens will be generated automatically

#### Storage
1. Go to "Storage"
2. Click "Get Started"
3. Start in **test mode**
4. Click "Done"

### Step 5: Update Firebase Options

Open `lib/firebase_options.dart` and replace placeholder values with your Firebase project configuration:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'YOUR_ANDROID_API_KEY',              // From google-services.json
  appId: '1:YOUR_APP_ID:android:YOUR_APP_ID',  // From google-services.json
  messagingSenderId: 'YOUR_SENDER_ID',         // From google-services.json
  projectId: 'your-project-id',                // Your Firebase project ID
  storageBucket: 'your-project-id.appspot.com',
);
```

You can find these values in `google-services.json`:
- `apiKey` → `client[0].api_key[0].current_key`
- `appId` → `client[0].client_info.mobilesdk_app_id`
- `messagingSenderId` → `project_info.project_number`
- `projectId` → `project_info.project_id`
- `storageBucket` → `project_info.storage_bucket`

### Step 6: Test Firebase Connection

Run the app and check console for Firebase initialization:
```bash
flutter run
```

Look for: `✅ Firebase initialized` in the console.

## Security Rules (Important!)

### Firestore Security Rules

For **production**, update Firestore rules in Firebase Console:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Interactions collection
    match /interactions/{interactionId} {
      allow read, write: if request.auth != null;
    }
    
    // Messages collection
    match /messages/{messageId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Storage Security Rules

For **production**, update Storage rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Troubleshooting

### Error: "Default FirebaseApp is not initialized"

**Solution:**
- Verify `google-services.json` is in `android/app/`
- Run `flutter clean` and `flutter pub get`
- Rebuild the app

### Error: "com.google.android.gms:play-services-basement"

**Solution:**
- Update Android Studio
- Sync Gradle files
- Run `flutter clean`

### FCM Token is null

**Solution:**
- Ensure Firebase Messaging is enabled in Console
- Check internet connection
- Add FCM permissions to AndroidManifest.xml

## Testing Firebase

### Test Firestore
```dart
// In your app, try saving data:
await FirebaseFirestore.instance.collection('test').add({
  'message': 'Hello Firebase!',
  'timestamp': FieldValue.serverTimestamp(),
});
```

### Test FCM
Use Firebase Console → Cloud Messaging → Send test message

## Production Checklist

Before deploying to production:

- [ ] Update Firestore rules to production mode
- [ ] Update Storage rules to production mode
- [ ] Enable Firebase Authentication (Email/Password or Google Sign-In)
- [ ] Set up Firebase Analytics
- [ ] Configure proper security rules
- [ ] Test all Firebase features thoroughly

---

**Need Help?** Check [Firebase Documentation](https://firebase.google.com/docs)
