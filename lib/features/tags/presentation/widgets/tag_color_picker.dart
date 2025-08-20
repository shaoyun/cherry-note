import 'package:flutter/material.dart';

/// 标签颜色选择器对话框
class TagColorPickerDialog extends StatefulWidget {
  /// 标签名称
  final String tagName;
  
  /// 初始颜色
  final String? initialColor;

  const TagColorPickerDialog({
    super.key,
    required this.tagName,
    this.initialColor,
  });

  @override
  State<TagColorPickerDialog> createState() => _TagColorPickerDialogState();
}

class _TagColorPickerDialogState extends State<TagColorPickerDialog> {
  String? _selectedColor;

  // 预定义的标签颜色
  static const List<Color> _predefinedColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFFF44336), // Red
    Color(0xFF9C27B0), // Purple
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF795548), // Brown
    Color(0xFF009688), // Teal
    Color(0xFFE91E63), // Pink
    Color(0xFF3F51B5), // Indigo
    Color(0xFFCDDC39), // Lime
    Color(0xFFFF5722), // Deep Orange
  ];

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('选择标签颜色'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标签预览
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).dividerColor,
                ),
              ),
              child: Row(
                children: [
                  Text('预览: '),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedColor != null
                          ? Color(int.parse(_selectedColor!.substring(1), radix: 16) + 0xFF000000).withOpacity(0.1)
                          : Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedColor != null
                            ? Color(int.parse(_selectedColor!.substring(1), radix: 16) + 0xFF000000)
                            : Theme.of(context).primaryColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_offer,
                          size: 14,
                          color: _selectedColor != null
                              ? Color(int.parse(_selectedColor!.substring(1), radix: 16) + 0xFF000000)
                              : Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.tagName.isEmpty ? '标签名称' : widget.tagName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _selectedColor != null
                                ? Color(int.parse(_selectedColor!.substring(1), radix: 16) + 0xFF000000)
                                : Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 颜色选择网格
            Text(
              '选择颜色:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _predefinedColors.length + 1, // +1 for default color
              itemBuilder: (context, index) {
                if (index == 0) {
                  // 默认颜色选项
                  return _buildColorOption(
                    null,
                    '默认',
                    Theme.of(context).primaryColor,
                  );
                }
                
                final color = _predefinedColors[index - 1];
                return _buildColorOption(
                  _colorToHex(color),
                  '',
                  color,
                );
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedColor),
          child: const Text('确定'),
        ),
      ],
    );
  }

  Widget _buildColorOption(String? colorHex, String label, Color color) {
    final isSelected = _selectedColor == colorHex;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedColor = colorHex;
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: label.isNotEmpty
              ? Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                )
              : isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
        ),
      ),
    );
  }
}

/// 简单的颜色选择器组件
class TagColorPicker extends StatefulWidget {
  /// 当前选中的颜色
  final String? selectedColor;
  
  /// 颜色变更回调
  final ValueChanged<String?>? onColorChanged;
  
  /// 是否显示标签
  final bool showLabels;

  const TagColorPicker({
    super.key,
    this.selectedColor,
    this.onColorChanged,
    this.showLabels = false,
  });

  @override
  State<TagColorPicker> createState() => _TagColorPickerState();
}

class _TagColorPickerState extends State<TagColorPicker> {
  // 预定义的标签颜色
  static const List<Color> _predefinedColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFFF44336), // Red
    Color(0xFF9C27B0), // Purple
    Color(0xFF607D8B), // Blue Grey
    Color(0xFF795548), // Brown
    Color(0xFF009688), // Teal
    Color(0xFFE91E63), // Pink
    Color(0xFF3F51B5), // Indigo
    Color(0xFFCDDC39), // Lime
    Color(0xFFFF5722), // Deep Orange
  ];

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // 默认颜色选项
        _buildColorOption(null, '默认', Theme.of(context).primaryColor),
        
        // 预定义颜色选项
        ..._predefinedColors.map((color) {
          return _buildColorOption(_colorToHex(color), '', color);
        }),
      ],
    );
  }

  Widget _buildColorOption(String? colorHex, String label, Color color) {
    final isSelected = widget.selectedColor == colorHex;
    
    return GestureDetector(
      onTap: () => widget.onColorChanged?.call(colorHex),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: label.isNotEmpty && widget.showLabels
              ? Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                )
              : isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
        ),
      ),
    );
  }
}