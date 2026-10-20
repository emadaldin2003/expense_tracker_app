# محتوى `README.md` كامل بالعربية

احفظ الملف باسم `README.md` في **جذر** المشروع (نفس مجلد `pubspec.yaml`، وليس داخل `lib/` أو `android/`).

> **ملاحظة:** أوامر الأوامر (bash) وأسماء الملفات والمسارات والأسماء التقنية بقيت بالإنجليزية لأنها يجب أن تبقى كما هي لتعمل. أما النصوص الوصفية فمترجمة.

---

```markdown
# تطبيق تتبع المصروفات

تطبيق عربي (من اليمين إلى اليسار) لتتبع المصروفات والإيرادات، مبني بـ Flutter وSQLite. يعمل محليًا بالكامل: كل البيانات تبقى على الجهاز، وكلمات المرور تُجزَّأ قبل حفظها.

## المشكلة التي يحلّها

تتبّع المصروفات اليومية والإيرادات دون الحاجة إلى حساب سحابي أو اتصال بالإنترنت. يستهدف التطبيق الناطقين بالعربية ويقدّم تجربة استخدام نظيفة موجّهة للجوال أولًا.

## الميزات

- واجهة عربية من اليمين إلى اليسار (Material 3).
- حسابات مستخدمين محلية بكلمات مرور مُجزَّأة (SHA-256 + ملح عشوائي).
- إضافة / تعديل / حذف معاملات المصروفات والإيرادات.
- فئات (طعام، مواصلات، ترفيه، سكن، صحة، تعليم، أخرى).
- بحث بالعنوان أو الفئة.
- تصفية حسب التاريخ: الكل، اليوم، هذا الأسبوع (يبدأ السبت)، هذا الشهر.
- شاشة إحصائيات مع تفصيل حسب الفئة وأشرطة تقدّم.
- حذف ناعم إلى سلة المهملات، مع إمكانية الاستعادة والحذف النهائي.
- وضع نهاري / ليلي، مع حفظ التفضيل محليًا.
- تخزين SQLite مع `ON DELETE CASCADE` و `PRAGMA foreign_keys = ON`.

## التقنيات

- Flutter (Dart SDK `^3.10.7`).
- `sqflite` لقاعدة بيانات SQLite.
- `crypto` لتجزئة كلمات المرور.
- `shared_preferences` لحفظ تفضيل الثيم.
- `flutter_localizations` للتعريب.

## بنية المشروع

```
lib/
├── main.dart
├── theme/
│   ├── app_theme.dart
│   └── theme_controller.dart
├── database/
│   └── db_helper.dart
├── models/
│   ├── user.dart
│   └── expense.dart
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── main_shell.dart
│   ├── home_screen.dart
│   ├── add_expense_screen.dart
│   ├── statistics_screen.dart
│   ├── trash_screen.dart
│   └── settings_screen.dart
└── widgets/
    ├── expense_card.dart
    ├── expense_list.dart
    ├── stat_card.dart
    ├── date_filter_chips.dart
    ├── empty_state.dart
    └── confirm_dialog.dart
```

## البدء

### المتطلبات

- Flutter SDK `>= 3.38.0`.
- Dart `>= 3.10.7`.
- Android SDK (يُستخرج `minSdk` من أدوات Flutter).

### التشغيل

```bash
flutter pub get
flutter run
```

### الاختبارات

```bash
flutter test
```

### التحليل الساكن

```bash
flutter analyze
```

## لقطات الشاشة

لقطات الشاشة غير مضمّنة بعد. أضفها تحت `docs/screenshots/` وأدرجها هنا، مثل:

```
![الرئيسية](docs/screenshots/home.png)
![الإحصائيات](docs/screenshots/statistics.png)
![السلة](docs/screenshots/trash.png)
```

## القيود المعروفة

- محلي بالكامل، جهاز واحد. لا مزامنة بين الأجهزة.
- كلمات المرور مُجزَّأة بـ SHA-256 مع ملح لكل مستخدم. للإنتاج، يُفضَّل استخدام Argon2 أو bcrypt.
- `applicationId` هو `com.example.expense_tracker_app`. يجب تغييره قبل النشر على Google Play.
- لا CI، لا اختبارات تكامل، لا تصدير (CSV / PDF).
- لا حفظ للجلسة: إغلاق التطبيق يتطلب تسجيل الدخول مرة أخرى.

## الترخيص

غير محدد. أضف ملف `LICENSE` إن كنت تنوي السماح بإعادة الاستخدام.
```

---

## أين تحفظه وكيف ترفعه

1. احفظ المحتوى أعلاه في ملف باسم `README.md` في **جذر المشروع**:
   ```
   expense_tracker_app/
   ├── README.md      ← هنا
   ├── pubspec.yaml
   ├── lib/
   └── android/
   ```

2. بعد الحفظ، من داخل مجلد المشروع:

```powershell
git status
```
يجب أن يظهر `README.md` ضمن "Untracked files".

3. ثم:

```powershell
git add README.md
git commit -m "docs: add Arabic README"
git push
```
