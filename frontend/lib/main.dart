/// MediConnect Pro - Main Entry Point
/// CDC: Architecture Clean, Riverpod, GoRouter, Firebase
library;

import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logger/logger.dart';

import 'core/constants/app_constants.dart';
import 'core/notifications/enhanced_notification_service.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/notifications/presentation/providers/notification_providers.dart';
import 'features/profile/presentation/providers/theme_provider.dart';
import 'features/video_call/presentation/providers/video_call_providers.dart';

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
      systemNavigationBarColor: AppTheme.neutralGray50,
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

final _appLogger = Logger(printer: PrettyPrinter(methodCount: 0));

class MediConnectProApp extends ConsumerStatefulWidget {
  const MediConnectProApp({super.key});

  @override
  ConsumerState<MediConnectProApp> createState() => _MediConnectProAppState();
}

class _MediConnectProAppState extends ConsumerState<MediConnectProApp> {
  StreamSubscription<String>? _tokenRefreshSubscription;
  Timer? _fcmHeartbeatTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  @override
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    _fcmHeartbeatTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final notificationService = ref.read(enhancedNotificationServiceProvider);
      await notificationService.initialize(onAction: _handleNotificationAction);

      await _registerFcmToken();
      _startFcmHeartbeat();
      _tokenRefreshSubscription =
          FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        await ref
            .read(fcmTokenProvider.notifier)
            .registerToken(token, _platformName());
      });
    } catch (error, stackTrace) {
      _appLogger.w(
        'Push initialization skipped: $error',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _registerFcmToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    await ref
        .read(fcmTokenProvider.notifier)
        .registerToken(token, _platformName());
  }

  void _startFcmHeartbeat() {
    _fcmHeartbeatTimer?.cancel();
    _fcmHeartbeatTimer = Timer.periodic(const Duration(minutes: 30), (_) async {
      await ref.read(fcmTokenProvider.notifier).heartbeat();
    });
  }

  void _handleNotificationAction(String action, Map<String, dynamic> data) {
    switch (action) {
      case 'accept':
        final appointmentId = data['appointment_id']?.toString() ??
            data['consultation_id']?.toString();
        if (appointmentId != null && appointmentId.isNotEmpty) {
          _navigateTo(
            AppRoutes.videoCall.replaceFirst(':appointmentId', appointmentId),
            extra: data,
          );
        }
        return;
      case 'decline':
        final teleconsultationId = data['teleconsultation_id']?.toString();
        if (teleconsultationId != null && teleconsultationId.isNotEmpty) {
          unawaited(
            ref.read(videoCallRepositoryProvider).cancelTeleconsultation(
                  teleconsultationId,
                  reason: 'declined_from_notification',
                ),
          );
        }
        return;
      case 'deep_link':
      case 'tap':
      case 'view':
        final route = _resolveRouteFromPayload(data);
        if (route != null) {
          _navigateTo(route, extra: data);
        }
        return;
    }
  }

  String? _resolveRouteFromPayload(Map<String, dynamic> data) {
    final deepLink = data['deep_link']?.toString();

    if (deepLink != null && deepLink.isNotEmpty) {
      if (deepLink.startsWith('/teleconsultations/') ||
          deepLink.startsWith('/video-call/')) {
        return deepLink;
      }

      if (deepLink.startsWith('/appointments/')) {
        final appointmentId = deepLink.split('/').last;
        final role = ref.read(authNotifierProvider).valueOrNull?.user?.role;
        final route = role == AppConstants.roleDoctor
            ? AppRoutes.doctorAppointmentDetail
            : AppRoutes.appointmentDetail;

        return route.replaceFirst(':id', appointmentId);
      }
    }

    final teleconsultationId = data['teleconsultation_id']?.toString();
    if (teleconsultationId != null && teleconsultationId.isNotEmpty) {
      return AppRoutes.teleconsultationDetail
          .replaceFirst(':id', teleconsultationId);
    }

    final appointmentId = data['appointment_id']?.toString();
    if (appointmentId != null && appointmentId.isNotEmpty) {
      return AppRoutes.videoCall.replaceFirst(':appointmentId', appointmentId);
    }

    return null;
  }

  void _navigateTo(String route, {Map<String, dynamic>? extra}) {
    final context = rootNavigatorKey.currentContext;
    if (context == null) {
      return;
    }

    GoRouter.of(context).push(route, extra: extra);
  }

  String _platformName() {
    if (Platform.isIOS) {
      return 'ios';
    }

    if (Platform.isAndroid) {
      return 'android';
    }

    return Platform.operatingSystem;
  }

  @override
  Widget build(BuildContext context) {
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
