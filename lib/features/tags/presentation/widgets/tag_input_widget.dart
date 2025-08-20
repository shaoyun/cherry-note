import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/tag.dart';
import '../bloc/tags_bloc.dart';
import '../bloc/tags_event.dart';
import '../bloc/tags_state.dart';
import 'tag_chip_widget.dart';
import 'tag_color_picker.dart';

/// 标签输入组件，支持标签的添加、删除和自动补全
class TagInputWidget extends StatefulWidget {
  /// 当前选中的标签列表
  final List<String> selectedTags;
  
  /// 标签变更回调
  final ValueChanged<List<String>>? onTagsChanged;
  
  /// 是否只读模式
  final bool readOnly;
  
  /// 最大标签数量限制
  final int? maxTags;
  
  /// 输入框提示文本
  final String? hintText;
  
  /// 是否显示颜色选择器
  final bool showColorPicker;
  
  /// 是否允许创建新标签
  final bool allowCreateNew;

  const TagInputWidget({
    super.key,
    this.selectedTags = const [],
    this.onTagsChanged,
    this.readOnly = false,
    this.maxTags,
    this.hintText,
    this.showColorPicker = false,
    this.allowCreateNew = true,
  });

  @override
  State<TagInputWidget> createState() => _TagInputWidgetState();
}

class _TagInputWidgetState extends State<TagInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];
  bool _showSuggestions = false;
  String? _selectedColor;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _getSuggestions(_controller.text);
    } else {
      _hideOverlay();
    }
  }

  void _onTextChanged(String text) {
    _getSuggestions(text);
  }

  void _getSuggestions(String query) {
    if (widget.readOnly) return;
    
    context.read<TagsBloc>().add(GetTagSuggestionsEvent(
      query: query,
      limit: 10,
    ));
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _getInputWidth(),
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 50),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              child: _buildSuggestionsList(),
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
    setState(() {
      _showSuggestions = true;
    });
  }

  void _hideOverlay() {
    _removeOverlay();
    setState(() {
      _showSuggestions = false;
    });
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  double _getInputWidth() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 300;
  }

  Widget _buildSuggestionsList() {
    if (_suggestions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          widget.allowCreateNew && _controller.text.isNotEmpty
              ? '按回车创建新标签 "${_controller.text}"'
              : '没有找到匹配的标签',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).hintColor,
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        final isSelected = widget.selectedTags.contains(suggestion);
        
        return ListTile(
          dense: true,
          title: Text(suggestion),
          trailing: isSelected ? const Icon(Icons.check, size: 16) : null,
          onTap: isSelected ? null : () => _selectTag(suggestion),
          enabled: !isSelected,
        );
      },
    );
  }

  void _selectTag(String tagName) {
    if (widget.readOnly) return;
    if (widget.selectedTags.contains(tagName)) return;
    if (widget.maxTags != null && widget.selectedTags.length >= widget.maxTags!) {
      _showMaxTagsReachedMessage();
      return;
    }

    final newTags = [...widget.selectedTags, tagName];
    widget.onTagsChanged?.call(newTags);
    
    _controller.clear();
    _hideOverlay();
    _focusNode.requestFocus();
  }

  void _removeTag(String tagName) {
    if (widget.readOnly) return;
    
    final newTags = widget.selectedTags.where((tag) => tag != tagName).toList();
    widget.onTagsChanged?.call(newTags);
  }

  void _createNewTag() {
    final tagName = _controller.text.trim();
    if (tagName.isEmpty) return;
    if (widget.selectedTags.contains(tagName)) return;
    if (!widget.allowCreateNew) return;
    if (widget.maxTags != null && widget.selectedTags.length >= widget.maxTags!) {
      _showMaxTagsReachedMessage();
      return;
    }

    // 如果显示颜色选择器，先选择颜色
    if (widget.showColorPicker) {
      _showColorPickerDialog(tagName);
    } else {
      _createTag(tagName, null);
    }
  }

  void _createTag(String tagName, String? color) {
    // 创建新标签
    context.read<TagsBloc>().add(CreateTagEvent(
      name: tagName,
      color: color,
    ));

    // 添加到选中列表
    final newTags = [...widget.selectedTags, tagName];
    widget.onTagsChanged?.call(newTags);
    
    _controller.clear();
    _hideOverlay();
    _focusNode.requestFocus();
  }

  void _showColorPickerDialog(String tagName) {
    showDialog<String>(
      context: context,
      builder: (context) => TagColorPickerDialog(
        tagName: tagName,
        initialColor: _selectedColor,
      ),
    ).then((color) {
      if (color != null) {
        _createTag(tagName, color);
      }
    });
  }

  void _showMaxTagsReachedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('最多只能添加 ${widget.maxTags} 个标签'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TagsBloc, TagsState>(
      listener: (context, state) {
        if (state is TagSuggestions) {
          setState(() {
            _suggestions = state.suggestions
                .where((suggestion) => !widget.selectedTags.contains(suggestion))
                .toList();
          });
          
          if (_focusNode.hasFocus && _suggestions.isNotEmpty) {
            _showOverlay();
          } else {
            _hideOverlay();
          }
        } else if (state is TagsLoaded && state.suggestions != null) {
          setState(() {
            _suggestions = state.suggestions!
                .where((suggestion) => !widget.selectedTags.contains(suggestion))
                .toList();
          });
          
          if (_focusNode.hasFocus && _suggestions.isNotEmpty) {
            _showOverlay();
          } else {
            _hideOverlay();
          }
        }
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 已选标签显示
            if (widget.selectedTags.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.selectedTags.map((tag) {
                  return TagChipWidget(
                    tag: tag,
                    onDeleted: widget.readOnly ? null : () => _removeTag(tag),
                    showDeleteButton: !widget.readOnly,
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
            
            // 标签输入框
            if (!widget.readOnly) ...[
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onTextChanged,
                onSubmitted: (_) => _createNewTag(),
                decoration: InputDecoration(
                  hintText: widget.hintText ?? '输入标签名称...',
                  prefixIcon: const Icon(Icons.local_offer_outlined),
                  suffixIcon: widget.showColorPicker
                      ? IconButton(
                          icon: Icon(
                            Icons.palette_outlined,
                            color: _selectedColor != null
                                ? Color(int.parse(_selectedColor!.substring(1), radix: 16) + 0xFF000000)
                                : null,
                          ),
                          onPressed: () => _showColorPickerDialog(_controller.text.trim()),
                          tooltip: '选择颜色',
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                enabled: widget.maxTags == null || widget.selectedTags.length < widget.maxTags!,
              ),
              
              // 提示信息
              if (widget.maxTags != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${widget.selectedTags.length}/${widget.maxTags} 个标签',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}