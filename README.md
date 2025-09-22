# README — مشروع “مشروع فايربيس المستخدمين”

> هذا الدليل يشرح **كيف تنشئ المشروع من الصفر**، **تربطه بفايربيس عبر `flutterfire configure`**، **تفعّل الخدمات المطلوبة**، ثم يشرح **سير عمل التطبيق** والعمليات الأساسية (تسجيل الدخول/الإنشاء/الخروج/جلب المستخدمين/التحقق من الجلسة) مع **نصائح نشر واستكشاف أخطاء شائعة**.

---

## 1) المتطلبات

* **Flutter**: يُفضّل 3.22+

  ```bash
  flutter --version
  ```
* **Dart**: يتماشى مع إصدار Flutter المستخدَم.
* **Firebase CLI**:

  ```bash
  npm i -g firebase-tools
  firebase login
  firebase --version
  ```
* **FlutterFire CLI**:

  ```bash
  dart pub global activate flutterfire_cli
  flutterfire --version
  ```
* حساب Google مفعّل عليه Firebase.

---

## 2) إنشاء مشروع Flutter (لو لم يكن موجودًا)

```bash
flutter create users_firebase_project
cd users_firebase_project
```

> إن كان مشروعك موجودًا، تَخَطَّ هذه الخطوة.

---

## 3) إضافة حزم Firebase في `pubspec.yaml`

أضف (أو حدّث) التبعيات الأساسية:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.4.0
  firebase_auth: ^5.1.1
  cloud_firestore: ^5.2.1

  # للواجهة
  flutter_localizations:
    sdk: flutter
```

ثم:

```bash
flutter pub get
```

> **ملاحظة:** الإصدارات أعلاه أمثلة شائعة حديثة. استخدم آخر الإصدارات المتوافقة مع قناة Flutter لديك.

---

## 4) إنشاء مشروع Firebase وربطه بالتطبيق

### 4.1 إنشاء مشروع على Firebase Console

1. ادخل إلى [Firebase Console](https://console.firebase.google.com/).
2. “**Add project**” ثم اختر اسمًا مناسبًا (مثل `userprofile-4fb32`).
3. أنشئ المشروع.

### 4.2 ربط Flutter بالتطبيق عبر `flutterfire configure`

من جذر مشروع Flutter:

```bash
flutterfire configure
```

* اختر مشروع Firebase الذي أنشأته.
* اختر المنصات (Android / iOS / Web) بحسب ما تريد دعمه.
* سينشئ الملف:

  ```
  lib/firebase_options.dart
  ```
* وسيتم **تسجيل** تطبيقات المنصات في Firebase (إن لم تكن مسجّلة).

> **معلومة مهمّة:** إذا فشل إنشاء تطبيق الويب (حدثت لك سابقًا رسالة شبيهة بـ `Failed to create web app`)، لديك خياران:
>
> 1. جرّب تحديث Firebase CLI ثم أعد الأمر:
     >
     >    ```bash
