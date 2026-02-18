import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:indulge/provider/theme_provider.dart';

void main() {
  group('ThemeProvider', () {
    group('initialization', () {
      test('starts with system theme mode by default', () {
        final themeProvider = ThemeProvider();
        expect(themeProvider.themeMode, equals(ThemeMode.system));
        expect(themeProvider.isSystemMode, isTrue);
        expect(themeProvider.isDarkMode, isFalse);
        expect(themeProvider.isLightMode, isFalse);
        expect(themeProvider.isInitialized, isFalse);
      });

      test('initialize loads saved dark theme', () async {
        SharedPreferences.setMockInitialValues({
          'theme_mode': 'ThemeMode.dark',
        });
        await SharedPreferences.getInstance();
        final themeProvider = ThemeProvider();
        await themeProvider.initialize();
        expect(themeProvider.themeMode, equals(ThemeMode.dark));
        expect(themeProvider.isInitialized, isTrue);
      });

      test('initialize defaults to system when no saved preference', () async {
        SharedPreferences.setMockInitialValues({});
        await SharedPreferences.getInstance();
        final themeProvider = ThemeProvider();
        await themeProvider.initialize();
        expect(themeProvider.themeMode, equals(ThemeMode.system));
        expect(themeProvider.isInitialized, isTrue);
      });
    });

    group('setThemeMode', () {
      test('updates theme mode to dark', () async {
        SharedPreferences.setMockInitialValues({});
        await SharedPreferences.getInstance();
        final themeProvider = ThemeProvider();
        await themeProvider.initialize();
        await themeProvider.setThemeMode(ThemeMode.dark);
        expect(themeProvider.themeMode, equals(ThemeMode.dark));
        expect(themeProvider.isDarkMode, isTrue);
      });

      test('notifies listeners when theme changes', () async {
        SharedPreferences.setMockInitialValues({});
        await SharedPreferences.getInstance();
        final themeProvider = ThemeProvider();
        await themeProvider.initialize();
        var notified = false;
        themeProvider.addListener(() => notified = true);
        await themeProvider.setThemeMode(ThemeMode.dark);
        expect(notified, isTrue);
      });
    });

    group('toggleTheme', () {
      test('toggles from dark to light', () async {
        SharedPreferences.setMockInitialValues({
          'theme_mode': 'ThemeMode.dark',
        });
        await SharedPreferences.getInstance();
        final themeProvider = ThemeProvider();
        await themeProvider.initialize();
        await themeProvider.toggleTheme();
        expect(themeProvider.themeMode, equals(ThemeMode.light));
      });
    });

    group('convenience methods', () {
      test('useDarkTheme sets dark mode', () async {
        SharedPreferences.setMockInitialValues({});
        await SharedPreferences.getInstance();
        final themeProvider = ThemeProvider();
        await themeProvider.initialize();
        await themeProvider.useDarkTheme();
        expect(themeProvider.themeMode, equals(ThemeMode.dark));
      });
    });
  });
}
