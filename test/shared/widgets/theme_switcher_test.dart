import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cherry_note/shared/widgets/theme_switcher.dart';

void main() {
  group('AppThemeMode Extension', () {
    test('displayName returns correct Chinese names', () {
      expect(AppThemeMode.light.displayName, '浅色主题');
      expect(AppThemeMode.dark.displayName, '深色主题');
      expect(AppThemeMode.system.displayName, '跟随系统');
    });

    test('icon returns correct icons', () {
      expect(AppThemeMode.light.icon, Icons.light_mode);
      expect(AppThemeMode.dark.icon, Icons.dark_mode);
      expect(AppThemeMode.system.icon, Icons.brightness_auto);
    });

    test('themeMode returns correct ThemeMode', () {
      expect(AppThemeMode.light.themeMode, ThemeMode.light);
      expect(AppThemeMode.dark.themeMode, ThemeMode.dark);
      expect(AppThemeMode.system.themeMode, ThemeMode.system);
    });
  });

  group('ThemeSwitcher', () {
    testWidgets('renders current theme with label', (tester) async {
      AppThemeMode selectedTheme = AppThemeMode.light;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemeSwitcher(
              currentTheme: AppThemeMode.light,
              onThemeChanged: (theme) => selectedTheme = theme,
              showLabel: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.light_mode), findsOneWidget);
      expect(find.text('浅色主题'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('renders current theme without label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemeSwitcher(
              currentTheme: AppThemeMode.dark,
              onThemeChanged: (theme) {},
              showLabel: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
      expect(find.text('深色主题'), findsNothing);
      expect(find.byIcon(Icons.arrow_drop_down), findsNothing);
    });

    testWidgets('shows popup menu when tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemeSwitcher(
              currentTheme: AppThemeMode.light,
              onThemeChanged: (theme) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<AppThemeMode>));
      await tester.pumpAndSettle();

      expect(find.text('浅色主题'), findsNWidgets(2)); // One in button, one in menu
      expect(find.text('深色主题'), findsOneWidget);
      expect(find.text('跟随系统'), findsOneWidget);
    });

    testWidgets('calls onThemeChanged when menu item is selected', (tester) async {
      AppThemeMode? selectedTheme;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemeSwitcher(
              currentTheme: AppThemeMode.light,
              onThemeChanged: (theme) => selectedTheme = theme,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<AppThemeMode>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('深色主题'));
      await tester.pumpAndSettle();

      expect(selectedTheme, AppThemeMode.dark);
    });

    testWidgets('shows check mark for current theme in menu', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemeSwitcher(
              currentTheme: AppThemeMode.dark,
              onThemeChanged: (theme) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<AppThemeMode>));
      await tester.pumpAndSettle();

      // Check that the current theme has a check mark
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });

  group('ThemeToggleButton', () {
    testWidgets('renders light mode icon when dark mode is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemeToggleButton(
              isDarkMode: false,
              onToggle: (value) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    });

    testWidgets('renders dark mode icon when dark mode is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemeToggleButton(
              isDarkMode: true,
              onToggle: (value) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.light_mode), findsOneWidget);
    });

    testWidgets('calls onToggle with opposite value when tapped', (tester) async {
      bool? toggledValue;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemeToggleButton(
              isDarkMode: false,
              onToggle: (value) => toggledValue = value,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      expect(toggledValue, true);
    });

    testWidgets('shows custom tooltip when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemeToggleButton(
              isDarkMode: false,
              onToggle: (value) {},
              tooltip: 'Custom tooltip',
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, 'Custom tooltip');
    });

    testWidgets('shows default tooltip when none provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemeToggleButton(
              isDarkMode: false,
              onToggle: (value) {},
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, '切换到深色主题');
    });
  });

  group('ThemeSettingsTile', () {
    testWidgets('renders with current theme info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemeSettingsTile(
              currentTheme: AppThemeMode.system,
              onThemeChanged: (theme) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.brightness_auto), findsOneWidget);
      expect(find.text('主题设置'), findsOneWidget);
      expect(find.text('跟随系统'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('shows theme selection dialog when tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemeSettingsTile(
              currentTheme: AppThemeMode.light,
              onThemeChanged: (theme) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      expect(find.text('选择主题'), findsOneWidget);
      expect(find.byType(RadioListTile<AppThemeMode>), findsNWidgets(3));
    });

    testWidgets('calls onThemeChanged when theme is selected in dialog', (tester) async {
      AppThemeMode? selectedTheme;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemeSettingsTile(
              currentTheme: AppThemeMode.light,
              onThemeChanged: (theme) => selectedTheme = theme,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      // Find and tap the dark theme radio button
      final darkThemeRadio = find.byWidgetPredicate(
        (widget) => widget is RadioListTile<AppThemeMode> && 
                   widget.value == AppThemeMode.dark,
      );
      
      await tester.tap(darkThemeRadio);
      await tester.pumpAndSettle();

      expect(selectedTheme, AppThemeMode.dark);
    });
  });
}