>    npm i -g firebase-tools
>    firebase logout
>    firebase login
>    flutterfire configure
>    ```
> 2. أو أنشئ تطبيق الويب يدويًا من Firebase Console (Settings → Project settings → Your apps → Web) ثم أعد تشغيل `flutterfire configure` ليقرأ الإعدادات.

---

## 5) إعدادات منصات التشغيل

### 5.1 Android

* تأكد أن الملف `android/app/google-services.json` تم توليده (الـ CLI يتكفّل به).
* في `android/build.gradle` و `android/app/build.gradle` عادة يضيف FlutterFire التهيئة تلقائيًا. إن احتجت:

    * الجذر:

      ```gradle
      dependencies {
        classpath 'com.google.gms:google-services:4.4.2'
      }
      ```
    * داخل `android/app/build.gradle`:

      ```gradle
      apply plugin: 'com.google.gms.google-services'
      ```

### 5.2 iOS

* تأكد من وجود `ios/Runner/GoogleService-Info.plist`.
* افتح المشروع بـ Xcode أول مرة لتأكيد الدمج.
* في بعض الحالات أضف في `ios/Runner/Info.plist` مفاتيح الشبكة (إن استخدمت HTTP خارجية).

### 5.3 Web (اختياري)

* FlutterFire يحقن الـ config بالملف `firebase_options.dart`.
* لا تحتاج لتعديل `web/index.html` يدويًا عادة.

---

## 6) تفعيل خدمات Firebase

### 6.1 المصادقة (Authentication)

* من **Firebase Console → Authentication → Get started**.
* فعّل **Email/Password**.

### 6.2 قاعدة البيانات (Cloud Firestore)

* من **Firestore Database → Create database**.
* اختر **Production mode** (ثم أنشئ قواعد مناسبة — انظر الأسفل).

#### قواعد أمان Firestore المقترحة (أبسط بداية)

> لا تستخدم هذه القواعد في الإنتاج بدون مراجعة أمنية، لكنها مناسبة كبداية تجريبية:

```
// Firestore rules (نسخة مبسطة)
// السماح بالقراءة/الكتابة للمستخدمين المسجلين فقط
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == uid;
    }
    // افتراضياً منع كل شيء آخر
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

> القاعدة تمنع كتابة مستخدم لمستند مستخدم آخر (يكتب فقط على `users/{uid}` الخاص به).

---

## 7) التهيئة داخل Flutter

### 7.1 التهيئة في `main()`

الكود لديك بالفعل:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}
```

> ملف `DefaultFirebaseOptions` يأتي من `lib/firebase_options.dart` الذي أنشأه `flutterfire configure`.

### 7.2 اللغة والثيم والملاحة

* `MyApp` يضبط الثيم (فاتح/داكن)، الـ `locale` إلى العربية (السعودية)، ويستخدم `navigatorKey` و `onGenerateRoute`.

---

## 8) بنية المشروع (مقترحة سريعة)

```
lib/
  main.dart
  firebase_options.dart        # مُولّد
  router/
    app_router.dart            # إن أحببت فصل الراوتر
  services/
    auth_service.dart          # AuthService
    user_repo.dart             # UserRepo (Firestore)
  ui/
    splash_gate.dart           # SplashGate
    auth/
      sign_in_view.dart
      sign_up_view.dart
    dashboard/
      dashboard_view.dart
      users_view.dart
      settings_view.dart
    widgets/
      background_shapes.dart
