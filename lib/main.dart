import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'providers/connection_provider.dart';
import 'providers/telemetry_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/connect_screen.dart';
import 'services/local_server.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LocalUnityServer.instance.ensureStarted();

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

  runApp(const ETS2LARemoteApp());
}

class ETS2LARemoteApp extends StatelessWidget {
  const ETS2LARemoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppSettings()),
        ChangeNotifierProvider(create: (_) => ConnectionProvider()),
        ChangeNotifierProvider(create: (_) => TelemetryProvider()),
      ],
      child: Consumer<AppSettings>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'ETS2LA Remote',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            
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
            locale: settings.language != null 
                ? Locale(settings.language!) 
                : null,
            localeResolutionCallback: (locale, supportedLocales) {
              for (final supported in supportedLocales) {
                if (supported.languageCode == locale?.languageCode) {
                  return supported;
                }
              }
              return const Locale('en');
            },
            
            home: const ConnectScreen(),
          );
        },
      ),
    );
  }
}