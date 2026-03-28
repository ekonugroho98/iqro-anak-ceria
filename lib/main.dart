import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'providers/progress_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';
import 'services/ad_service.dart';
import 'services/iap_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Portrait only — anak lebih mudah pegang HP tegak
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Muat semua provider sebelum app ditampilkan
  final progressProvider = ProgressProvider();
  final settingsProvider = SettingsProvider();
  await Future.wait([
    progressProvider.load(),
    settingsProvider.load(),
  ]);

  // Inisialisasi AdMob dengan COPPA compliance sebelum runApp,
  // sehingga iklan pertama sudah preload saat user tiba di home screen.
  await AdService().initialize();

  // Inisialisasi IAP — query produk dari Google Play di background.
  // Tidak await agar tidak memperlambat startup jika Play Store lambat merespons.
  unawaited(IapService().initialize());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: progressProvider),
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: const IqroAnakCeriaApp(),
    ),
  );
}

class IqroAnakCeriaApp extends StatelessWidget {
  const IqroAnakCeriaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Iqro Anak Ceria',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}