# 📦 دليل بناء ملف AAB للنشر على Google Play

## 🎯 نظرة عامة
هذا الدليل يشرح كيفية بناء ملف Android App Bundle (AAB) لتطبيق HeartSync للنشر على Google Play Store.

---

## ⚙️ المتطلبات الأساسية

### 1. تثبيت Flutter
```bash
# تأكد من تثبيت Flutter
flutter --version

# إذا لم يكن مثبتاً، قم بتحميله من:
# https://flutter.dev/docs/get-started/install
```

### 2. إعداد Android SDK
```bash
# تأكد من تثبيت Android SDK
flutter doctor

# يجب أن ترى:
# ✓ Android toolchain - develop for Android devices
```

### 3. تثبيت Java JDK
```bash
# تأكد من تثبيت JDK 11 أو أحدث
java -version
```

---

## 🔥 إعداد Firebase

### 1. تنزيل google-services.json
1. اذهب إلى [Firebase Console](https://console.firebase.google.com)
2. اختر مشروعك أو أنشئ مشروع جديد
3. أضف تطبيق Android
4. Package name: `com.heartsync.app`
5. حمّل ملف `google-services.json`
6. ضعه في: `android/app/google-services.json`

### 2. تفعيل خدمات Firebase
- **Authentication**: فعّل تسجيل الدخول المجهول
- **Firestore Database**: أنشئ قاعدة بيانات
- **Cloud Messaging**: تلقائياً مفعّل
- **Storage**: أنشئ storage bucket

---

## 🔑 إنشاء Keystore للتوقيع

### 1. إنشاء ملف keystore جديد
```bash
keytool -genkey -v -keystore ~/heartsync-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias heartsync

# املأ المعلومات المطلوبة:
# - Password: اختر كلمة مرور قوية (احفظها!)
# - First and Last Name: اسم الشركة/المطور
# - Organizational Unit: قسم التطوير
# - Organization: اسم المنظمة
# - City/Locality: المدينة
# - State/Province: المنطقة
# - Country Code: رمز البلد (مثال: SA للسعودية)
```

### 2. إنشاء ملف key.properties
```bash
# أنشئ الملف: android/key.properties
nano android/key.properties
```

أضف المحتوى التالي:
```properties
storePassword=كلمة_المرور_التي_اخترتها
keyPassword=كلمة_المرور_التي_اخترتها
keyAlias=heartsync
storeFile=/home/runner/heartsync-release-key.jks
```

⚠️ **مهم جداً**: لا تشارك هذا الملف أو تضعه في Git!

---

## 📝 تحديث ملف build.gradle

### 1. فتح android/app/build.gradle
```bash
nano android/app/build.gradle
```

### 2. إضافة تكوين التوقيع

أضف قبل `android {`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

داخل `android {` أضف:
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
    }
}
```

---

## 🏗️ بناء ملف AAB

### 1. تنظيف المشروع
```bash
flutter clean
flutter pub get
```

### 2. بناء AAB
```bash
flutter build appbundle --release

# أو مع تحديد target-platform معين:
flutter build appbundle --release --target-platform android-arm,android-arm64,android-x64
```

### 3. موقع ملف AAB
```
build/app/outputs/bundle/release/app-release.aab
```

---

## 📤 رفع AAB إلى Google Play

### 1. إنشاء حساب Google Play Developer
- اذهب إلى: https://play.google.com/console
- ادفع رسوم التسجيل (25$ مرة واحدة)

### 2. إنشاء تطبيق جديد
1. اضغط "Create app"
2. املأ التفاصيل:
   - App name: HeartSync
   - Default language: العربية أو English
   - App or game: App
   - Free or paid: Free

### 3. رفع AAB
1. Production > Create new release
2. Upload the AAB file
3. Release name: 1.0.0
4. Release notes (بالعربية والإنجليزية)

### 4. ملء معلومات التطبيق
- **App content**:
  - Privacy policy
  - Target audience
  - Content rating
  - Data safety

- **Store listing**:
  - App name: HeartSync
  - Short description (80 chars)
  - Full description (4000 chars)
  - Screenshots (2-8 images)
  - Feature graphic (1024 x 500)
  - App icon (512 x 512)

---

## 🎨 متطلبات الصور

### Screenshots
- **حجم**: 1080 x 1920 (portrait) أو 1920 x 1080 (landscape)
- **عدد**: 2-8 صور
- **نصيحة**: استخدم أداة Screener من Google

### Feature Graphic
- **حجم**: 1024 x 500 pixels
- **صيغة**: PNG أو JPEG
- **يجب**: أن تكون جذابة وتمثل التطبيق

### App Icon
- **حجم**: 512 x 512 pixels
- **صيغة**: PNG بدون transparency
- **ملاحظة**: مختلف عن icon داخل التطبيق

---

## ✅ قائمة المراجعة النهائية

قبل النشر، تأكد من:

- [ ] ملف google-services.json في مكانه الصحيح
- [ ] تم إنشاء keystore وحفظ كلمة المرور
- [ ] تم تحديث version في pubspec.yaml
- [ ] تم اختبار التطبيق على أجهزة حقيقية
- [ ] Firebase services مفعّلة ومكوّنة
- [ ] Privacy policy جاهزة
- [ ] Screenshots وصور التطبيق جاهزة
- [ ] وصف التطبيق مكتوب بالعربية والإنجليزية
- [ ] تم بناء AAB بنجاح
- [ ] تم اختبار AAB على جهاز

---

## 🔧 حل المشاكل الشائعة

### مشكلة: "Keystore file not found"
```bash
# تأكد من المسار في key.properties
ls -la ~/heartsync-release-key.jks
```

### مشكلة: "google-services.json not found"
```bash
# تأكد من وجود الملف
ls -la android/app/google-services.json
```

### مشكلة: "Build failed"
```bash
# نظف وأعد البناء
flutter clean
rm -rf build/
flutter pub get
flutter build appbundle --release
```

---

## 📱 اختبار AAB قبل النشر

### استخدام bundletool
```bash
# تحميل bundletool
wget https://github.com/google/bundletool/releases/download/1.15.6/bundletool-all-1.15.6.jar

# إنشاء APK من AAB للاختبار
java -jar bundletool-all-1.15.6.jar build-apks \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=app-release.apks \
  --mode=universal

# فك الضغط والتثبيت
unzip app-release.apks -d apks
adb install apks/universal.apk
```

---

## 🎉 مبروك!

بعد اتباع هذه الخطوات، سيكون تطبيق HeartSync جاهزاً للنشر على Google Play Store!

### الخطوات التالية:
1. انتظر مراجعة Google (عادة 1-3 أيام)
2. راقب التقييمات والتعليقات
3. حدّث التطبيق بانتظام
4. استجب لملاحظات المستخدمين

---

## 📞 دعم إضافي

- [Flutter Deployment Guide](https://flutter.dev/docs/deployment/android)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [Firebase Documentation](https://firebase.google.com/docs)
