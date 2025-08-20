import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../sync/domain/entities/s3_config.dart';
import '../../../../core/services/s3_connection_test_service.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

/// Widget for configuring S3 storage settings
class S3ConfigWidget extends StatefulWidget {
  final S3Config? initialConfig;
  final VoidCallback? onConfigChanged;

  const S3ConfigWidget({
    super.key,
    this.initialConfig,
    this.onConfigChanged,
  });

  @override
  State<S3ConfigWidget> createState() => _S3ConfigWidgetState();
}

class _S3ConfigWidgetState extends State<S3ConfigWidget> {
  final _formKey = GlobalKey<FormState>();
  final _endpointController = TextEditingController();
  final _regionController = TextEditingController();
  final _accessKeyController = TextEditingController();
  final _secretKeyController = TextEditingController();
  final _bucketController = TextEditingController();
  final _portController = TextEditingController();

  bool _useSSL = true;
  bool _showSecretKey = false;
  String _configType = 'aws'; // 'aws' or 'minio' or 'custom'

  @override
  void initState() {
    super.initState();
    _loadInitialConfig();
  }

  @override
  void dispose() {
    _endpointController.dispose();
    _regionController.dispose();
    _accessKeyController.dispose();
    _secretKeyController.dispose();
    _bucketController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _loadInitialConfig() {
    final config = widget.initialConfig;
    if (config != null) {
      _endpointController.text = config.endpoint;
      _regionController.text = config.region;
      _accessKeyController.text = config.accessKeyId;
      _secretKeyController.text = config.secretAccessKey;
      _bucketController.text = config.bucketName;
      _useSSL = config.useSSL;
      _portController.text = config.port?.toString() ?? '';

      // Determine config type
      if (config.endpoint.contains('amazonaws.com')) {
        _configType = 'aws';
      } else if (config.endpoint.contains('localhost') || config.endpoint.contains('127.0.0.1')) {
        _configType = 'minio';
      } else {
        _configType = 'custom';
      }
    }
  }

  S3Config _buildConfig() {
    return S3Config(
      endpoint: _endpointController.text.trim(),
      region: _regionController.text.trim(),
      accessKeyId: _accessKeyController.text.trim(),
      secretAccessKey: _secretKeyController.text.trim(),
      bucketName: _bucketController.text.trim(),
      useSSL: _useSSL,
      port: _portController.text.isNotEmpty ? int.tryParse(_portController.text) : null,
    );
  }

  void _onConfigTypeChanged(String? type) {
    if (type == null) return;
    
    setState(() {
      _configType = type;
      
      switch (type) {
        case 'aws':
          _endpointController.text = 's3.amazonaws.com';
          _regionController.text = 'us-east-1';
          _useSSL = true;
          _portController.clear();
          break;
        case 'minio':
          _endpointController.text = 'localhost';
          _regionController.text = 'us-east-1';
          _useSSL = false;
          _portController.text = '9000';
          break;
        case 'custom':
          // Keep current values
          break;
      }
    });
  }

  void _testConnection() {
    if (!_formKey.currentState!.validate()) return;
    
    final config = _buildConfig();
    context.read<SettingsBloc>().add(TestS3Connection(config));
  }

  void _saveConfig() {
    if (!_formKey.currentState!.validate()) return;
    
    final config = _buildConfig();
    context.read<SettingsBloc>().add(UpdateS3Config(config));
    widget.onConfigChanged?.call();
  }

  void _clearConfig() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除S3配置'),
        content: const Text('确定要清除所有S3配置信息吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<SettingsBloc>().add(const ClearS3Config());
              setState(() {
                _endpointController.clear();
                _regionController.clear();
                _accessKeyController.clear();
                _secretKeyController.clear();
                _bucketController.clear();
                _portController.clear();
                _useSSL = true;
                _configType = 'aws';
              });
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state is S3ConnectionTestSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.result.message ?? '连接测试成功'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (state is S3ConnectionTestFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.result.error ?? '连接测试失败'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.cloud, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      'S3 存储配置',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Configuration Type Selector
                DropdownButtonFormField<String>(
                  value: _configType,
                  decoration: const InputDecoration(
                    labelText: '配置类型',
                    border: OutlineInputBorder(),
                    helperText: '选择预设配置或自定义',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'aws', child: Text('AWS S3')),
                    DropdownMenuItem(value: 'minio', child: Text('MinIO')),
                    DropdownMenuItem(value: 'custom', child: Text('自定义')),
                  ],
                  onChanged: _onConfigTypeChanged,
                ),
                const SizedBox(height: 16),

                // Endpoint
                TextFormField(
                  controller: _endpointController,
                  decoration: const InputDecoration(
                    labelText: 'S3 端点 *',
                    hintText: 's3.amazonaws.com 或 localhost',
                    border: OutlineInputBorder(),
                    helperText: '不包含协议前缀 (http:// 或 https://)',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入S3端点';
                    }
                    if (value.startsWith('http://') || value.startsWith('https://')) {
                      return '端点不应包含协议前缀';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Region and Port Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _regionController,
                        decoration: const InputDecoration(
                          labelText: '区域 *',
                          hintText: 'us-east-1',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '请输入区域';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _portController,
                        decoration: const InputDecoration(
                          labelText: '端口',
                          hintText: '9000',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final port = int.tryParse(value);
                            if (port == null || port < 1 || port > 65535) {
                              return '无效端口';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Access Key
                TextFormField(
                  controller: _accessKeyController,
                  decoration: const InputDecoration(
                    labelText: 'Access Key *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入Access Key';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Secret Key
                TextFormField(
                  controller: _secretKeyController,
                  decoration: InputDecoration(
                    labelText: 'Secret Key *',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_showSecretKey ? Icons.visibility_off : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _showSecretKey = !_showSecretKey;
                        });
                      },
                    ),
                  ),
                  obscureText: !_showSecretKey,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入Secret Key';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Bucket Name
                TextFormField(
                  controller: _bucketController,
                  decoration: const InputDecoration(
                    labelText: 'Bucket 名称 *',
                    border: OutlineInputBorder(),
                    helperText: '存储笔记的S3存储桶名称',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入Bucket名称';
                    }
                    // Basic bucket name validation
                    if (!RegExp(r'^[a-z0-9.-]+$').hasMatch(value)) {
                      return 'Bucket名称只能包含小写字母、数字、点和连字符';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // SSL Switch
                SwitchListTile(
                  title: const Text('使用 SSL/TLS'),
                  subtitle: const Text('启用加密连接 (HTTPS)'),
                  value: _useSSL,
                  onChanged: (value) {
                    setState(() {
                      _useSSL = value;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Action Buttons
                BlocBuilder<SettingsBloc, SettingsState>(
                  builder: (context, state) {
                    final isLoading = state is S3ConnectionTesting;
                    
                    return Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : _testConnection,
                          icon: isLoading 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wifi_protected_setup),
                          label: Text(isLoading ? '测试中...' : '测试连接'),
                        ),
                        ElevatedButton.icon(
                          onPressed: _saveConfig,
                          icon: const Icon(Icons.save),
                          label: const Text('保存配置'),
                        ),
                        TextButton.icon(
                          onPressed: _clearConfig,
                          icon: const Icon(Icons.clear),
                          label: const Text('清除配置'),
                        ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Help Text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '配置说明',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• AWS S3: 使用标准AWS S3服务\n'
                        '• MinIO: 使用自托管的MinIO服务\n'
                        '• 自定义: 使用其他S3兼容服务\n'
                        '• 测试连接会验证配置并检查读写权限',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}