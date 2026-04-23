import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ets2la_remote/l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

/// Three-page first-run walkthrough. Shown exactly once per install, gated
/// by [AppSettings.hasSeenOnboarding]. Not meant to replace the connect
/// screen — its only job is to orient new users (what the app does, the
/// fact that ETS2LA must be running on PC, the "same Wi-Fi" requirement).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _index = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() {
    context.read<AppSettings>().markOnboardingSeen();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = <_OnboardingPage>[
      _OnboardingPage(
        icon: Icons.phone_android_rounded,
        title: l10n?.firstRunWelcomeTitle ?? 'Welcome to ETS2LA Remote',
        body: l10n?.firstRunWelcomeBody ??
            'Control autopilot and view truck telemetry right from your phone.',
      ),
      _OnboardingPage(
        icon: Icons.computer_rounded,
        title: l10n?.firstRunLaunchTitle ?? 'Launch ETS2LA on PC',
        body: l10n?.firstRunLaunchBody ??
            'Before connecting, make sure ETS2LA is running on your computer. The app talks to its WebSocket API.',
      ),
      _OnboardingPage(
        icon: Icons.wifi_rounded,
        title: l10n?.firstRunNetworkTitle ?? 'Same Wi-Fi',
        body: l10n?.firstRunNetworkBody ??
            'Your phone and PC must be on the same local network. Tap "Scan LAN" for auto-discovery or enter the PC IP manually.',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(
                  l10n?.skipOnboarding ?? 'Skip',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (ctx, i) => pages[i],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index
                        ? AppColors.orange
                        : AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    if (_index >= pages.length - 1) {
                      _finish();
                      return;
                    }
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                    );
                  },
                  child: Text(
                    _index >= pages.length - 1
                        ? (l10n?.getStarted ?? 'Get started')
                        : (l10n?.next ?? 'Next'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.orangeDim,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: AppColors.orange),
          ),
          const SizedBox(height: 36),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
