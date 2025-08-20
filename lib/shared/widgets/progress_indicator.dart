import 'package:flutter/material.dart';

/// Custom linear progress indicator with label
class CustomLinearProgressIndicator extends StatelessWidget {
  final double? value;
  final String? label;
  final String? description;
  final Color? backgroundColor;
  final Color? valueColor;
  final double height;
  final bool showPercentage;
  
  const CustomLinearProgressIndicator({
    super.key,
    this.value,
    this.label,
    this.description,
    this.backgroundColor,
    this.valueColor,
    this.height = 8.0,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null || (showPercentage && value != null)) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null)
                Text(
                  label!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              if (showPercentage && value != null)
                Text(
                  '${(value! * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: SizedBox(
            height: height,
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: backgroundColor ?? 
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                valueColor ?? Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(
            description!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }
}

/// Custom circular progress indicator with label
class CustomCircularProgressIndicator extends StatelessWidget {
  final double? value;
  final String? label;
  final double size;
  final double strokeWidth;
  final Color? backgroundColor;
  final Color? valueColor;
  final bool showPercentage;
  
  const CustomCircularProgressIndicator({
    super.key,
    this.value,
    this.label,
    this.size = 48.0,
    this.strokeWidth = 4.0,
    this.backgroundColor,
    this.valueColor,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: strokeWidth,
                backgroundColor: backgroundColor ?? 
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  valueColor ?? Theme.of(context).colorScheme.primary,
                ),
              ),
              if (showPercentage && value != null)
                Text(
                  '${(value! * 100).toInt()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 8),
          Text(
            label!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Step progress indicator for multi-step processes
class StepProgressIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String>? stepLabels;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? completedColor;
  final double lineHeight;
  final double circleRadius;
  
  const StepProgressIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.stepLabels,
    this.activeColor,
    this.inactiveColor,
    this.completedColor,
    this.lineHeight = 2.0,
    this.circleRadius = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCol = activeColor ?? theme.colorScheme.primary;
    final inactiveCol = inactiveColor ?? theme.colorScheme.outline;
    final completedCol = completedColor ?? theme.colorScheme.primary;

    return Column(
      children: [
        Row(
          children: List.generate(totalSteps, (index) {
            final isActive = index == currentStep;
            final isCompleted = index < currentStep;
            final isLast = index == totalSteps - 1;

            Color circleColor;
            Color textColor;
            if (isCompleted) {
              circleColor = completedCol;
              textColor = theme.colorScheme.onPrimary;
            } else if (isActive) {
              circleColor = activeCol;
              textColor = theme.colorScheme.onPrimary;
            } else {
              circleColor = inactiveCol;
              textColor = theme.colorScheme.onSurface;
            }

            return Expanded(
              child: Row(
                children: [
                  Container(
                    width: circleRadius * 2,
                    height: circleRadius * 2,
                    decoration: BoxDecoration(
                      color: circleColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isCompleted
                          ? Icon(
                              Icons.check,
                              size: circleRadius,
                              color: textColor,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: circleRadius * 0.7,
                              ),
                            ),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        height: lineHeight,
                        color: isCompleted ? completedCol : inactiveCol,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
        if (stepLabels != null) ...[
          const SizedBox(height: 8),
          Row(
            children: List.generate(totalSteps, (index) {
              final isActive = index == currentStep;
              final isCompleted = index < currentStep;
              
              return Expanded(
                child: Text(
                  stepLabels![index],
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: (isActive || isCompleted) 
                        ? FontWeight.bold 
                        : FontWeight.normal,
                    color: (isActive || isCompleted)
                        ? theme.colorScheme.primary
                        : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

/// Upload/Download progress widget
class FileProgressWidget extends StatelessWidget {
  final String fileName;
  final double progress;
  final String? status;
  final VoidCallback? onCancel;
  final bool isCompleted;
  final bool hasError;
  final String? errorMessage;
  
  const FileProgressWidget({
    super.key,
    required this.fileName,
    required this.progress,
    this.status,
    this.onCancel,
    this.isCompleted = false,
    this.hasError = false,
    this.errorMessage,
  });

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
                Icon(
                  isCompleted
                      ? Icons.check_circle
                      : hasError
                          ? Icons.error
                          : Icons.file_copy,
                  color: isCompleted
                      ? Colors.green
                      : hasError
                          ? Colors.red
                          : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fileName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (onCancel != null && !isCompleted && !hasError)
                  IconButton(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (!hasError) ...[
              CustomLinearProgressIndicator(
                value: isCompleted ? 1.0 : progress,
                height: 6,
                showPercentage: false,
              ),
              if (status != null) ...[
                const SizedBox(height: 4),
                Text(
                  status!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ] else ...[
              Text(
                errorMessage ?? '操作失败',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}