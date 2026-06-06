import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'core/l10n/app_l10n.dart';
import 'core/network/dio_client.dart';
import 'core/providers/settings_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/services/fcm_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await Hive.initFlutter();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  DioClient().init();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const ProviderScope(child: RapidSaveApp()));
}

class RapidSaveApp extends ConsumerWidget {
  const RapidSaveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final settings = ref.watch(settingsProvider);

    // Only pass 'locale' for languages that GlobalMaterialLocalizations supports.
    // For rw (Kinyarwanda) and sw (Swahili) we fall back to English so that
    // Scaffold, AlertDialog, TextField etc. always find MaterialLocalizations.
    // Our custom AppL10n (via appL10nProvider) handles the actual UI strings
    // independently of this locale setting.
    final Locale? materialLocale = switch (settings.locale.languageCode) {
      'fr' => const Locale('fr'),
      'en' || _ => const Locale('en'),
    };

    return MaterialApp.router(
      title: 'RapidSave',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      locale: materialLocale,
      supportedLocales: const [Locale('en'), Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