```

> في كودك الحالي كل شيء ضمن ملف واحد—يعمل، لكن التقسيم أعلاه أسهل صيانةً.

---

## 9) شرح سير عمل التطبيق (Flow)

### 9.1 شاشة البداية (SplashGate)

* **المسؤولية:** الانتظار حتى يحدّد Firebase ما إذا كان هناك مستخدم مسجّل دخول أم لا.
* **كيف تعمل:** تستمع لـ `authService.auth$`:

    * إن كان `User == null` → تنتقل إلى **تسجيل الدخول**.
    * إن كان `User != null` → تنتقل إلى **الداشبورد**.
* يوجد **AnimationController** لدوّار بسيط أثناء التحميل.

### 9.2 المصادقة (AuthService)

* `signIn(email, password)` → **تسجيل دخول**.
* `signUp(email, password, displayName)` → **إنشاء حساب** + تحديث اسم العرض.
* `signOut()` → **تسجيل خروج**.
* `auth$` → **Stream\<User?>** لتحديث الحالة.
* `current` → المستخدم الحالي أو `null`.

### 9.3 إنشاء مستند المستخدم (UserRepo)

* عند نجاح التسجيل (`SignUpView._register`):

    1. ينشأ المستخدم عبر `AuthService.signUp`.
    2. ننشيء مستند Firestore عبر:

       ```dart
       userRepo.createUserDoc(user: cred.user!, name: _name.text.trim());
       ```

    * الحقول المخزّنة: `uid, name, email, photoUrl, createdAt, lastSeenAt`.

### 9.4 شاشة تسجيل الدخول (SignInView)

* نموذج يتحقق من البريد وكلمة المرور.
* ينادي `authService.signIn`.
* عند النجاح → يذهب إلى `Routes.dashboard`.

### 9.5 شاشة إنشاء الحساب (SignUpView)

* نموذج: الاسم/البريد/كلمة المرور.
* ينادي `authService.signUp` ثم `userRepo.createUserDoc`.
* عند النجاح → `Routes.dashboard`.

### 9.6 لوحة التحكم (DashboardView)

* **Bottom Navigation** بلسانين:

    1. **UsersView** (عرض المستخدمين)
    2. **SettingsView** (حساب/تفضيلات/خروج)
* يستخدم `IndexedStack` كي **لا يعيد بناء** التبويبات عند التبديل.

### 9.7 شاشة المستخدمين (UsersView)

* **StreamBuilder** على `userRepo.users$()`:

    * يقرأ آخر 100 مستخدم مرتّبين تنازليًا حسب `createdAt`.
* لكل مستخدم: بطاقة فيها الاسم، البريد، وتاريخ الإنشاء.
* زر “**تحديث آخر ظهور**” ينادي:

  ```dart
  userRepo.touchLastSeen(u.uid);
  ```

### 9.8 شاشة الإعدادات (SettingsView)

* ترويسة جميلة بمعلومات البريد والاسم.
* بطاقة “حساب” تعرض الاسم والبريد.
* بطاقة “التفضيلات” (لغة/مظهر – ثابتة الآن للعرض).
* زر “تسجيل الخروج” مع **تأكيد**، ثم:

  ```dart
  authService.signOut();
  navKey.currentState?.pushNamedAndRemoveUntil(Routes.signIn, (_) => false);
  ```

---

## 10) بنية بيانات Firestore

* مجموعة: **`users`**

    * مستند: **`{uid}`**

        * `uid`: String
        * `name`: String
        * `email`: String
        * `photoUrl`: String? (قد تكون null)
        * `createdAt`: `FieldValue.serverTimestamp()`
        * `lastSeenAt`: `FieldValue.serverTimestamp()`

> **ملاحظة:** لأننا نستخدم `serverTimestamp()`، سيظهر الحقل null أول مرة على الجهاز حتى يكتب السيرفر القيمة ثم تُحدَّث بالستريم لاحقًا—هذا طبيعي.

---

## 11) التشغيل محليًا

### Android

```bash
flutter run -d android
```

### iOS

* أوّل مرة: افتح `ios/Runner.xcworkspace` من Xcode وشغّل على Simulator/جهاز حقيقي.

```bash
flutter run -d ios
```

### Web (اختياري)

```bash
flutter run -d chrome
```

---

## 12) البناء للإصدار (Release)

### Android (APK/AAB)

```bash
flutter build apk --release
# أو
flutter build appbundle --release
```

> تذكر إعداد توقيع Android إن رغبت بالنشر على Play.

### iOS

```bash
flutter build ios --release
```

> التوقيع، الـ Provisioning Profiles عبر Xcode/App Store Connect.

---

## 13) العمليات الأساسية (تلخيص عملي مع الإشارات للكود)

* **التحقق من تسجيل الدخول تلقائيًا**:

    * في `SplashGate.initState` عبر `authService.auth$`.
* **تسجيل الدخول**:

    * `SignInView._login()` → `authService.signIn(email, pass)`.
* **إنشاء حساب**:

    * `SignUpView._register()` → `authService.signUp(...)` ثم `userRepo.createUserDoc(...)`.
* **تسجيل الخروج**:

    * `SettingsView._confirmLogout()` → `authService.signOut()`.
* **جلب المستخدمين**:

    * `UsersView` عبر `userRepo.users$()`.
* **تحديث آخر ظهور**:

    * `userRepo.touchLastSeen(uid)`.

---

## 14) استكشاف أخطاء شائعة

### A) `flutterfire configure` فشل في إنشاء تطبيق الويب

* حدّث Firebase CLI وأعد تسجيل الدخول:

  ```bash
  npm i -g firebase-tools
  firebase logout
  firebase login
  flutterfire configure
  ```
* أو أنشئ تطبيق الويب يدويًا من Firebase Console، ثم أعد `flutterfire configure`.

### B) `Firebase.initializeApp` لا يجد `firebase_options.dart`

* تأكد أن `flutterfire configure` ولّد `lib/firebase_options.dart`.
* تأكد من الاستيراد:

  ```dart
  import 'firebase_options.dart';
  ```

### C) Firestore لن يقرأ/يكتب

* راجع **قواعد الأمان**.
* تأكد أن المستخدم **مسجّل دخول** قبل القراءة/الكتابة.
* تأكد من تمكين Firestore من الـ Console (Production mode).

### D) مشاكل Android Gradle/Namespace

* بعض الحِزم القديمة تحتاج تحديث أو إضافة `namespace` في `android/build.gradle` للحزمة المعطِّلة.
* حدّث الحزمة (مثال: `flutter_barcode_scanner`) أو أضف:

  ```gradle
  android {
    namespace "com.example.users_firebase_project" // مثال
  }
  ```

### E) iOS — مشاكل الصلاحيات/الشبكة

* أضف ما يلزم في `Info.plist` إن احتجت HTTP أو إعدادات خاصة.

---

## 15) تحسينات اختيارية

* فصل الملفات (Services/Repo/Views/Router) لسهولة الصيانة.
* إضافة **حماية إضافية** في قواعد Firestore (تحقق من الإيميل/صلاحيات إضافية).
* إضافة **تحديث الاسم/الصورة** من إعدادات الحساب.
* فلاتر/بحث في قائمة المستخدمين.
* دعم **مزامنة `photoURL`** إذا أضفت تحميل صور للملف الشخصي.

---

## 16) أسئلة متكررة

**س: هل يلزم `google-services.json` و `GoogleService-Info.plist` يدويًا؟**
ج: `flutterfire configure` يعتني بها غالبًا. إن لم تُنسخ تلقائيًا، نزّلها من إعدادات المشروع وضعها بمواضعها.

**س: لماذا تاريخ الإنشاء يظهر `—` لبعض المستخدمين؟**
ج: لأن الحقل `createdAt` يُملأ من الخادم عبر `serverTimestamp()`، قد يظهر فارغًا لحظيًا حتى تصل القيمة من Firestore ثم يحدث التحديث عبر الـ Stream.

---

## 17) مقتطفات من الكود لديك (للمراجعة السريعة)

* **التهيئة:**

  ```dart
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  ```
* **التحويل بين الشاشات بعد نجاح المصادقة:**

  ```dart
  navKey.currentState?.pushNamedAndRemoveUntil(Routes.dashboard, (_) => false);
  ```
* **إنشاء مستند المستخدم:**

  ```dart
  await userRepo.createUserDoc(user: cred.user!, name: _name.text.trim());
  ```
* **جلب المستخدمين:**

  ```dart
  userRepo.users$()
  ```
* **تحديث آخر ظهور:**

  ```dart
  userRepo.touchLastSeen(u.uid);
  ```
* **الخروج:**

  ```dart
  await authService.signOut();
  ```

---

## 18) خاتمة

بهذه الخطوات تكون:

1. أنشأت وربطت تطبيق Flutter بفايربيس عبر **`flutterfire configure`**.
2. فعّلت **Auth** و**Firestore**.
3. شغّلت التطبيق محليًا، مع تدفق مصادقة كامل وشاشة عرض للمستخدمين.

لو رغبت، أقدر أحوّل هذا الدليل إلى **ملف `README.md`** مُهيّأ جاهزًا للنسخ داخل مشروعك (مع جدول محتويات وروابط سريعة).
