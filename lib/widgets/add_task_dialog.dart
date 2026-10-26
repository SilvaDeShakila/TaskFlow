import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/task.dart';

class AddTaskDialog extends StatefulWidget {
  final Task? task;

  const AddTaskDialog({
    super.key,
    this.task,
  });

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late TaskPriority _selectedPriority;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.task?.title ?? '',
    );

    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );

    _selectedPriority = widget.task?.priority ?? TaskPriority.medium;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return AppTheme.dangerColor;
      case TaskPriority.medium:
        return const Color(0xFFB87516);
      case TaskPriority.low:
        return AppTheme.successColor;
    }
  }

  Color _priorityBackground(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const Color(0xFFFFECEE);
      case TaskPriority.medium:
        return AppTheme.softOrange;
      case TaskPriority.low:
        return AppTheme.softGreen;
    }
  }

  String _priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  IconData _priorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Icons.keyboard_double_arrow_up_rounded;
      case TaskPriority.medium:
        return Icons.drag_handle_rounded;
      case TaskPriority.low:
        return Icons.keyboard_double_arrow_down_rounded;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      Task(
        id: widget.task?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        isCompleted: widget.task?.isCompleted ?? false,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
        priority: _selectedPriority,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = screenWidth >= 700 ? 460.0 : screenWidth * 0.92;

    return AlertDialog(
      backgroundColor: AppTheme.cardColor,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      contentPadding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 18, 8),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
      title: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.softPurple,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _isEditing
                  ? Icons.edit_note_rounded
                  : Icons.add_task_rounded,
              color: AppTheme.primaryColor,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Edit task' : 'Create a task',
                  style: const TextStyle(
                    color: AppTheme.textColor,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isEditing
                      ? 'Update your task details'
                      : 'Add something to your plan',
                  style: const TextStyle(
                    color: AppTheme.mutedColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'TASK DETAILS',
                  style: TextStyle(
                    color: AppTheme.mutedColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _titleController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Task title',
                    hintText: 'What do you need to do?',
                    prefixIcon: Icon(Icons.edit_outlined),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a task title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  minLines: 3,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText: 'Add some helpful details...',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 39),
                      child: Icon(Icons.notes_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'PRIORITY LEVEL',
                  style: TextStyle(
                    color: AppTheme.mutedColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: TaskPriority.values.map((priority) {
                    final selected = _selectedPriority == priority;
                    final color = _priorityColor(priority);
                    final background = _priorityBackground(priority);

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: priority == TaskPriority.low ? 0 : 8,
                        ),
                        child: Semantics(
                          button: true,
                          selected: selected,
                          label: '${_priorityLabel(priority)} priority',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              setState(() {
                                _selectedPriority = priority;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                vertical: 13,
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? background
                                    : AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? color
                                      : AppTheme.borderColor,
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    _priorityIcon(priority),
                                    color: color,
                                    size: 23,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _priorityLabel(priority),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? color
                                          : AppTheme.mutedColor,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  AnimatedContainer(
                                    duration: const Duration(
                                      milliseconds: 180,
                                    ),
                                    width: selected ? 16 : 5,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? color
                                          : AppTheme.borderColor,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _submit,
          icon: Icon(
            _isEditing ? Icons.check_rounded : Icons.add_rounded,
            size: 18,
          ),
          label: Text(_isEditing ? 'Save changes' : 'Add task'),
        ),
      ],
    );
  }
}
