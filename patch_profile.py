import re

with open('lib/features/profile/presentation/screens/profile_screen.dart', 'r') as f:
    content = f.read()

import_statement = "import '../../../../core/providers/theme_provider.dart';\nimport '../../../../core/providers/locale_provider.dart';\n"
if "theme_provider.dart" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_statement)

notification_code = """
                      _SettingsItem(
                        icon: Icons.notifications_outlined,
                        title: loc.profileNotifications,
                        subtitle: loc.profileNotificationsSubtitle,
                        onTap: () => context.push('/notification-settings'),
                      ),
"""

if notification_code in content:
    content = content.replace(notification_code, "")

    new_section = """
              const SizedBox(height: 16),

              // ─── Ayarlar ─────────────────────────────
              _SettingsSection(
                title: loc.profileSettings,
                items: [
                  _SettingsItem(
                    icon: Icons.color_lens_outlined,
                    title: 'Tema',
                    subtitle: ref.watch(themeProvider).name.toUpperCase(),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => SimpleDialog(
                          title: const Text('Tema Seçimi'),
                          children: [
                            SimpleDialogOption(
                              onPressed: () {
                                ref.read(themeProvider.notifier).setTheme(ThemeMode.system);
                                Navigator.pop(ctx);
                              },
                              child: const Text('Sistem'),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                ref.read(themeProvider.notifier).setTheme(ThemeMode.light);
                                Navigator.pop(ctx);
                              },
                              child: const Text('Light'),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);
                                Navigator.pop(ctx);
                              },
                              child: const Text('Dark'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  _SettingsItem(
                    icon: Icons.language_rounded,
                    title: loc.profileLanguage,
                    subtitle: ref.watch(localeProvider).languageCode.toUpperCase(),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => SimpleDialog(
                          title: const Text('Dil Seçimi'),
                          children: [
                            SimpleDialogOption(
                              onPressed: () {
                                ref.read(localeProvider.notifier).setLocale(const Locale('tr'));
                                Navigator.pop(ctx);
                              },
                              child: const Text('Türkçe'),
                            ),
                            SimpleDialogOption(
                              onPressed: () {
                                ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                                Navigator.pop(ctx);
                              },
                              child: const Text('English'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  _SettingsItem(
                    icon: Icons.notifications_outlined,
                    title: loc.profileNotifications,
                    subtitle: loc.profileNotificationsSubtitle,
                    onTap: () => context.push('/notification-settings'),
                  ),
                ],
              ),
"""
    # Insert new section before App section
    app_section_marker = "              // ─── Uygulama Ayarları ─────────────────────────────"
    content = content.replace(app_section_marker, new_section + "\n" + app_section_marker)

with open('lib/features/profile/presentation/screens/profile_screen.dart', 'w') as f:
    f.write(content)

