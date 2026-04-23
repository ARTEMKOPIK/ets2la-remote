import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

/// Syntactic sugar around [AppLocalizations.of] so screen code reads as
/// `context.l10n?.foo ?? 'Foo'` instead of the noisier
/// `AppLocalizations.of(context)?.foo ?? 'Foo'`.
///
/// Kept nullable on purpose: the app can be launched before MaterialApp
/// finishes wiring localizations up (e.g. in an `initState` for logging)
/// and we'd rather render the English fallback than crash.
extension AppLocalizationsContext on BuildContext {
  AppLocalizations? get l10n => AppLocalizations.of(this);
}
