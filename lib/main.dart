// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'database/db_helper.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final dbHelper = DatabaseHelper();
    await dbHelper.database;
    debugPrint('تم تهيئة قاعدة البيانات بنجاح.');
  } catch (e) {
    debugPrint('خطأ في تهيئة قاعدة البيانات: $e');
  }

  try {
    await ThemeController.instance.load();
  } catch (e) {
    debugPrint('تعذّر تحميل تفضيل الثيم: $e');
  }

  runApp(const ExpenseTrackerApp());
}


class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'تتبع المصروفات',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeController.instance.mode,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: LoginScreen(),
        );
      },
    );
  }
}