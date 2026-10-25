class TaskModel {
  final String id;
  final String title;
  final String description;
  final String status; // todo | in_progress | done
  final String priority; // low | medium | high
  final DateTime? dueDate;
  final String assignedTo;
  final String createdBy;

  const TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.status = 'todo',
    this.priority = 'medium',
    this.dueDate,
    this.assignedTo = '',
    this.createdBy = '',
  });

  bool get isDone => status == 'done';

  bool get isOverdue {
    if (isDone || dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dueDate!.isBefore(today);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status,
        'priority': priority,
        'dueDate': dueDate == null
            ? ''
            : DateTime(dueDate!.year, dueDate!.month, dueDate!.day)
                .toIso8601String(),
        'assignedTo': assignedTo,
      };

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    final rawDue = json['dueDate']?.toString() ?? '';
    return TaskModel(
      id: json['id'].toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? 'todo',
      priority: json['priority']?.toString() ?? 'medium',
      dueDate: rawDue.isEmpty ? null : DateTime.tryParse(rawDue),
      assignedTo: json['assignedTo']?.toString() ?? '',
      createdBy: json['createdBy']?.toString() ?? '',
    );
  }

  TaskModel copyWith({
    String? title,
    String? description,
    String? status,
    String? priority,
    DateTime? dueDate,
    bool clearDueDate = false,
    String? assignedTo,
  }) {
    return TaskModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy,
    );
  }
}
