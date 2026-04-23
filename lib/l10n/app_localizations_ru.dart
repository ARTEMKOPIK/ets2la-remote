import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'ETS2LA Remote';

  @override
  String get recent => 'Недавние';

  @override
  String get pedals => 'ПЕДАЛИ';

  @override
  String get steeringTheTruck => 'Управление автомобилем';

  @override
  String get manualControl => 'Ручное управление';

  @override
  String get adaptiveCruiseControl => 'Адаптивный круиз-контроль';

  @override
  String get autopilotOn => 'Автопилот ВКЛ';

  @override
  String get autopilotOff => 'Автопилот ВЫКЛ';

  @override
  String get accOn => 'Круиз ВКЛ';

  @override
  String get accOff => 'Круиз ВЫКЛ';

  @override
  String get connectedTo => 'Подключено к';

  @override
  String get vpnWarning => 'Внимание: VPN может блокировать подключение';

  @override
  String get dashboard => 'Панель';

  @override
  String get map => 'Карта';

  @override
  String get settings => 'Настройки';

  @override
  String get connect => 'Подключение';

  @override
  String get connectToServer => 'Подключиться';

  @override
  String get enterIp => 'Введите IP адрес';

  @override
  String get autoConnect => 'Автоподключение';

  @override
  String get connected => 'Подключено';

  @override
  String get disconnected => 'Отключено';

  @override
  String get connecting => 'Подключение...';

  @override
  String get autopilot => 'Автопилот';

  @override
  String get steering => 'Руль';

  @override
  String get acc => 'Круиз';

  @override
  String get speed => 'Скорость';

  @override
  String get limit => 'Лимит';

  @override
  String get gas => 'ГАЗ';

  @override
  String get brake => 'ТОРМОЗ';

  @override
  String get indicators => 'Поворотники';

  @override
  String get plugins => 'Плагины';

  @override
  String get enable => 'Включить';

  @override
  String get disable => 'Выключить';

  @override
  String get enabled => 'Включено';

  @override
  String get disabled => 'Выключено';

  @override
  String get noPlugins => 'Плагины не найдены';

  @override
  String get version => 'Версия';

  @override
  String get about => 'О приложении';

  @override
  String get disconnect => 'Отключить';

  @override
  String get cancel => 'Отмена';

  @override
  String get ok => 'OK';

  @override
  String get error => 'Ошибка';

  @override
  String get retry => 'Повторить';

  @override
  String get cannotReachServer => 'Не удается подключиться';

  @override
  String get makeSureRunning => 'Убедитесь что ETS2LA запущен';

  @override
  String get connectionFailed => 'Ошибка подключения';

  @override
  String get language => 'Язык';

  @override
  String get units => 'Единицы';

  @override
  String get kmh => 'км/ч';

  @override
  String get mph => 'миль/ч';

  @override
  String get gaugeMax => 'Макс. спидометр';

  @override
  String get darkMode => 'Тёмная тема';

  @override
  String get autoFollow => 'Автоследование карты';

  @override
  String get firewallHint => 'Однократная настройка ПК';

  @override
  String get firewallCmd => 'Выполните на ПК:';

  @override
  String get copied => 'Скопировано';

  @override
  String get view3d => '3D Вид';

  @override
  String get updateAvailable => 'Доступно обновление';

  @override
  String get updateNow => 'Обновить сейчас';

  @override
  String get updateLater => 'Напомнить позже';

  @override
  String get installUpdate => 'Установить';

  @override
  String get whatsNew => 'Что нового:';

  @override
  String get downloading => 'Скачивание';

  @override
  String get downloaded => 'Скачано!';

  @override
  String get running => 'Работает';

  @override
  String get stopped => 'Остановлен';

  @override
  String get autoConnectOnLaunch => 'Автоподключение при запуске';

  @override
  String get reconnectToLastIp => 'Подключаться к последнему IP автоматически';

  @override
  String get connectionTimeout => 'Таймаут подключения';

  @override
  String secondsFormat(Object count) {
    return '$count секунд';
  }

  @override
  String get portsAdvanced => 'Порты (для разработчиков)';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get speedUnits => 'Единицы скорости';

  @override
  String get speedometerMax => 'Макс. спидометра';

  @override
  String get showActivePlugins => 'Активные плагины';

  @override
  String get pluginChipsOnDashboard => 'Показывать плагины на панели';

  @override
  String get autoFollowTruck => 'Следить за грузовиком';

  @override
  String get keepTruckCentered => 'Держать грузовик в центре карты';

  @override
  String get showRoute => 'Показать маршрут';

  @override
  String get displayNavRoute => 'Маршрут навигации на карте';

  @override
  String get mapStyle => 'Стиль карты';

  @override
  String get darkThemeByDefault => 'Тёмная тема по умолчанию';

  @override
  String get unityVizTheme => 'Тема визуализации Unity';

  @override
  String get autoConnectOnOpen => 'Автоподключение при открытии';

  @override
  String get connectWhenTabOpens => 'Подключаться при открытии вкладки';

  @override
  String get connection => 'Подключение';

  @override
  String get firewallTitle => 'Однократная настройка ПК';

  @override
  String get firewallBody => 'Чтобы управлять автопилотом с телефона, откройте порт 37523 на ПК (Брандмауэр Windows). Делается один раз.';

  @override
  String get runInPowerShell => 'Выполните в PowerShell (Админ):';

  @override
  String get togglePluginsHint => 'Управляйте плагинами, загруженными в ETS2LA';

  @override
  String get firstLaunchHint => 'Первый запуск ~5 секунд';

  @override
  String get reconnecting => 'Переподключение...';

  @override
  String get invalidIp => 'Введите корректный IPv4 адрес';

  @override
  String get checkForUpdates => 'Проверить обновления';

  @override
  String get noUpdates => 'У вас актуальная версия';

  @override
  String updatingFile(String file) {
    return 'Обновление $file...';
  }

  @override
  String get startingLocalServer => 'Запуск локального сервера...';

  @override
  String get preparingUnity => 'Подготовка Unity...';

  @override
  String get autoFollowTooltip => 'Автоследование';

  @override
  String get noPositionData => 'Нет данных позиции';

  @override
  String get enableNavigationPlugin => 'Включите плагин NavigationSockets';

  @override
  String get game => 'ИГРА';

  @override
  String get notConnected => 'Нет соединения';

  @override
  String get copy => 'Копировать';

  @override
  String get languageSystem => 'Системный';

  @override
  String get ets2laOnGithub => 'ETS2LA на GitHub';

  @override
  String get removeFromRecent => 'Удалить';

  @override
  String get loadingPlugins => 'Загрузка плагинов…';

  @override
  String get refresh => 'Обновить';

  @override
  String get dismiss => 'Скрыть';

  @override
  String get portsAdvancedHint => 'Меняйте, только если ETS2LA использует нестандартные порты';

  @override
  String get hostnameOrIp => 'IP или имя хоста';

  @override
  String get invalidHost => 'Введите корректный IP адрес или имя хоста';

  @override
  String get pluginEnabled => 'Плагин включён';

  @override
  String get pluginDisabled => 'Плагин выключен';

  @override
  String get pluginToggleFailed => 'Не удалось переключить плагин';
}
