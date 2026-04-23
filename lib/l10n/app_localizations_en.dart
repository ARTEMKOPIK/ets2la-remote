import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ETS2LA Remote';

  @override
  String get recent => 'Recent';

  @override
  String get pedals => 'PEDALS';

  @override
  String get steeringTheTruck => 'Steering the truck';

  @override
  String get manualControl => 'Manual control';

  @override
  String get adaptiveCruiseControl => 'Adaptive Cruise Control';

  @override
  String get autopilotOn => 'Autopilot ON';

  @override
  String get autopilotOff => 'Autopilot OFF';

  @override
  String get accOn => 'ACC ON';

  @override
  String get accOff => 'ACC OFF';

  @override
  String get connectedTo => 'Connected to';

  @override
  String get vpnWarning => 'Warning: VPN may prevent connection';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get map => 'Map';

  @override
  String get settings => 'Settings';

  @override
  String get connect => 'Connect';

  @override
  String get connectToServer => 'Connect to Server';

  @override
  String get enterIp => 'Enter IP address';

  @override
  String get autoConnect => 'Auto-connect';

  @override
  String get connected => 'Connected';

  @override
  String get disconnected => 'Disconnected';

  @override
  String get connecting => 'Connecting...';

  @override
  String get autopilot => 'Autopilot';

  @override
  String get steering => 'Steering';

  @override
  String get acc => 'ACC';

  @override
  String get speed => 'Speed';

  @override
  String get limit => 'Limit';

  @override
  String get gas => 'GAS';

  @override
  String get brake => 'BRAKE';

  @override
  String get indicators => 'Indicators';

  @override
  String get plugins => 'Plugins';

  @override
  String get enable => 'Enable';

  @override
  String get disable => 'Disable';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get noPlugins => 'No plugins found';

  @override
  String get version => 'Version';

  @override
  String get about => 'About';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get cannotReachServer => 'Cannot reach server';

  @override
  String get makeSureRunning => 'Make sure ETS2LA is running';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get language => 'Language';

  @override
  String get units => 'Units';

  @override
  String get kmh => 'km/h';

  @override
  String get mph => 'mph';

  @override
  String get gaugeMax => 'Gauge max';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get autoFollow => 'Auto-follow map';

  @override
  String get firewallHint => 'One-time PC setup';

  @override
  String get firewallCmd => 'Run this on PC:';

  @override
  String get view3d => '3D View';

  @override
  String get updateAvailable => 'Update Available';

  @override
  String get updateNow => 'Update Now';

  @override
  String get updateLater => 'Remind Me Later';

  @override
  String get installUpdate => 'Install Update';

  @override
  String get whatsNew => 'What\'s new:';

  @override
  String get downloading => 'Downloading';

  @override
  String get downloaded => 'Downloaded!';

  @override
  String get running => 'Running';

  @override
  String get stopped => 'Stopped';

  @override
  String get autoConnectOnLaunch => 'Auto-connect on launch';

  @override
  String get reconnectToLastIp => 'Reconnect to last IP automatically';

  @override
  String get connectionTimeout => 'Connection timeout';

  @override
  String secondsFormat(Object count) {
    return '$count seconds';
  }

  @override
  String get portsAdvanced => 'Ports (Advanced)';

  @override
  String get appearance => 'Appearance';

  @override
  String get speedUnits => 'Speed units';

  @override
  String get speedometerMax => 'Speedometer max';

  @override
  String get showActivePlugins => 'Show Active Plugins';

  @override
  String get pluginChipsOnDashboard => 'Plugin chips on Dashboard';

  @override
  String get autoFollowTruck => 'Auto-follow truck';

  @override
  String get keepTruckCentered => 'Keep truck centered by default';

  @override
  String get showRoute => 'Show route';

  @override
  String get displayNavRoute => 'Display navigation route on map';

  @override
  String get mapStyle => 'Map style';

  @override
  String get darkThemeByDefault => 'Dark theme by default';

  @override
  String get unityVizTheme => 'Unity visualization theme';

  @override
  String get autoConnectOnOpen => 'Auto-connect on open';

  @override
  String get connectWhenTabOpens => 'Connect to ETS2LA when tab opens';

  @override
  String get connection => 'Connection';

  @override
  String get firewallTitle => 'One-time PC setup';

  @override
  String firewallBody(int port) {
    return 'To control autopilot from your phone, open port $port on your PC (Windows Firewall). This is done once.';
  }

  @override
  String get autopilotLabel => 'AUTOPILOT';

  @override
  String get steeringLabel => 'STEERING';

  @override
  String get accLabel => 'ACC';

  @override
  String get updateDownloadFailed => 'Update download failed';

  @override
  String get updateInstallFailed => 'Install failed';

  @override
  String get updateCheckFailed => 'Couldn\'t check for updates';

  @override
  String get networkOffline => 'You appear to be offline';

  @override
  String get fullscreen => 'Fullscreen';

  @override
  String get exitFullscreen => 'Exit fullscreen';

  @override
  String get lightTheme => 'Light theme';

  @override
  String get darkTheme => 'Dark theme';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get zoomOut => 'Zoom out';

  @override
  String get resetCamera => 'Reset camera';

  @override
  String get mapAttributionTitle => 'Map data';

  @override
  String get runInPowerShell => 'Run in PowerShell (Admin):';

  @override
  String get togglePluginsHint => 'Toggle plugins that are already loaded in ETS2LA';

  @override
  String get firstLaunchHint => 'First launch only ~5s';

  @override
  String get reconnecting => 'Reconnecting...';

  @override
  String get invalidIp => 'Enter a valid IPv4 address';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get noUpdates => 'You\'re up to date';

  @override
  String updatingFile(String file) {
    return 'Updating $file...';
  }

  @override
  String get startingLocalServer => 'Starting local server...';

  @override
  String get preparingUnity => 'Preparing Unity...';

  @override
  String get autoFollowTooltip => 'Auto-follow';

  @override
  String get noPositionData => 'No position data';

  @override
  String get enableNavigationPlugin => 'Enable NavigationSockets plugin';

  @override
  String get game => 'GAME';

  @override
  String get notConnected => 'Not connected';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get languageSystem => 'System';

  @override
  String get hostnameOrIp => 'IP or hostname';

  @override
  String get invalidHost => 'Enter a valid IP address or hostname';

  @override
  String get pluginEnabled => 'Plugin enabled';

  @override
  String get pluginDisabled => 'Plugin disabled';

  @override
  String get pluginToggleFailed => 'Failed to toggle plugin';

  @override
  String get ets2laOnGithub => 'ETS2LA on GitHub';

  @override
  String get removeFromRecent => 'Remove';

  @override
  String get loadingPlugins => 'Loading plugins…';

  @override
  String get refresh => 'Refresh';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get portsAdvancedHint => 'Only change if ETS2LA uses non-default ports';

  @override
  String get findEts2la => 'Find ETS2LA on LAN';

  @override
  String get scanning => 'Scanning…';

  @override
  String get noHostsFound => 'No ETS2LA found on LAN';

  @override
  String get foundOnLan => 'Found on LAN';

  @override
  String get change => 'Change';

  @override
  String get scanFinishedNoHosts => 'No ETS2LA found. Check it\'s running and on the same Wi-Fi.';

  @override
  String get connectFailedHint => 'ETS2LA didn\'t answer. Opening the socket anyway…';

  @override
  String get allowInstall => 'Allow install';

  @override
  String get installPermissionHint => 'Android blocks third-party installs by default. Allow \"Install unknown apps\" for ETS2LA Remote, then tap Install again.';

  @override
  String get whatsNewTitle => 'What\'s new';

  @override
  String get gotIt => 'Got it';

  @override
  String get collectingData => 'Collecting data…';

  @override
  String get profiles => 'Profiles';

  @override
  String get profileName => 'Name';

  @override
  String get profileNameRequired => 'Enter a name';

  @override
  String get saveAsProfile => 'Save as profile';

  @override
  String get deleteProfile => 'Delete profile';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get macAddressOptional => 'MAC address (optional)';

  @override
  String get macAddressHelper => 'Needed for Wake-on-LAN';

  @override
  String get invalidMac => 'Invalid MAC address';

  @override
  String get wakeHost => 'Wake host';

  @override
  String get wolSent => 'Wake-on-LAN packet sent';

  @override
  String get wolFailed => 'Failed to send Wake-on-LAN packet';
}
