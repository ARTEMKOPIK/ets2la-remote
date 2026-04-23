import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ETS2LA Remote'**
  String get appTitle;

  /// No description provided for @recent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// No description provided for @pedals.
  ///
  /// In en, this message translates to:
  /// **'PEDALS'**
  String get pedals;

  /// No description provided for @steeringTheTruck.
  ///
  /// In en, this message translates to:
  /// **'Steering the truck'**
  String get steeringTheTruck;

  /// No description provided for @manualControl.
  ///
  /// In en, this message translates to:
  /// **'Manual control'**
  String get manualControl;

  /// No description provided for @adaptiveCruiseControl.
  ///
  /// In en, this message translates to:
  /// **'Adaptive Cruise Control'**
  String get adaptiveCruiseControl;

  /// No description provided for @autopilotOn.
  ///
  /// In en, this message translates to:
  /// **'Autopilot ON'**
  String get autopilotOn;

  /// No description provided for @autopilotOff.
  ///
  /// In en, this message translates to:
  /// **'Autopilot OFF'**
  String get autopilotOff;

  /// No description provided for @accOn.
  ///
  /// In en, this message translates to:
  /// **'ACC ON'**
  String get accOn;

  /// No description provided for @accOff.
  ///
  /// In en, this message translates to:
  /// **'ACC OFF'**
  String get accOff;

  /// No description provided for @connectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected to'**
  String get connectedTo;

  /// No description provided for @vpnWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: VPN may prevent connection'**
  String get vpnWarning;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @connectToServer.
  ///
  /// In en, this message translates to:
  /// **'Connect to Server'**
  String get connectToServer;

  /// No description provided for @enterIp.
  ///
  /// In en, this message translates to:
  /// **'Enter IP address'**
  String get enterIp;

  /// No description provided for @autoConnect.
  ///
  /// In en, this message translates to:
  /// **'Auto-connect'**
  String get autoConnect;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get disconnected;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get connecting;

  /// No description provided for @autopilot.
  ///
  /// In en, this message translates to:
  /// **'Autopilot'**
  String get autopilot;

  /// No description provided for @steering.
  ///
  /// In en, this message translates to:
  /// **'Steering'**
  String get steering;

  /// No description provided for @acc.
  ///
  /// In en, this message translates to:
  /// **'ACC'**
  String get acc;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @limit.
  ///
  /// In en, this message translates to:
  /// **'Limit'**
  String get limit;

  /// No description provided for @gas.
  ///
  /// In en, this message translates to:
  /// **'GAS'**
  String get gas;

  /// No description provided for @brake.
  ///
  /// In en, this message translates to:
  /// **'BRAKE'**
  String get brake;

  /// No description provided for @indicators.
  ///
  /// In en, this message translates to:
  /// **'Indicators'**
  String get indicators;

  /// No description provided for @plugins.
  ///
  /// In en, this message translates to:
  /// **'Plugins'**
  String get plugins;

  /// No description provided for @enable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get enable;

  /// No description provided for @disable.
  ///
  /// In en, this message translates to:
  /// **'Disable'**
  String get disable;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @noPlugins.
  ///
  /// In en, this message translates to:
  /// **'No plugins found'**
  String get noPlugins;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cannotReachServer.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach server'**
  String get cannotReachServer;

  /// No description provided for @makeSureRunning.
  ///
  /// In en, this message translates to:
  /// **'Make sure ETS2LA is running'**
  String get makeSureRunning;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get units;

  /// No description provided for @kmh.
  ///
  /// In en, this message translates to:
  /// **'km/h'**
  String get kmh;

  /// No description provided for @mph.
  ///
  /// In en, this message translates to:
  /// **'mph'**
  String get mph;

  /// No description provided for @gaugeMax.
  ///
  /// In en, this message translates to:
  /// **'Gauge max'**
  String get gaugeMax;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @autoFollow.
  ///
  /// In en, this message translates to:
  /// **'Auto-follow map'**
  String get autoFollow;

  /// No description provided for @firewallHint.
  ///
  /// In en, this message translates to:
  /// **'One-time PC setup'**
  String get firewallHint;

  /// No description provided for @firewallCmd.
  ///
  /// In en, this message translates to:
  /// **'Run this on PC:'**
  String get firewallCmd;

  /// No description provided for @view3d.
  ///
  /// In en, this message translates to:
  /// **'3D View'**
  String get view3d;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update Available'**
  String get updateAvailable;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @updateLater.
  ///
  /// In en, this message translates to:
  /// **'Remind Me Later'**
  String get updateLater;

  /// No description provided for @installUpdate.
  ///
  /// In en, this message translates to:
  /// **'Install Update'**
  String get installUpdate;

  /// No description provided for @whatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new:'**
  String get whatsNew;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @downloaded.
  ///
  /// In en, this message translates to:
  /// **'Downloaded!'**
  String get downloaded;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// No description provided for @stopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get stopped;

  /// No description provided for @autoConnectOnLaunch.
  ///
  /// In en, this message translates to:
  /// **'Auto-connect on launch'**
  String get autoConnectOnLaunch;

  /// No description provided for @reconnectToLastIp.
  ///
  /// In en, this message translates to:
  /// **'Reconnect to last IP automatically'**
  String get reconnectToLastIp;

  /// No description provided for @connectionTimeout.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout'**
  String get connectionTimeout;

  /// No description provided for @secondsFormat.
  ///
  /// In en, this message translates to:
  /// **'{count} seconds'**
  String secondsFormat(Object count);

  /// No description provided for @portsAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Ports (Advanced)'**
  String get portsAdvanced;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @speedUnits.
  ///
  /// In en, this message translates to:
  /// **'Speed units'**
  String get speedUnits;

  /// No description provided for @speedometerMax.
  ///
  /// In en, this message translates to:
  /// **'Speedometer max'**
  String get speedometerMax;

  /// No description provided for @showActivePlugins.
  ///
  /// In en, this message translates to:
  /// **'Show Active Plugins'**
  String get showActivePlugins;

  /// No description provided for @pluginChipsOnDashboard.
  ///
  /// In en, this message translates to:
  /// **'Plugin chips on Dashboard'**
  String get pluginChipsOnDashboard;

  /// No description provided for @autoFollowTruck.
  ///
  /// In en, this message translates to:
  /// **'Auto-follow truck'**
  String get autoFollowTruck;

  /// No description provided for @keepTruckCentered.
  ///
  /// In en, this message translates to:
  /// **'Keep truck centered by default'**
  String get keepTruckCentered;

  /// No description provided for @showRoute.
  ///
  /// In en, this message translates to:
  /// **'Show route'**
  String get showRoute;

  /// No description provided for @displayNavRoute.
  ///
  /// In en, this message translates to:
  /// **'Display navigation route on map'**
  String get displayNavRoute;

  /// No description provided for @mapStyle.
  ///
  /// In en, this message translates to:
  /// **'Map style'**
  String get mapStyle;

  /// No description provided for @darkThemeByDefault.
  ///
  /// In en, this message translates to:
  /// **'Dark theme by default'**
  String get darkThemeByDefault;

  /// No description provided for @unityVizTheme.
  ///
  /// In en, this message translates to:
  /// **'Unity visualization theme'**
  String get unityVizTheme;

  /// No description provided for @autoConnectOnOpen.
  ///
  /// In en, this message translates to:
  /// **'Auto-connect on open'**
  String get autoConnectOnOpen;

  /// No description provided for @connectWhenTabOpens.
  ///
  /// In en, this message translates to:
  /// **'Connect to ETS2LA when tab opens'**
  String get connectWhenTabOpens;

  /// No description provided for @connection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connection;

  /// No description provided for @firewallTitle.
  ///
  /// In en, this message translates to:
  /// **'One-time PC setup'**
  String get firewallTitle;

  /// No description provided for @firewallBody.
  ///
  /// In en, this message translates to:
  /// **'To control autopilot from your phone, open port 37523 on your PC (Windows Firewall). This is done once.'**
  String get firewallBody;

  /// No description provided for @runInPowerShell.
  ///
  /// In en, this message translates to:
  /// **'Run in PowerShell (Admin):'**
  String get runInPowerShell;

  /// No description provided for @togglePluginsHint.
  ///
  /// In en, this message translates to:
  /// **'Toggle plugins that are already loaded in ETS2LA'**
  String get togglePluginsHint;

  /// No description provided for @firstLaunchHint.
  ///
  /// In en, this message translates to:
  /// **'First launch only ~5s'**
  String get firstLaunchHint;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting...'**
  String get reconnecting;

  /// No description provided for @invalidIp.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid IPv4 address'**
  String get invalidIp;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @noUpdates.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date'**
  String get noUpdates;

  /// No description provided for @updatingFile.
  ///
  /// In en, this message translates to:
  /// **'Updating {file}...'**
  String updatingFile(String file);

  /// No description provided for @startingLocalServer.
  ///
  /// In en, this message translates to:
  /// **'Starting local server...'**
  String get startingLocalServer;

  /// No description provided for @preparingUnity.
  ///
  /// In en, this message translates to:
  /// **'Preparing Unity...'**
  String get preparingUnity;

  /// No description provided for @autoFollowTooltip.
  ///
  /// In en, this message translates to:
  /// **'Auto-follow'**
  String get autoFollowTooltip;

  /// No description provided for @noPositionData.
  ///
  /// In en, this message translates to:
  /// **'No position data'**
  String get noPositionData;

  /// No description provided for @enableNavigationPlugin.
  ///
  /// In en, this message translates to:
  /// **'Enable NavigationSockets plugin'**
  String get enableNavigationPlugin;

  /// No description provided for @game.
  ///
  /// In en, this message translates to:
  /// **'GAME'**
  String get game;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @hostnameOrIp.
  ///
  /// In en, this message translates to:
  /// **'IP or hostname'**
  String get hostnameOrIp;

  /// No description provided for @invalidHost.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid IP address or hostname'**
  String get invalidHost;

  /// No description provided for @pluginEnabled.
  ///
  /// In en, this message translates to:
  /// **'Plugin enabled'**
  String get pluginEnabled;

  /// No description provided for @pluginDisabled.
  ///
  /// In en, this message translates to:
  /// **'Plugin disabled'**
  String get pluginDisabled;

  /// No description provided for @pluginToggleFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to toggle plugin'**
  String get pluginToggleFailed;

  /// No description provided for @ets2laOnGithub.
  ///
  /// In en, this message translates to:
  /// **'ETS2LA on GitHub'**
  String get ets2laOnGithub;

  /// No description provided for @removeFromRecent.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeFromRecent;

  /// No description provided for @loadingPlugins.
  ///
  /// In en, this message translates to:
  /// **'Loading plugins…'**
  String get loadingPlugins;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @portsAdvancedHint.
  ///
  /// In en, this message translates to:
  /// **'Only change if ETS2LA uses non-default ports'**
  String get portsAdvancedHint;

  /// No description provided for @findEts2la.
  ///
  /// In en, this message translates to:
  /// **'Find ETS2LA on LAN'**
  String get findEts2la;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning…'**
  String get scanning;

  /// No description provided for @noHostsFound.
  ///
  /// In en, this message translates to:
  /// **'No ETS2LA found on LAN'**
  String get noHostsFound;

  /// No description provided for @foundOnLan.
  ///
  /// In en, this message translates to:
  /// **'Found on LAN'**
  String get foundOnLan;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @scanFinishedNoHosts.
  ///
  /// In en, this message translates to:
  /// **'No ETS2LA found. Check it\'s running and on the same Wi-Fi.'**
  String get scanFinishedNoHosts;

  /// No description provided for @connectFailedHint.
  ///
  /// In en, this message translates to:
  /// **'ETS2LA didn\'t answer. Opening the socket anyway…'**
  String get connectFailedHint;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ru': return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
