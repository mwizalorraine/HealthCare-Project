import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_l10n.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;

  const SettingsState({
    this.themeMode = ThemeMode.light,
    this.locale = const Locale('en'),
  });

  SettingsState copyWith({ThemeMode? themeMode, Locale? locale}) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    locale: locale ?? this.locale,
  );

  bool get isDark => themeMode == ThemeMode.dark;
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  static const _kTheme = 'rs_theme_mode';
  static const _kLocale = 'rs_locale';

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final t = p.getString(_kTheme) ?? 'light';
    final l = p.getString(_kLocale) ?? 'en';
    state = SettingsState(
      themeMode: t == 'dark' ? ThemeMode.dark : ThemeMode.light,
      locale: Locale(l),
    );
  }

  Future<void> toggleTheme() async {
    final p = await SharedPreferences.getInstance();
    final next = state.isDark ? ThemeMode.light : ThemeMode.dark;
    await p.setString(_kTheme, next == ThemeMode.dark ? 'dark' : 'light');
    state = state.copyWith(themeMode: next);
  }

  Future<void> setLocale(Locale locale) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLocale, locale.languageCode);
    state = state.copyWith(locale: locale);
  }

  String get localeName {
    switch (state.locale.languageCode) {
      case 'fr':
        return 'Français';
      case 'rw':
        return 'Kinyarwanda';
      case 'sw':
        return 'Kiswahili';
      default:
        return 'English';
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

/// Provides an AppL10n instance derived directly from the stored locale.
/// Use this instead of AppL10n.of(context) to avoid MaterialLocalizations
/// conflicts when the locale is Kinyarwanda (rw) or Swahili (sw), which are
/// not supported by GlobalMaterialLocalizations.
final appL10nProvider = Provider<AppL10n>((ref) {
  return AppL10n(ref.watch(settingsProvider).locale);
});
