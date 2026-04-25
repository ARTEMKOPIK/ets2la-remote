import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:ets2la_remote/l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'providers/connection_provider.dart';
import 'providers/telemetry_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/update_provider.dart';
import 'screens/dashboard_screen.dart';
import 'services/local_server.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Start the local Unity server in the background — startup failures here
  // are non-fatal (visualization is optional) so we keep it unawaited,
  // but log any error so it shows in crash reports.
  ensureStartedBg() async {
    try {
      await LocalUnityServer.instance.ensureStarted();
    } catch (e, st) {
      debugPrint('LocalUnityServer.startup failed (non-fatal): $e\n$st');
    }
  }
  unawaited(ensureStartedBg());

  // Pre-load settings before building the widget tree
  final settings = await AppSettings.create();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(ETS2LARemoteApp(settings: settings));
}

class ETS2LARemoteApp extends StatelessWidget {
  final AppSettings settings;
  const ETS2LARemoteApp({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
        ChangeNotifierProvider(create: (_) => TelemetryProvider()),
        ChangeNotifierProvider(create: (_) => UpdateProvider()),
      ],
      child: Consumer<AppSettings>(
        builder: (context, settings, child) {
          // Reduce-motion: swap in a no-op page-transition builder so
          // route pushes are instantaneous. Also drives `AnimatedSwitcher`
          // duration choices across the app via `AppSettings.reduceMotion`.
          final theme = AppTheme.build(
            accent: settings.accentColor,
            highContrast: settings.highContrast,
          );
          final themed = settings.reduceMotion
              ? theme.copyWith(
                  pageTransitionsTheme: const PageTransitionsTheme(
                    builders: {
                      TargetPlatform.android: _NoTransitionsBuilder(),
                      TargetPlatform.iOS: _NoTransitionsBuilder(),
                    },
                  ),
                )
              : theme;
          return MaterialApp(
            title: 'ETS2LA Remote',
            debugShowCheckedModeBanner: false,
            theme: themed,

            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('ru'),
            ],
            locale: settings.locale,
            localeResolutionCallback: (locale, supportedLocales) {
              for (final supported in supportedLocales) {
                if (supported.languageCode == locale?.languageCode) {
                  return supported;
                }
              }
              return const Locale('en');
            },

            home: const DashboardScreen(),
          );
        },
      ),
    );
  }
}

/// Page-transition builder that returns the child unchanged — used when
/// `AppSettings.reduceMotion` is on. Matches the contract of
/// [PageTransitionsBuilder] so it can drop into a [PageTransitionsTheme].
class _NoTransitionsBuilder extends PageTransitionsBuilder {
  const _NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}