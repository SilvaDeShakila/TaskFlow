enum TaskPriority { high, medium, low }

class Task {
  final String id;
  String title;
  String description;
  bool isCompleted;
  final DateTime createdAt;
  TaskPriority priority;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.isCompleted = false,
    required this.createdAt,
    this.priority = TaskPriority.medium,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'priority': priority.name,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    final priorityName = json['priority'] as String?;

    final savedPriority = TaskPriority.values.where(
      (item) => item.name == priorityName,
    );

    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      priority: savedPriority.isNotEmpty
          ? savedPriority.first
          : TaskPriority.medium,
    );
  }
}
