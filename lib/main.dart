import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'dart:io' show Platform;

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/constants/app_constants.dart';
import 'features/player/providers/audio_player_provider.dart';
import 'features/notifications/providers/notification_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // CRITICAL for iOS: Initialize JustAudioBackground for iOS lockscreen controls
  // This handles MPRemoteCommandCenter (skip next/previous on lockscreen)
  // Android will use AudioService instead (custom notification)
  if (!kIsWeb && Platform.isIOS) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.breakinghits.monetization.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    );
  }
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Pause background timers when app is not active
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Pause notification auto-refresh to save battery
      ref.read(notificationListProvider.notifier).pauseAutoRefresh();
    } else if (state == AppLifecycleState.resumed) {
      // Resume notification auto-refresh when app is active
      ref.read(notificationListProvider.notifier).resumeAutoRefresh();
    } else if (state == AppLifecycleState.detached) {
      // Stop playback when app is terminated
      ref.read(audioPlayerProvider.notifier).disposePlayer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      
      // Theme Configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      
      // Router Configuration
      routerConfig: router,
    );
  }
}
