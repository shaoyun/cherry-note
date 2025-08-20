import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 关于页面
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于 Cherry Note'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 应用图标和名称
            _buildAppHeader(context),
            
            const SizedBox(height: 32),
            
            // 应用描述
            _buildDescription(context),
            
            const SizedBox(height: 32),
            
            // 功能特性
            _buildFeatures(context),
            
            const SizedBox(height: 32),
            
            // 技术栈
            _buildTechStack(context),
            
            const SizedBox(height: 32),
            
            // 版权信息
            _buildCopyright(context),
            
            const SizedBox(height: 32),
            
            // 操作按钮
            _buildActions(context),
          ],
        ),
      ),
    );
  }

  /// 构建应用头部
  Widget _buildAppHeader(BuildContext context) {
    return Column(
      children: [
        // 应用图标
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.note,
            size: 64,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // 应用名称
        Text(
          'Cherry Note',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // 版本信息
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Version 1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建应用描述
  Widget _buildDescription(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '应用简介',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Cherry Note 是一个现代化的跨平台Markdown笔记应用，专为提高写作效率而设计。'
              '它采用三栏布局，支持实时预览，并提供强大的文件夹管理和标签过滤功能。'
              '通过S3兼容的对象存储，您可以在多个设备间无缝同步您的笔记。',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建功能特性
  Widget _buildFeatures(BuildContext context) {
    final features = [
      _FeatureItem(
        icon: Icons.view_column,
        title: '三栏布局',
        description: '文件夹树、笔记列表、编辑预览区域',
      ),
      _FeatureItem(
        icon: Icons.markdown,
        title: 'Markdown支持',
        description: '实时编辑和预览，语法高亮',
      ),
      _FeatureItem(
        icon: Icons.folder_outlined,
        title: '文件夹管理',
        description: '多级目录结构，拖拽操作',
      ),
      _FeatureItem(
        icon: Icons.label,
        title: '标签过滤',
        description: '灵活的标签系统，快速筛选',
      ),
      _FeatureItem(
        icon: Icons.cloud_sync,
        title: 'S3同步',
        description: '云端存储，多设备同步',
      ),
      _FeatureItem(
        icon: Icons.devices,
        title: '跨平台',
        description: 'Android、Windows、macOS支持',
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '主要特性',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 3,
              ),
              itemCount: features.length,
              itemBuilder: (context, index) {
                final feature = features[index];
                return _buildFeatureItem(context, feature);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建功能特性项
  Widget _buildFeatureItem(BuildContext context, _FeatureItem feature) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            feature.icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  feature.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  feature.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建技术栈
  Widget _buildTechStack(BuildContext context) {
    final technologies = [
      'Flutter',
      'Dart',
      'BLoC Pattern',
      'S3 API',
      'SQLite',
      'Markdown',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.code,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '技术栈',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: technologies.map((tech) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    tech,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建版权信息
  Widget _buildCopyright(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.copyright,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(height: 8),
            Text(
              '© 2024 Cherry Note Team',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Licensed under MIT License',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建操作按钮
  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () => _copySystemInfo(context),
          icon: const Icon(Icons.info),
          label: const Text('系统信息'),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: () => _showLicenses(context),
          icon: const Icon(Icons.article),
          label: const Text('开源许可'),
        ),
      ],
    );
  }

  /// 复制系统信息
  void _copySystemInfo(BuildContext context) {
    final systemInfo = '''
Cherry Note v1.0.0
Platform: ${Theme.of(context).platform.name}
Flutter Version: 3.16.0
Dart Version: 3.2.0
Build Date: ${DateTime.now().toIso8601String().split('T')[0]}
''';

    Clipboard.setData(ClipboardData(text: systemInfo));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('系统信息已复制到剪贴板'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 显示开源许可
  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'Cherry Note',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.note, size: 48),
    );
  }
}

/// 功能特性项数据类
class _FeatureItem {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}