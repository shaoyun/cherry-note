import 'package:flutter/material.dart';
import 'dart:async';

/// Widget to display real-time sync status
class SyncStatusWidget extends StatefulWidget {
  final SyncStatus status;
  final String? message;
  final double? progress;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final bool showDetails;

  const SyncStatusWidget({
    Key? key,
    required this.status,
    this.message,
    this.progress,
    this.onRetry,
    this.onCancel,
    this.showDetails = false,
  }) : super(key: key);

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    if (widget.status == SyncStatus.syncing) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SyncStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == SyncStatus.syncing && oldWidget.status != SyncStatus.syncing) {
      _animationController.repeat(reverse: true);
    } else if (widget.status != SyncStatus.syncing && oldWidget.status == SyncStatus.syncing) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getStatusColor().withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.status == SyncStatus.syncing ? _pulseAnimation.value : 1.0,
                child: _buildStatusIcon(),
              );
            },
          ),
          const SizedBox(width: 8),
          if (widget.showDetails) ...[
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getStatusText(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(),
                    ),
                  ),
                  if (widget.message != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.message!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (widget.progress != null && widget.status == SyncStatus.syncing) ...[
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: widget.progress,
                      backgroundColor: _getStatusColor().withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            Text(
              _getStatusText(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: _getStatusColor(),
              ),
            ),
          ],
          if (widget.onRetry != null && widget.status == SyncStatus.error) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: widget.onRetry,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.refresh,
                  size: 16,
                  color: _getStatusColor(),
                ),
              ),
            ),
          ],
          if (widget.onCancel != null && widget.status == SyncStatus.syncing) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: widget.onCancel,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: _getStatusColor(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (widget.status) {
      case SyncStatus.idle:
        return Icon(
          Icons.cloud_done,
          size: 16,
          color: _getStatusColor(),
        );
      case SyncStatus.syncing:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
          ),
        );
      case SyncStatus.success:
        return Icon(
          Icons.check_circle,
          size: 16,
          color: _getStatusColor(),
        );
      case SyncStatus.error:
        return Icon(
          Icons.error,
          size: 16,
          color: _getStatusColor(),
        );
      case SyncStatus.conflict:
        return Icon(
          Icons.warning,
          size: 16,
          color: _getStatusColor(),
        );
      case SyncStatus.offline:
        return Icon(
          Icons.cloud_off,
          size: 16,
          color: _getStatusColor(),
        );
    }
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case SyncStatus.idle:
        return Colors.grey;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.success:
        return Colors.green;
      case SyncStatus.error:
        return Colors.red;
      case SyncStatus.conflict:
        return Colors.orange;
      case SyncStatus.offline:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (widget.status) {
      case SyncStatus.idle:
        return '已同步';
      case SyncStatus.syncing:
        return '同步中';
      case SyncStatus.success:
        return '同步成功';
      case SyncStatus.error:
        return '同步失败';
      case SyncStatus.conflict:
        return '存在冲突';
      case SyncStatus.offline:
        return '离线';
    }
  }
}

/// Compact sync status indicator for toolbar/status bar
class CompactSyncStatusIndicator extends StatelessWidget {
  final SyncStatus status;
  final VoidCallback? onTap;

  const CompactSyncStatusIndicator({
    Key? key,
    required this.status,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatusIcon(),
            const SizedBox(width: 4),
            Text(
              _getStatusText(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getStatusColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (status) {
      case SyncStatus.idle:
        return Icon(
          Icons.cloud_done,
          size: 14,
          color: _getStatusColor(),
        );
      case SyncStatus.syncing:
        return SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor()),
          ),
        );
      case SyncStatus.success:
        return Icon(
          Icons.check_circle,
          size: 14,
          color: _getStatusColor(),
        );
      case SyncStatus.error:
        return Icon(
          Icons.error,
          size: 14,
          color: _getStatusColor(),
        );
      case SyncStatus.conflict:
        return Icon(
          Icons.warning,
          size: 14,
          color: _getStatusColor(),
        );
      case SyncStatus.offline:
        return Icon(
          Icons.cloud_off,
          size: 14,
          color: _getStatusColor(),
        );
    }
  }

  Color _getStatusColor() {
    switch (status) {
      case SyncStatus.idle:
        return Colors.grey;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.success:
        return Colors.green;
      case SyncStatus.error:
        return Colors.red;
      case SyncStatus.conflict:
        return Colors.orange;
      case SyncStatus.offline:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (status) {
      case SyncStatus.idle:
        return '已同步';
      case SyncStatus.syncing:
        return '同步中';
      case SyncStatus.success:
        return '成功';
      case SyncStatus.error:
        return '失败';
      case SyncStatus.conflict:
        return '冲突';
      case SyncStatus.offline:
        return '离线';
    }
  }
}

/// Detailed sync status panel
class SyncStatusPanel extends StatelessWidget {
  final SyncStatus status;
  final String? message;
  final double? progress;
  final List<String>? recentFiles;
  final DateTime? lastSyncTime;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;
  final VoidCallback? onViewDetails;

  const SyncStatusPanel({
    Key? key,
    required this.status,
    this.message,
    this.progress,
    this.recentFiles,
    this.lastSyncTime,
    this.onRetry,
    this.onCancel,
    this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SyncStatusWidget(
                  status: status,
                  showDetails: false,
                ),
                const Spacer(),
                if (onRetry != null && status == SyncStatus.error)
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试'),
                  ),
                if (onCancel != null && status == SyncStatus.syncing)
                  TextButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.stop),
                    label: const Text('取消'),
                  ),
              ],
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (progress != null && status == SyncStatus.syncing) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress! * 100).toInt()}% 完成',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (lastSyncTime != null) ...[
              const SizedBox(height: 8),
              Text(
                '上次同步: ${_formatDateTime(lastSyncTime!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
            ],
            if (recentFiles != null && recentFiles!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '最近同步的文件:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              ...recentFiles!.take(3).map((file) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Row(
                  children: [
                    const Icon(Icons.file_copy, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        file,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
              if (recentFiles!.length > 3) ...[
                const SizedBox(height: 4),
                TextButton(
                  onPressed: onViewDetails,
                  child: Text('查看全部 ${recentFiles!.length} 个文件'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} 分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} 小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} 天前';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }
}

/// Sync status enumeration
enum SyncStatus {
  idle,     // Not syncing, up to date
  syncing,  // Currently syncing
  success,  // Last sync was successful
  error,    // Last sync failed
  conflict, // Sync conflicts detected
  offline,  // No network connection
}