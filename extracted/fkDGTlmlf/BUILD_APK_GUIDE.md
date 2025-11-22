# 📦 كيفية بناء ملف APK لتطبيق HeartSync

## متطلبات البناء

1. **Flutter SDK** مثبت على جهازك
2. **Android Studio** أو **Android SDK Tools**
3. **Java JDK** (يأتي مع Android Studio)

## خطوات البناء السريعة ⚡

### 1. تثبيت Flutter

```bash
# Windows/Mac/Linux - قم بتنزيل Flutter من:
# https://docs.flutter.dev/get-started/install

# تحقق من التثبيت
flutter doctor
```

### 2. تكوين Firebase

**مهم جداً!** قبل البناء، يجب إعداد Firebase:

1. اذهب إلى https://console.firebase.google.com
2. أنشئ مشروع جديد
3. أضف تطبيق Android:
   - اسم الحزمة: `com.heartsync.app`
   - قم بتنزيل `google-services.json`
   - ضعه في `android/app/`

4. فعّل الخدمات التالية في Firebase:
   - ✅ Firestore Database
   - ✅ Authentication  
   - ✅ Cloud Messaging
   - ✅ Storage

5. حدّث `lib/firebase_options.dart` بقيم مشروعك

### 3. تثبيت المكتبات

```bash
cd heartsync
flutter pub get
```

### 4. بناء APK للتجربة (Debug)

```bash
flutter build apk --debug
```

📁 الملف في: `build/app/outputs/flutter-apk/app-debug.apk`

### 5. بناء APK للنشر (Release)

```bash
flutter build apk --release
```

📁 الملف في: `build/app/outputs/flutter-apk/app-release.apk`

### 6. بناء APK مقسم (أحجام أصغر) 🚀

```bash
flutter build apk --split-per-abi
```

سينتج 3 ملفات APK مختلفة:
- `app-armeabi-v7a-release.apk` (للأجهزة القديمة)
- `app-arm64-v8a-release.apk` (للأجهزة الحديثة - **الأكثر شيوعاً**)
- `app-x86_64-release.apk` (للمحاكيات)

## تثبيت APK على هاتفك 📱

### الطريقة 1: نقل مباشر
1. انقل ملف APK إلى هاتفك عبر USB
2. افتح الملف على الهاتف
3. اسمح بالتثبيت من مصادر غير معروفة (إذا طُلب)
4. ثبّت التطبيق

### الطريقة 2: عبر ADB
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## حل المشاكل الشائعة 🔧

### خطأ: "Execution failed for task ':app:processDebugGoogleServices'"

**الحل:**
- تأكد من وجود `google-services.json` في `android/app/`
- تأكد من صحة بيانات Firebase

### خطأ: "SDK location not found"

**الحل:**
```bash
# أنشئ ملف android/local.properties
echo "sdk.dir=/path/to/your/Android/sdk" > android/local.properties
```

### خطأ في البناء

**الحل:**
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### التطبيق يتعطل عند البدء

**الحل:**
- تحقق من إعدادات Firebase
- تأكد من تفعيل خدمات Firestore
- راجع السجلات: `flutter logs`

## نصائح مهمة 💡

1. **ملف Release APK** هو الذي تنشره، وليس Debug
2. **Split APK** أصغر حجماً وأفضل للنشر
3. احتفظ بنسخة من ملف `google-services.json`
4. لا تنشر التطبيق بدون اختباره أولاً

## النشر على Google Play Store 🎯

لنشر التطبيق على متجر جوجل بلاي:

1. أنشئ مفتاح توقيع:
```bash
keytool -genkey -v -keystore heartsync-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias heartsync
```

2. أنشئ ملف `android/key.properties`:
```properties
storePassword=<password>
keyPassword=<password>
keyAlias=heartsync
storeFile=<path-to-heartsync-key.jks>
```

3. ابنِ App Bundle:
```bash
flutter build appbundle --release
```

4. ارفع الملف `build/app/outputs/bundle/release/app-release.aab` إلى Play Console

---

## دعم فني 🆘

إذا واجهت مشاكل:
1. راجع `flutter doctor` للتأكد من إعداد البيئة
2. تحقق من سجلات Flutter: `flutter logs`
3. نظّف المشروع: `flutter clean`

**بالتوفيق! 💖**
