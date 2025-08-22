import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../../../settings/presentation/bloc/settings_event.dart';
import '../../../settings/presentation/bloc/settings_state.dart';
import '../../../settings/presentation/widgets/s3_config_widget.dart';

/// 设置页面
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    // Load settings when the page is initialized
    context.read<SettingsBloc>().add(const LoadSettings());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('设置'),
          actions: [
            BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) {
                return TextButton(
                  onPressed: state is SettingsLoaded 
                    ? () => context.read<SettingsBloc>().add(const SaveAllSettings())
                    : null,
                  child: const Text('保存'),
                );
              },
            ),
          ],
        ),
        body: BlocListener<SettingsBloc, SettingsState>(
          listener: (context, state) {
            if (state is SettingsSaved) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('设置已保存'),
                  duration: Duration(seconds: 2),
                ),
              );
            } else if (state is SettingsExported) {
              final message = state.exportedSettings['message'] as String? ?? '设置已导出';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 3),
                ),
              );
            } else if (state is SettingsImported) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('设置已成功导入'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            } else if (state is SettingsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          },
          child: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              if (state is SettingsLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (state is SettingsError && state.currentSettings == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('加载设置失败: ${state.message}'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.read<SettingsBloc>().add(const LoadSettings()),
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                );
              }
              
              final settings = state is SettingsLoaded 
                ? state 
                : (state is SettingsError ? state.currentSettings : null);
                
              if (settings == null) {
                return const Center(child: CircularProgressIndicator());
              }
              
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildThemeSection(settings),
                    const SizedBox(height: 24),
                    _buildEditorSection(settings),
                    const SizedBox(height: 24),
                    _buildSyncSection(settings),
                    const SizedBox(height: 24),
                    _buildInterfaceSection(settings),
                    const SizedBox(height: 24),
                    S3ConfigWidget(
                      initialConfig: settings.s3Config,
                      onConfigChanged: () {
                        // Config is automatically saved by the widget
                      },
                    ),
                    const SizedBox(height: 24),
                    _buildSettingsManagementSection(),
                    const SizedBox(height: 24),
                    _buildAboutSection(),
                  ],
                ),
              );
            },
          ),
        ),
    );
  }

  /// 构建主题设置部分
  Widget _buildThemeSection(SettingsLoaded settings) {
    return _buildSection(
      title: '外观',
      icon: Icons.palette,
      children: [
        ListTile(
          title: const Text('主题模式'),
          subtitle: const Text('选择应用的主题模式'),
          trailing: DropdownButton<String>(
            value: settings.themeMode,
            onChanged: (value) {
              if (value != null) {
                context.read<SettingsBloc>().add(UpdateThemeMode(value));
              }
            },
            items: const [
              DropdownMenuItem(
                value: 'system',
                child: Text('跟随系统'),
              ),
              DropdownMenuItem(
                value: 'light',
                child: Text('浅色模式'),
              ),
              DropdownMenuItem(
                value: 'dark',
                child: Text('深色模式'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建编辑器设置部分
  Widget _buildEditorSection(SettingsLoaded settings) {
    return _buildSection(
      title: '编辑器',
      icon: Icons.edit,
      children: [
        ListTile(
          title: const Text('字体大小'),
          subtitle: Text('当前: ${settings.fontSize.toInt()}px'),
          trailing: SizedBox(
            width: 200,
            child: Slider(
              value: settings.fontSize,
              min: 10,
              max: 24,
              divisions: 14,
              onChanged: (value) {
                context.read<SettingsBloc>().add(UpdateFontSize(value));
              },
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('显示行号'),
          subtitle: const Text('在编辑器中显示行号'),
          value: settings.showLineNumbers,
          onChanged: (value) {
            context.read<SettingsBloc>().add(UpdateShowLineNumbers(value));
          },
        ),
        SwitchListTile(
          title: const Text('自动换行'),
          subtitle: const Text('长行自动换行显示'),
          value: settings.wordWrap,
          onChanged: (value) {
            context.read<SettingsBloc>().add(UpdateWordWrap(value));
          },
        ),
        SwitchListTile(
          title: const Text('自动保存'),
          subtitle: const Text('编辑时自动保存笔记'),
          value: settings.autoSave,
          onChanged: (value) {
            context.read<SettingsBloc>().add(UpdateAutoSave(value));
          },
        ),
        if (settings.autoSave)
          ListTile(
            title: const Text('自动保存间隔'),
            subtitle: Text('每 ${settings.autoSaveInterval} 秒自动保存一次'),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                value: settings.autoSaveInterval.toDouble(),
                min: 10,
                max: 120,
                divisions: 11,
                onChanged: (value) {
                  context.read<SettingsBloc>().add(UpdateAutoSaveInterval(value.toInt()));
                },
              ),
            ),
          ),
      ],
    );
  }

  /// 构建同步设置部分
  Widget _buildSyncSection(SettingsLoaded settings) {
    return _buildSection(
      title: '同步',
      icon: Icons.sync,
      children: [
        SwitchListTile(
          title: const Text('自动同步'),
          subtitle: const Text('定期自动同步到云端'),
          value: settings.autoSync,
          onChanged: (value) {
            context.read<SettingsBloc>().add(UpdateAutoSync(value));
          },
        ),
        if (settings.autoSync)
          ListTile(
            title: const Text('同步间隔'),
            subtitle: Text('每 ${settings.syncInterval} 分钟同步一次'),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                value: settings.syncInterval.toDouble(),
                min: 1,
                max: 60,
                divisions: 59,
                onChanged: (value) {
                  context.read<SettingsBloc>().add(UpdateSyncInterval(value.toInt()));
                },
              ),
            ),
          ),
        SwitchListTile(
          title: const Text('启动时同步'),
          subtitle: const Text('应用启动时自动同步'),
          value: settings.syncOnStartup,
          onChanged: (value) {
            context.read<SettingsBloc>().add(UpdateSyncOnStartup(value));
          },
        ),
        SwitchListTile(
          title: const Text('关闭时同步'),
          subtitle: const Text('应用关闭时自动同步'),
          value: settings.syncOnClose,
          onChanged: (value) {
            context.read<SettingsBloc>().add(UpdateSyncOnClose(value));
          },
        ),
      ],
    );
  }

  /// 构建界面设置部分
  Widget _buildInterfaceSection(SettingsLoaded settings) {
    return _buildSection(
      title: '界面',
      icon: Icons.view_quilt,
      children: [
        SwitchListTile(
          title: const Text('显示工具栏'),
          subtitle: const Text('显示顶部工具栏'),
          value: settings.showToolbar,
          onChanged: (value) {
            context.read<SettingsBloc>().add(UpdateShowToolbar(value));
          },
        ),
        SwitchListTile(
          title: const Text('显示状态栏'),
          subtitle: const Text('显示底部状态栏'),
          value: settings.showStatusBar,
          onChanged: (value) {
            context.read<SettingsBloc>().add(UpdateShowStatusBar(value));
          },
        ),
        SwitchListTile(
          title: const Text('紧凑模式'),
          subtitle: const Text('使用更紧凑的界面布局'),
          value: settings.compactMode,
          onChanged: (value) {
            context.read<SettingsBloc>().add(UpdateCompactMode(value));
          },
        ),
      ],
    );
  }

  /// 构建设置管理部分
  Widget _buildSettingsManagementSection() {
    return _buildSection(
      title: '设置管理',
      icon: Icons.settings_backup_restore,
      children: [
        ListTile(
          title: const Text('导出设置'),
          subtitle: const Text('将当前设置导出到文件'),
          leading: const Icon(Icons.file_download),
          onTap: () {
            context.read<SettingsBloc>().add(const ExportSettings());
          },
        ),
        ListTile(
          title: const Text('导入设置'),
          subtitle: const Text('从文件导入设置'),
          leading: const Icon(Icons.file_upload),
          onTap: () {
            context.read<SettingsBloc>().add(const ImportSettings());
          },
        ),
        ListTile(
          title: const Text('重置所有设置'),
          subtitle: const Text('恢复到默认设置'),
          leading: const Icon(Icons.restore, color: Colors.red),
          onTap: _showResetDialog,
        ),
      ],
    );
  }

  /// 构建关于部分
  Widget _buildAboutSection() {
    return _buildSection(
      title: '关于',
      icon: Icons.info,
      children: [
        ListTile(
          title: const Text('Cherry Note'),
          subtitle: const Text('版本 1.0.0'),
          leading: const Icon(Icons.note),
        ),
        ListTile(
          title: const Text('开发者'),
          subtitle: const Text('Cherry Note Team'),
        ),
        ListTile(
          title: const Text('许可证'),
          subtitle: const Text('MIT License'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton(
              onPressed: _showAboutDialog,
              child: const Text('关于应用'),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: _checkForUpdates,
              child: const Text('检查更新'),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建设置部分
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }



  /// 显示重置设置对话框
  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置所有设置'),
        content: const Text('确定要重置所有设置到默认值吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<SettingsBloc>().add(const ResetAllSettings());
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示关于对话框
  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Cherry Note',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.note, size: 48),
      children: [
        const Text('一个跨平台的Markdown笔记应用，支持S3存储同步。'),
        const SizedBox(height: 16),
        const Text('功能特性：'),
        const Text('• 三栏布局设计'),
        const Text('• Markdown编辑和预览'),
        const Text('• 多级文件夹管理'),
        const Text('• 标签过滤系统'),
        const Text('• S3云端同步'),
        const Text('• 跨平台支持'),
      ],
    );
  }

  /// 检查更新
  void _checkForUpdates() {
    // TODO: 实现更新检查
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('当前已是最新版本'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}

