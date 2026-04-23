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
  String get ok => 'ОК';

  @override
  String get mapStyleDark => 'Тёмная';

  @override
  String get mapStyleLight => 'Светлая';

  @override
  String get mapStyleSatellite => 'Спутник';

  @override
  String get pluginDisabledHint => 'Плагин выключен — нажмите, чтобы включить';

  @override
  String get portApiLabel => 'API (REST)';

  @override
  String get portVizLabel => 'Визуализация (WS)';

  @override
  String get portNavLabel => 'Навигация (WS)';

  @override
  String get portPagesLabel => 'Страницы (WS)';

  @override
  String get profileHintHomePc => 'Домашний ПК';

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
  String firewallBody(int port) {
    return 'Чтобы управлять автопилотом с телефона, откройте порт $port на ПК (Брандмауэр Windows). Делается один раз.';
  }

  @override
  String get autopilotLabel => 'АВТОПИЛОТ';

  @override
  String get steeringLabel => 'РУЛЬ';

  @override
  String get accLabel => 'КРУИЗ';

  @override
  String get updateDownloadFailed => 'Не удалось скачать обновление';

  @override
  String get updateInstallFailed => 'Ошибка установки';

  @override
  String get updateCheckFailed => 'Не удалось проверить обновления';

  @override
  String get networkOffline => 'Нет подключения к интернету';

  @override
  String get fullscreen => 'Во весь экран';

  @override
  String get exitFullscreen => 'Выйти из полного экрана';

  @override
  String get lightTheme => 'Светлая тема';

  @override
  String get darkTheme => 'Тёмная тема';

  @override
  String get zoomIn => 'Приблизить';

  @override
  String get zoomOut => 'Отдалить';

  @override
  String get resetCamera => 'Сбросить камеру';

  @override
  String get mapAttributionTitle => 'Источники карты';

  @override
  String get waitingForGameTitle => 'Ждём телеметрию';

  @override
  String get waitingForGameBody =>
      'Запусти ETS2 или ATS и включи плагин Map в ETS2LA — данные появятся здесь.';

  @override
  String reconnectingIn(int seconds) => 'Переподключение через ${seconds} с';

  @override
  String get reconnectNow => 'Повторить';

  @override
  String get stageConnecting => 'Подключение…';

  @override
  String get stagePinging => 'Проверка сервера…';

  @override
  String get stageOpeningSocket => 'Открываем сокет…';

  @override
  String get stageSubscribing => 'Подписка на телеметрию…';

  @override
  String get firstRunWelcomeTitle => 'Добро пожаловать в ETS2LA Remote';

  @override
  String get firstRunWelcomeBody =>
      'Управляй автопилотом и смотри телеметрию грузовика прямо с телефона.';

  @override
  String get firstRunLaunchTitle => 'Запусти ETS2LA на ПК';

  @override
  String get firstRunLaunchBody =>
      'Перед подключением убедись, что ETS2LA запущен на компьютере. Приложение общается с его WebSocket-API.';

  @override
  String get firstRunNetworkTitle => 'Одна Wi-Fi сеть';

  @override
  String get firstRunNetworkBody =>
      'Телефон и ПК должны быть в одной локальной сети. Нажми «Найти в сети» для автопоиска или введи IP вручную.';

  @override
  String get getStarted => 'Начать';

  @override
  String get next => 'Далее';

  @override
  String get skipOnboarding => 'Пропустить';

  @override
  String get whyNotFound => 'Почему не находит ПК?';

  @override
  String get mdnsHelpTitle => 'ETS2LA не виден в сети';

  @override
  String get mdnsHelpBody =>
      '• Проверь, что ETS2LA запущен на ПК\n'
      '• Оба устройства должны быть в одной Wi-Fi (не гостевой)\n'
      '• Некоторые роутеры блокируют mDNS — в этом случае введи IP ПК вручную\n'
      '• Если используешь VPN — выключи его\n'
      '• Windows Defender может блокировать порт — см. команду для фаервола в настройках';

  @override
  String get saveAsProfileQuestion => 'Сохранить это подключение как профиль?';

  @override
  String get pluginDisabled => 'Плагин выключен — нажми, чтобы включить';

  @override
  String get pluginStarting => 'Включаем плагин…';

  @override
  String get sparklineStatsTitle => 'Последние 60 секунд';

  @override
  String get sparklineAvg => 'Сред';

  @override
  String get sparklineMax => 'Макс';

  @override
  String get sparklineMin => 'Мин';

  @override
  String get accentColorLabel => 'Акцентный цвет';

  @override
  String get accentOrange => 'Оранжевый';

  @override
  String get accentBlue => 'Синий';

  @override
  String get accentGreen => 'Зелёный';

  @override
  String get accentPurple => 'Фиолетовый';

  @override
  String get highContrast => 'Высокий контраст';

  @override
  String get highContrastHint => 'Более чёткие границы элементов';

  @override
  String get reduceMotion => 'Меньше анимации';

  @override
  String get reduceMotionHint => 'Отключить переходы и вибрацию';

  @override
  String get accessibility => 'Доступность';

  @override
  String get pingLabel => 'Пинг';

  @override
  String get disconnectHint => 'Удерживай имя хоста, чтобы отключиться';

  @override
  String get holdToDisconnect => 'Удерживай для отключения';

  @override
  String get mapTileDark => 'Тёмная';

  @override
  String get mapTileLight => 'Светлая';

  @override
  String get mapTileSatellite => 'Спутник';

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
  String get copied => 'Скопировано';

  @override
  String get languageSystem => 'Системный';

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
  String get findEts2la => 'Найти ETS2LA в сети';

  @override
  String get scanning => 'Поиск…';

  @override
  String get noHostsFound => 'ETS2LA не найден в сети';

  @override
  String get foundOnLan => 'Найдено в сети';

  @override
  String get change => 'Изменить';

  @override
  String get scanFinishedNoHosts => 'ETS2LA не найден. Проверьте, запущен ли он и вы в одной сети.';

  @override
  String get connectFailedHint => 'ETS2LA не ответил. Пробуем подключиться напрямую…';

  @override
  String get allowInstall => 'Разрешить установку';

  @override
  String get installPermissionHint => 'Android по умолчанию блокирует установку из сторонних источников. Включите «Установка неизвестных приложений» для ETS2LA Remote и снова нажмите «Установить».';

  @override
  String get whatsNewTitle => 'Что нового';

  @override
  String get gotIt => 'Понятно';

  @override
  String get collectingData => 'Сбор данных…';

  @override
  String get profiles => 'Профили';

  @override
  String get profileName => 'Название';

  @override
  String get profileNameRequired => 'Введите название';

  @override
  String get saveAsProfile => 'Сохранить как профиль';

  @override
  String get deleteProfile => 'Удалить профиль';

  @override
  String get edit => 'Изменить';

  @override
  String get save => 'Сохранить';

  @override
  String get macAddressOptional => 'MAC-адрес (необязательно)';

  @override
  String get macAddressHelper => 'Нужен для Wake-on-LAN';

  @override
  String get invalidMac => 'Неверный MAC-адрес';

  @override
  String get wakeHost => 'Разбудить ПК';

  @override
  String get wolSent => 'Пакет Wake-on-LAN отправлен';

  @override
  String get wolFailed => 'Не удалось отправить пакет Wake-on-LAN';
}
