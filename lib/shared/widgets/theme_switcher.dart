import 'package:flutter/material.dart';

/// Theme mode enum
enum AppThemeMode {
  light,
  dark,
  system,
}

extension AppThemeModeExtension on AppThemeMode {
  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return '浅色主题';
      case AppThemeMode.dark:
        return '深色主题';
      case AppThemeMode.system:
        return '跟随系统';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  ThemeMode get themeMode {
    switch (this) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

/// Theme switcher widget
class ThemeSwitcher extends StatelessWidget {
  final AppThemeMode currentTheme;
  final ValueChanged<AppThemeMode> onThemeChanged;
  final bool showLabel;
  
  const ThemeSwitcher({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AppThemeMode>(
      initialValue: currentTheme,
      onSelected: onThemeChanged,
      itemBuilder: (context) => AppThemeMode.values.map((theme) {
        return PopupMenuItem<AppThemeMode>(
          value: theme,
          child: Row(
            children: [
              Icon(theme.icon),
              const SizedBox(width: 12),
              Text(theme.displayName),
              if (theme == currentTheme) ...[
                const Spacer(),
                const Icon(Icons.check, color: Colors.green),
              ],
            ],
          ),
        );
      }).toList(),
      child: showLabel
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(currentTheme.icon),
                const SizedBox(width: 8),
                Text(currentTheme.displayName),
                const Icon(Icons.arrow_drop_down),
              ],
            )
          : Icon(currentTheme.icon),
    );
  }
}

/// Theme toggle button (light/dark only)
class ThemeToggleButton extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggle;
  final String? tooltip;
  
  const ThemeToggleButton({
    super.key,
    required this.isDarkMode,
    required this.onToggle,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => onToggle(!isDarkMode),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          isDarkMode ? Icons.light_mode : Icons.dark_mode,
          key: ValueKey(isDarkMode),
        ),
      ),
      tooltip: tooltip ?? (isDarkMode ? '切换到浅色主题' : '切换到深色主题'),
    );
  }
}

/// Theme settings tile for settings page
class ThemeSettingsTile extends StatelessWidget {
  final AppThemeMode currentTheme;
  final ValueChanged<AppThemeMode> onThemeChanged;
  
  const ThemeSettingsTile({
    super.key,
    required this.currentTheme,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(currentTheme.icon),
      title: const Text('主题设置'),
      subtitle: Text(currentTheme.displayName),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showThemeDialog(context),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeMode.values.map((theme) {
            return RadioListTile<AppThemeMode>(
              value: theme,
              groupValue: currentTheme,
              onChanged: (value) {
                if (value != null) {
                  onThemeChanged(value);
                  Navigator.of(context).pop();
                }
              },
              title: Row(
                children: [
                  Icon(theme.icon),
                  const SizedBox(width: 12),
                  Text(theme.displayName),
                ],
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}