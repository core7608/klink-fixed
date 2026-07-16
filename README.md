# klink — native iOS (SwiftUI)

مشروع iOS أصلي بالكامل بلغة Swift/SwiftUI، مبني من الصفر، منفصل تماماً عن نسخة
الويب (React) ونسخة Capacitor السابقة. يُبنى سحابياً عبر **Codemagic** باستخدام
أحدث إصدار Xcode متاح، عشان يدعم **Liquid Glass الحقيقي** (`.glassEffect()`
من iOS 26 SDK) — وهو API غير متاح على Xcode 15.2 المحلي.

---

## البنية

```
.                           ← جذر المستودع (هنا يعيش codemagic.yaml + project.yml)
├── codemagic.yaml           ← إعداد البناء السحابي الكامل
├── project.yml              ← مواصفة المشروع لـ XcodeGen (بديل عن .xcodeproj يدوي)
└── klink/                   ← جذر كود المصدر الفعلي
    ├── App/                 ← نقطة الدخول (KlinkApp.swift), MainTabView
    ├── Design/               ← نظام الألوان، الثيمات الـ13، الزجاج السائل، أكواد GSAP-style
    │   └── Themes/
    ├── Models/               ← نماذج البيانات (Message, Chat, KlinkUser)
    ├── Services/             ← Firebase, المصادقة, الوسائط, الأمان, المسودات المعلّقة
    │   ├── Media/
    │   └── Security/
    ├── Views/                ← كل الشاشات
    │   ├── Auth/
    │   ├── Chat/
    │   ├── Onboarding/       ← LaunchView + LandingView (الرسوم المتحركة)
    │   ├── Settings/
    │   └── Themes/           ← منتقي الثيمات ومنتقي الأيقونات
    ├── AlternateIcons/       ← 16 أيقونة بديلة (+ الافتراضية في Assets.xcassets) = 17
    ├── Assets.xcassets/
    ├── Info.plist
    └── GoogleService-Info.plist
```

**لماذا XcodeGen بدل `.xcodeproj` يدوي؟** ملفات `.pbxproj` صعبة جداً وعرضة
للأخطاء لو اتكتبت يدوياً بدون Xcode نفسه. `project.yml` ملف بسيط ومقروء،
وXcodeGen بيولّد `.xcodeproj` صحيح 100% منه في كل مرة بناء — تلقائياً كخطوة
أولى في `codemagic.yaml`.

---

## البناء على Codemagic

1. اربط هذا المستودع (repo) بحساب Codemagic
2. Codemagic هيكتشف `codemagic.yaml` تلقائياً ويعرض الـ workflows:
   - **klink-ios-debug** — بناء تجريبي غير موقّع (للتحقق من نجاح الكومبايل بسرعة)
   - **klink-ios-release** — بناء موقّع بالكامل (IPA جاهز للتوزيع/App Store)
3. لتشغيل `klink-ios-release` تحتاج تضيف مجموعة متغيرات بيئة اسمها
   `ios_signing` في إعدادات التطبيق على Codemagic، فيها:
   - `APP_STORE_CONNECT_ISSUER_ID`
   - `APP_STORE_CONNECT_KEY_IDENTIFIER`
   - `APP_STORE_CONNECT_PRIVATE_KEY`
   
   (تقدر تحصل عليهم من App Store Connect → Users and Access → Keys)

كل شي بيتم تلقائياً: تثبيت XcodeGen → توليد المشروع → تحميل حزم Swift Package
Manager (Firebase, GoogleSignIn) → البناء → (في الإصدار الموقّع) رفعه كـ IPA.

---

## الميزات المطبقة في هذه المرحلة

- **تسجيل الدخول**: Google (عبر SDK الأصلي، لا WebView) + بريد/كلمة مرور
- **13 ثيم** كامل (ألوان خلفية/سطح/فقاعات/نص مختلفة تماماً لكل ثيم)
- **17 أيقونة تطبيق** قابلة للتبديل من داخل التطبيق (الإعدادات ← أيقونة التطبيق)
- **بدون اشتراك مدفوع** — كل الميزات مفتوحة للجميع
- **توثيق سري**: كتابة `001ed1v` في أي خانة بحث توثّق الحساب المسجّل دخول فوراً
- **زجاج سائل حقيقي** (Liquid Glass) على البطاقات، الأزرار، الفقاعات
- **صفحة هبوط متحركة** (GSAP-style choreography) قبل شاشة تسجيل الدخول
- **قفل التطبيق ببصمة الوجه/اللمس** (Face ID / Touch ID)، مع كشف لقطات الشاشة
- **الميزة الفريدة**: نظام "المسودات المعلّقة" — لو جالك رد وانت لسه بتكتب رسالة
  طويلة، تقدر "تحفظ" اللي كاتبه بضغطة واحدة، ترد على الرسالة الجديدة فوراً،
  وترجع لمسودتك الأصلية بالظبط زي ما سبتها
- **إرسال كل أنواع الملفات**: صور، فيديو، رسائل صوتية (تسجيل مباشر)، ملفات عامة
- **حذف الرسائل** (soft delete، بنفس منطق نسخة الويب)
- **الرد على رسالة محددة** مع معاينة داخل الفقاعة

## قيد الإنشاء / المراحل القادمة

- المجتمع (Community) — حالياً شاشة placeholder
- المكالمات الصوتية/المرئية
- القصص (Stories)
- إشعارات Push (FCM)

---

## ملاحظة توافق مهمة

هذا المشروع **لا يُبنى محلياً على Xcode 15.2** بسبب استخدام `.glassEffect()`
(متاح فقط في SDK الخاص بـ Xcode 26). البناء **يجب** أن يتم عبر Codemagic
(`xcode: latest` في `codemagic.yaml`) أو على جهاز فيه Xcode 26+ مثبت.
