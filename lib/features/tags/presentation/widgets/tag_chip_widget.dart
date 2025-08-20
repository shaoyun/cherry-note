import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/tag.dart';
import '../bloc/tags_bloc.dart';
import '../bloc/tags_state.dart';

/// 标签芯片组件，用于显示单个标签
class TagChipWidget extends StatelessWidget {
  /// 标签名称
  final String tag;
  
  /// 删除回调
  final VoidCallback? onDeleted;
  
  /// 点击回调
  final VoidCallback? onTap;
  
  /// 是否显示删除按钮
  final bool showDeleteButton;
  
  /// 是否选中状态
  final bool isSelected;
  
  /// 自定义颜色
  final Color? color;
  
  /// 芯片大小
  final double? height;

  const TagChipWidget({
    super.key,
    required this.tag,
    this.onDeleted,
    this.onTap,
    this.showDeleteButton = true,
    this.isSelected = false,
    this.color,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TagsBloc, TagsState>(
      builder: (context, state) {
        Tag? tagEntity;
        
        // 尝试从状态中获取标签实体以获取颜色信息
        if (state is TagsLoaded) {
          tagEntity = state.tags.cast<Tag?>().firstWhere(
            (t) => t?.name == tag,
            orElse: () => null,
          );
        }

        final tagColor = color ?? 
            (tagEntity?.color != null 
                ? Color(int.parse(tagEntity!.color!.substring(1), radix: 16) + 0xFF000000)
                : null);

        return GestureDetector(
          onTap: onTap,
          child: Container(
            height: height ?? 32,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected 
                  ? (tagColor ?? Theme.of(context).primaryColor)
                  : (tagColor?.withOpacity(0.1) ?? Theme.of(context).primaryColor.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: tagColor ?? Theme.of(context).primaryColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标签图标
                Icon(
                  Icons.local_offer,
                  size: 14,
                  color: isSelected 
                      ? Colors.white
                      : (tagColor ?? Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 4),
                
                // 标签文本
                Flexible(
                  child: Text(
                    tag,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected 
                          ? Colors.white
                          : (tagColor ?? Theme.of(context).primaryColor),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                // 删除按钮
                if (showDeleteButton && onDeleted != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onDeleted,
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: isSelected 
                          ? Colors.white
                          : (tagColor ?? Theme.of(context).primaryColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 可选择的标签芯片组件
class SelectableTagChip extends StatelessWidget {
  /// 标签名称
  final String tag;
  
  /// 是否选中
  final bool isSelected;
  
  /// 选择状态变更回调
  final ValueChanged<bool>? onSelectionChanged;
  
  /// 自定义颜色
  final Color? color;

  const SelectableTagChip({
    super.key,
    required this.tag,
    this.isSelected = false,
    this.onSelectionChanged,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TagChipWidget(
      tag: tag,
      isSelected: isSelected,
      color: color,
      showDeleteButton: false,
      onTap: () => onSelectionChanged?.call(!isSelected),
    );
  }
}

/// 带计数的标签芯片组件
class CountedTagChip extends StatelessWidget {
  /// 标签名称
  final String tag;
  
  /// 笔记数量
  final int count;
  
  /// 点击回调
  final VoidCallback? onTap;
  
  /// 是否选中状态
  final bool isSelected;
  
  /// 自定义颜色
  final Color? color;

  const CountedTagChip({
    super.key,
    required this.tag,
    required this.count,
    this.onTap,
    this.isSelected = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TagsBloc, TagsState>(
      builder: (context, state) {
        Tag? tagEntity;
        
        // 尝试从状态中获取标签实体
        if (state is TagsLoaded) {
          tagEntity = state.tags.cast<Tag?>().firstWhere(
            (t) => t?.name == tag,
            orElse: () => null,
          );
        }

        final tagColor = color ?? 
            (tagEntity?.color != null 
                ? Color(int.parse(tagEntity!.color!.substring(1), radix: 16) + 0xFF000000)
                : null);

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected 
                  ? (tagColor ?? Theme.of(context).primaryColor)
                  : (tagColor?.withOpacity(0.1) ?? Theme.of(context).primaryColor.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: tagColor ?? Theme.of(context).primaryColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 标签图标
                Icon(
                  Icons.local_offer,
                  size: 14,
                  color: isSelected 
                      ? Colors.white
                      : (tagColor ?? Theme.of(context).primaryColor),
                ),
                const SizedBox(width: 4),
                
                // 标签文本
                Text(
                  tag,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isSelected 
                        ? Colors.white
                        : (tagColor ?? Theme.of(context).primaryColor),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(width: 4),
                
                // 计数徽章
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white.withOpacity(0.2)
                        : (tagColor ?? Theme.of(context).primaryColor).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isSelected 
                          ? Colors.white
                          : (tagColor ?? Theme.of(context).primaryColor),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}