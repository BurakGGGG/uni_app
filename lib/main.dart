import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/shared_preferences_provider.dart';
import 'router/app_router.dart';
import 'features/notifications/data/fcm_service.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Timeago Türkçe lokalizasyonu (Sprint 3 — Kişi B)
  timeago.setLocaleMessages('tr', timeago.TrMessages());
  timeago.setDefaultLocale('tr');

  // Asenkron işlemleri paralel başlat (Cold Start optimizasyonu)
  final results = await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    SharedPreferences.getInstance(),
  ]);
  
  final prefs = results[1] as SharedPreferences;

  // Firestore offline persistence'i maksimum önbellekleme için yapılandır
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Status bar stilini ayarla
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
    ),
  );

  // Tercih edilen oryantasyonlar
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const UniSecApp(),
    ),
  );
}

/// ÜniSeç ana uygulama widget'ı
class UniSecApp extends ConsumerStatefulWidget {
  const UniSecApp({super.key});

  @override
  ConsumerState<UniSecApp> createState() => _UniSecAppState();
}

class _UniSecAppState extends ConsumerState<UniSecApp> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FCMService().init();
      
      // Notification tap → router push
      FCMService().onNotificationTap = (data) {
        final route = data['route'] as String?;
        if (route != null && route.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(routerProvider).push(route);
          });
        }
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
