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

  /// No description provided for @mapStyleDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get mapStyleDark;

  /// No description provided for @mapStyleLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get mapStyleLight;

  /// No description provided for @mapStyleSatellite.
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get mapStyleSatellite;

  /// No description provided for @pluginDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'Plugin disabled — tap to enable'**
  String get pluginDisabledHint;

  /// No description provided for @portApiLabel.
  ///
  /// In en, this message translates to:
  /// **'API (REST)'**
  String get portApiLabel;

  /// No description provided for @portVizLabel.
  ///
  /// In en, this message translates to:
  /// **'Visualization (WS)'**
  String get portVizLabel;

  /// No description provided for @portNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Navigation (WS)'**
  String get portNavLabel;

  /// No description provided for @portPagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Pages (WS)'**
  String get portPagesLabel;

  /// No description provided for @profileHintHomePc.
  ///
  /// In en, this message translates to:
  /// **'Home PC'**
  String get profileHintHomePc;

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

  /// No description provided for @autopilotLabel.
  ///
  /// In en, this message translates to:
  /// **'AUTOPILOT'**
  String get autopilotLabel;

  /// No description provided for @steering.
  ///
  /// In en, this message translates to:
  /// **'Steering'**
  String get steering;

  /// No description provided for @steeringLabel.
  ///
  /// In en, this message translates to:
  /// **'STEERING'**
  String get steeringLabel;

  /// No description provided for @acc.
  ///
  /// In en, this message translates to:
  /// **'ACC'**
  String get acc;

  /// No description provided for @accLabel.
  ///
  /// In en, this message translates to:
  /// **'ACC'**
  String get accLabel;

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
  String secondsFormat(int count);

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
  /// **'To control autopilot from your phone, open port {port} on your PC (Windows Firewall). This is done once.'**
  String firewallBody(int port);

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
  /// **'Plugin disabled — tap to enable'**
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

  /// No description provided for @allowInstall.
  ///
  /// In en, this message translates to:
  /// **'Allow install'**
  String get allowInstall;

  /// No description provided for @installPermissionHint.
  ///
  /// In en, this message translates to:
  /// **'Android blocks third-party installs by default. Allow \"Install unknown apps\" for ETS2LA Remote, then tap Install again.'**
  String get installPermissionHint;

  /// No description provided for @whatsNewTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsNewTitle;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @collectingData.
  ///
  /// In en, this message translates to:
  /// **'Collecting data…'**
  String get collectingData;

  /// No description provided for @profiles.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get profiles;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileName;

  /// No description provided for @profileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get profileNameRequired;

  /// No description provided for @saveAsProfile.
  ///
  /// In en, this message translates to:
  /// **'Save as profile'**
  String get saveAsProfile;

  /// No description provided for @deleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Delete profile'**
  String get deleteProfile;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @macAddressOptional.
  ///
  /// In en, this message translates to:
  /// **'MAC address (optional)'**
  String get macAddressOptional;

  /// No description provided for @macAddressHelper.
  ///
  /// In en, this message translates to:
  /// **'Needed for Wake-on-LAN'**
  String get macAddressHelper;

  /// No description provided for @invalidMac.
  ///
  /// In en, this message translates to:
  /// **'Invalid MAC address'**
  String get invalidMac;

  /// No description provided for @wakeHost.
  ///
  /// In en, this message translates to:
  /// **'Wake host'**
  String get wakeHost;

  /// No description provided for @wolSent.
  ///
  /// In en, this message translates to:
  /// **'Wake-on-LAN packet sent'**
  String get wolSent;

  /// No description provided for @wolFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send Wake-on-LAN packet'**
  String get wolFailed;

  /// No description provided for @updateDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Update download failed'**
  String get updateDownloadFailed;

  /// No description provided for @updateInstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Install failed'**
  String get updateInstallFailed;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for updates'**
  String get updateCheckFailed;

  /// No description provided for @networkOffline.
  ///
  /// In en, this message translates to:
  /// **'You appear to be offline'**
  String get networkOffline;

  /// No description provided for @fullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get fullscreen;

  /// No description provided for @exitFullscreen.
  ///
  /// In en, this message translates to:
  /// **'Exit fullscreen'**
  String get exitFullscreen;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get darkTheme;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @zoomOut.
  ///
  /// In en, this message translates to:
  /// **'Zoom out'**
  String get zoomOut;

  /// No description provided for @resetCamera.
  ///
  /// In en, this message translates to:
  /// **'Reset camera'**
  String get resetCamera;

  /// No description provided for @mapAttributionTitle.
  ///
  /// In en, this message translates to:
  /// **'Map data'**
  String get mapAttributionTitle;

  /// No description provided for @waitingForGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for telemetry'**
  String get waitingForGameTitle;

  /// No description provided for @waitingForGameBody.
  ///
  /// In en, this message translates to:
  /// **'Launch ETS2 or ATS, then enable the Map plugin in ETS2LA to start seeing data here.'**
  String get waitingForGameBody;

  /// No description provided for @reconnectingIn.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting in {seconds}s'**
  String reconnectingIn(int seconds);

  /// No description provided for @reconnectNow.
  ///
  /// In en, this message translates to:
  /// **'Retry now'**
  String get reconnectNow;

  /// No description provided for @stageConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get stageConnecting;

  /// No description provided for @stagePinging.
  ///
  /// In en, this message translates to:
  /// **'Pinging backend…'**
  String get stagePinging;

  /// No description provided for @stageOpeningSocket.
  ///
  /// In en, this message translates to:
  /// **'Opening socket…'**
  String get stageOpeningSocket;

  /// No description provided for @stageSubscribing.
  ///
  /// In en, this message translates to:
  /// **'Subscribing to telemetry…'**
  String get stageSubscribing;

  /// No description provided for @firstRunWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to ETS2LA Remote'**
  String get firstRunWelcomeTitle;

  /// No description provided for @firstRunWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Control autopilot and see your truck\'s telemetry from your phone.'**
  String get firstRunWelcomeBody;

  /// No description provided for @firstRunLaunchTitle.
  ///
  /// In en, this message translates to:
  /// **'Launch ETS2LA on your PC'**
  String get firstRunLaunchTitle;

  /// No description provided for @firstRunLaunchBody.
  ///
  /// In en, this message translates to:
  /// **'Make sure ETS2LA is running on your computer before connecting. This app talks to its WebSocket API.'**
  String get firstRunLaunchBody;

  /// No description provided for @firstRunNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay on the same Wi-Fi'**
  String get firstRunNetworkTitle;

  /// No description provided for @firstRunNetworkBody.
  ///
  /// In en, this message translates to:
  /// **'Phone and PC need to be on the same local network. Tap \"Scan LAN\" to find your PC automatically, or enter its IP manually.'**
  String get firstRunNetworkBody;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @skipOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipOnboarding;

  /// No description provided for @whyNotFound.
  ///
  /// In en, this message translates to:
  /// **'Why isn\'t it finding my PC?'**
  String get whyNotFound;

  /// No description provided for @mdnsHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find ETS2LA on the LAN'**
  String get mdnsHelpTitle;

  /// No description provided for @mdnsHelpBody.
  ///
  /// In en, this message translates to:
  /// **'• Make sure ETS2LA is running on your PC\n• Both devices must be on the same Wi-Fi (not guest network)\n• Some routers block mDNS discovery — in that case, enter the PC\'s IP manually\n• If using a VPN, disconnect it first\n• Windows Defender may block the port — see the firewall command in Settings'**
  String get mdnsHelpBody;

  /// No description provided for @saveAsProfileQuestion.
  ///
  /// In en, this message translates to:
  /// **'Save this connection as a profile?'**
  String get saveAsProfileQuestion;

  /// No description provided for @pluginStarting.
  ///
  /// In en, this message translates to:
  /// **'Enabling plugin…'**
  String get pluginStarting;

  /// No description provided for @sparklineStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Last 60 seconds'**
  String get sparklineStatsTitle;

  /// No description provided for @sparklineAvg.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get sparklineAvg;

  /// No description provided for @sparklineMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get sparklineMax;

  /// No description provided for @sparklineMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get sparklineMin;

  /// No description provided for @accentColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get accentColorLabel;

  /// No description provided for @accentOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get accentOrange;

  /// No description provided for @accentBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get accentBlue;

  /// No description provided for @accentGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get accentGreen;

  /// No description provided for @accentPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get accentPurple;

  /// No description provided for @highContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get highContrast;

  /// No description provided for @highContrastHint.
  ///
  /// In en, this message translates to:
  /// **'Stronger borders for better visibility'**
  String get highContrastHint;

  /// No description provided for @reduceMotion.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get reduceMotion;

  /// No description provided for @reduceMotionHint.
  ///
  /// In en, this message translates to:
  /// **'Disable transitions and haptics'**
  String get reduceMotionHint;

  /// No description provided for @accessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibility;

  /// No description provided for @pingLabel.
  ///
  /// In en, this message translates to:
  /// **'Ping'**
  String get pingLabel;

  /// No description provided for @disconnectHint.
  ///
  /// In en, this message translates to:
  /// **'Long-press the host to disconnect'**
  String get disconnectHint;

  /// No description provided for @holdToDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Hold to disconnect'**
  String get holdToDisconnect;

  /// No description provided for @mapTileDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get mapTileDark;

  /// No description provided for @mapTileLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get mapTileLight;

  /// No description provided for @mapTileSatellite.
  ///
  /// In en, this message translates to:
  /// **'Satellite'**
  String get mapTileSatellite;

  /// No description provided for @tripLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Trip log'**
  String get tripLogTitle;

  /// No description provided for @tripLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No trips yet. Drive for a minute with ETS2LA connected and they\'ll show up here.'**
  String get tripLogEmpty;

  /// No description provided for @tripLogTotalsTitle.
  ///
  /// In en, this message translates to:
  /// **'All-time totals'**
  String get tripLogTotalsTitle;

  /// No description provided for @tripLogClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear trip history?'**
  String get tripLogClearTitle;

  /// No description provided for @tripLogClearBody.
  ///
  /// In en, this message translates to:
  /// **'This removes all saved trips from this device. The action cannot be undone.'**
  String get tripLogClearBody;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @drivingTime.
  ///
  /// In en, this message translates to:
  /// **'Driving time'**
  String get drivingTime;

  /// No description provided for @avgSpeed.
  ///
  /// In en, this message translates to:
  /// **'Avg'**
  String get avgSpeed;

  /// No description provided for @maxSpeed.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get maxSpeed;

  /// No description provided for @autopilotShare.
  ///
  /// In en, this message translates to:
  /// **'Autopilot'**
  String get autopilotShare;

  /// Number of times autopilot was disengaged during a trip
  ///
  /// In en, this message translates to:
  /// **'{count} disengagements'**
  String disengagements(int count);

  /// No description provided for @driverMode.
  ///
  /// In en, this message translates to:
  /// **'Driver mode'**
  String get driverMode;

  /// No description provided for @driverModeHint.
  ///
  /// In en, this message translates to:
  /// **'Big-text dashboard for the phone in a mount'**
  String get driverModeHint;

  /// No description provided for @driverModeAutoLandscape.
  ///
  /// In en, this message translates to:
  /// **'Auto-enter on landscape'**
  String get driverModeAutoLandscape;

  /// No description provided for @enterDriverMode.
  ///
  /// In en, this message translates to:
  /// **'Enter driver mode'**
  String get enterDriverMode;

  /// No description provided for @exitDriverMode.
  ///
  /// In en, this message translates to:
  /// **'Exit driver mode'**
  String get exitDriverMode;

  /// No description provided for @favourite.
  ///
  /// In en, this message translates to:
  /// **'Favourite'**
  String get favourite;

  /// No description provided for @pinFavourite.
  ///
  /// In en, this message translates to:
  /// **'Pin as default'**
  String get pinFavourite;

  /// No description provided for @unpinFavourite.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpinFavourite;

  /// No description provided for @shareProfile.
  ///
  /// In en, this message translates to:
  /// **'Share profile'**
  String get shareProfile;

  /// No description provided for @scanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get scanQr;

  /// No description provided for @scanQrHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a profile QR code'**
  String get scanQrHint;

  /// No description provided for @profileImported.
  ///
  /// In en, this message translates to:
  /// **'Profile imported'**
  String get profileImported;

  /// No description provided for @profileImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the QR code'**
  String get profileImportFailed;

  /// No description provided for @connectionDoctor.
  ///
  /// In en, this message translates to:
  /// **'Connection doctor'**
  String get connectionDoctor;

  /// No description provided for @connectionDoctorHint.
  ///
  /// In en, this message translates to:
  /// **'Probes every port and shows which one is blocked'**
  String get connectionDoctorHint;

  /// No description provided for @runDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Run diagnostics'**
  String get runDiagnostics;

  /// No description provided for @doctorPingingApi.
  ///
  /// In en, this message translates to:
  /// **'Pinging API (port {port})…'**
  String doctorPingingApi(int port);

  /// No description provided for @doctorOpeningViz.
  ///
  /// In en, this message translates to:
  /// **'Opening visualization WS (port {port})…'**
  String doctorOpeningViz(int port);

  /// No description provided for @doctorOpeningNav.
  ///
  /// In en, this message translates to:
  /// **'Opening navigation WS (port {port})…'**
  String doctorOpeningNav(int port);

  /// No description provided for @doctorOpeningPages.
  ///
  /// In en, this message translates to:
  /// **'Opening pages WS (port {port})…'**
  String doctorOpeningPages(int port);

  /// No description provided for @doctorReachable.
  ///
  /// In en, this message translates to:
  /// **'Reachable'**
  String get doctorReachable;

  /// No description provided for @doctorBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get doctorBlocked;

  /// No description provided for @copyFirewallCommand.
  ///
  /// In en, this message translates to:
  /// **'Copy Windows firewall command'**
  String get copyFirewallCommand;

  /// No description provided for @firewallCommandCopied.
  ///
  /// In en, this message translates to:
  /// **'Firewall command copied'**
  String get firewallCommandCopied;

  /// No description provided for @customizeDashboard.
  ///
  /// In en, this message translates to:
  /// **'Customize dashboard'**
  String get customizeDashboard;

  /// No description provided for @customizeDashboardHint.
  ///
  /// In en, this message translates to:
  /// **'Pick and reorder the cards you want to see'**
  String get customizeDashboardHint;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get resetToDefault;

  /// No description provided for @hapticEventsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Telemetry vibrations'**
  String get hapticEventsEnabled;

  /// No description provided for @hapticEventsHint.
  ///
  /// In en, this message translates to:
  /// **'Distinct patterns for autopilot / ACC / over-limit events'**
  String get hapticEventsHint;

  /// No description provided for @ttsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Voice cues'**
  String get ttsEnabled;

  /// No description provided for @ttsEnabledHint.
  ///
  /// In en, this message translates to:
  /// **'Short spoken announcements on autopilot events'**
  String get ttsEnabledHint;

  /// No description provided for @tripLogEnabled.
  ///
  /// In en, this message translates to:
  /// **'Record trip log'**
  String get tripLogEnabled;

  /// No description provided for @tripLogEnabledHint.
  ///
  /// In en, this message translates to:
  /// **'Save distance, duration, autopilot share per session'**
  String get tripLogEnabledHint;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @tripLog.
  ///
  /// In en, this message translates to:
  /// **'Trip log'**
  String get tripLog;
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
