/// MediConnect Pro - Main Entry Point
/// CDC: Architecture Clean, Riverpod, GoRouter, Firebase
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/presentation/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Initialize Firebase ─────────────────────────────────
  // TODO: Uncomment when Firebase is configured
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  // ── Initialize date formatting for French locale ────────
  await initializeDateFormatting('fr_FR', null);

  // ── System UI styling ───────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // ── Preferred orientations ──────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: MediConnectProApp(),
    ),
  );
}

class MediConnectProApp extends ConsumerWidget {
  const MediConnectProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeNotifierProvider);

    return MaterialApp.router(
      // ── App Info ──────────────────────────────────────
      title: 'MediConnect Pro',
      debugShowCheckedModeBanner: false,

      // ── Theme ────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // ── Router ───────────────────────────────────────
      routerConfig: router,

      // ── Localization ─────────────────────────────────
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('fr', 'FR'),
      supportedLocales: const [
        Locale('fr', 'FR'),
        Locale('en', 'US'),
      ],
    );
  }
}
