import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/task.dart';

class TaskTile extends StatelessWidget {
  final Task task;
  final ValueChanged<bool?> onCompletionChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.onCompletionChanged,
    required this.onEdit,
    required this.onDelete,
  });

  Color get _priorityColor {
    switch (task.priority) {
      case TaskPriority.high:
        return const Color(0xFFD94F5C);
      case TaskPriority.medium:
        return const Color(0xFFB87516);
      case TaskPriority.low:
        return AppTheme.successColor;
    }
  }

  Color get _priorityBackground {
    switch (task.priority) {
      case TaskPriority.high:
        return const Color(0xFFFFECEE);
      case TaskPriority.medium:
        return AppTheme.softOrange;
      case TaskPriority.low:
        return AppTheme.softGreen;
    }
  }

  String get _priorityLabel {
    switch (task.priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  IconData get _priorityIcon {
    switch (task.priority) {
      case TaskPriority.high:
        return Icons.keyboard_double_arrow_up_rounded;
      case TaskPriority.medium:
        return Icons.drag_handle_rounded;
      case TaskPriority.low:
        return Icons.keyboard_double_arrow_down_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = task.isCompleted;

    return Card(
      elevation: 0,
      color: AppTheme.cardColor,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: completed
              ? AppTheme.successColor.withValues(alpha: 0.28)
              : AppTheme.borderColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 4, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Checkbox(
                value: completed,
                onChanged: onCompletionChanged,
                activeColor: AppTheme.successColor,
                semanticLabel: 'Mark ${task.title} as completed',
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _buildBadge(
                          label: _priorityLabel,
                          color: _priorityColor,
                          background: _priorityBackground,
                          icon: _priorityIcon,
                        ),
                        if (completed)
                          _buildBadge(
                            label: 'Completed',
                            color: AppTheme.successColor,
                            background: AppTheme.softGreen,
                            icon: Icons.check_circle_rounded,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      task.title,
                      softWrap: true,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                        color: completed
                            ? AppTheme.mutedColor
                            : AppTheme.textColor,
                        decoration: completed
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    if (task.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        task.description,
                        softWrap: true,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.55,
                          color: AppTheme.mutedColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: completed
                            ? AppTheme.softGreen
                            : AppTheme.softPurple,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            completed
                                ? Icons.check_circle_outline_rounded
                                : Icons.schedule_rounded,
                            size: 15,
                            color: completed
                                ? AppTheme.successColor
                                : AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            completed ? 'Completed' : 'In progress',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: completed
                                  ? AppTheme.successColor
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Task options',
              padding: EdgeInsets.zero,
              iconSize: 22,
              icon: const Icon(
                Icons.more_horiz_rounded,
                color: AppTheme.mutedColor,
              ),
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 19,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 10),
                      Text('Edit task'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 19,
                        color: AppTheme.dangerColor,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Delete task',
                        style: TextStyle(
                          color: AppTheme.dangerColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required Color background,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
