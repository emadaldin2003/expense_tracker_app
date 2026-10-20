// screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../theme/theme_controller.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onLogout;
  const SettingsScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('الإعدادات')),
          body: ListView(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('الوضع الليلي'),
                subtitle: const Text('يُحفظ تلقائيًا'),
                value: ThemeController.instance.isDark,
                onChanged: (v) => ThemeController.instance.setDark(v),
              ),
              const Divider(height: 1),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('الإصدار'),
                subtitle: Text('1.0.0 (build 1)'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(Icons.logout, color: scheme.error),
                title: Text(
                  'تسجيل الخروج',
                  style: TextStyle(color: scheme.error),
                ),
                onTap: onLogout,
              ),
            ],
          ),
        );
      },
    );
  }
}