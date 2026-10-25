import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/task_model.dart';
import '../providers/tasks_provider.dart';
import 'task_form_screen.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  static const _filters = ['Open', 'To do', 'In progress', 'Done'];

  String _filter = 'Open';
  bool _mineOnly = false;

  bool _matches(TaskModel t) {
    switch (_filter) {
      case 'To do':
        return t.status == 'todo';
      case 'In progress':
        return t.status == 'in_progress';
      case 'Done':
        return t.isDone;
      default:
        return !t.isDone;
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirmDelete(TaskModel task) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('"${task.title}" will be removed for everyone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.dangerRed),
            ),
          ),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TasksProvider>();
    final me = (context.watch<AuthProvider>().user?.username ?? '').toLowerCase();

    var filtered = tasks.tasks.where(_matches);
    if (_mineOnly) {
      filtered = filtered.where((t) => t.assignedTo.toLowerCase() == me);
    }
    final items = tasks.sorted(filtered);
    final openCount = tasks.tasks.where((t) => !t.isDone).length;

    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tasks',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  '$openCount open • ${tasks.overdueCount} overdue',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final f in _filters)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(f),
                            selected: _filter == f,
                            showCheckmark: false,
                            labelStyle: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _filter == f
                                  ? AppTheme.primaryBlue
                                  : AppTheme.textMuted,
                            ),
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                        ),
                      FilterChip(
                        avatar: const Icon(Icons.person_outline, size: 16),
                        label: const Text('Mine'),
                        selected: _mineOnly,
                        showCheckmark: false,
                        onSelected: (v) => setState(() => _mineOnly = v),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (tasks.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: AppCard(
                color: AppTheme.dangerRed.withValues(alpha: 0.08),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTheme.dangerRed),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tasks.error!,
                        style: const TextStyle(
                          color: AppTheme.dangerRed,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => tasks.load(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => tasks.load(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 110),
                children: items.isEmpty
                    ? [
                        if (tasks.isLoading)
                          const Padding(
                            padding: EdgeInsets.only(top: 60),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          EmptyState(
                            icon: Icons.checklist,
                            title: 'No tasks here',
                            message: _filter == 'Done'
                                ? 'Completed tasks will show up here.'
                                : 'Tap New task to add one.',
                          ),
                      ]
                    : [
                        for (final task in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Dismissible(
                              key: ValueKey(task.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.dangerRed.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.dangerRed,
                                ),
                              ),
                              confirmDismiss: (_) async {
                                if (await _confirmDelete(task) && mounted) {
                                  final error = await context
                                      .read<TasksProvider>()
                                      .remove(task.id);
                                  if (error != null) _toast(error);
                                }
                                return false;
                              },
                              child: _TaskCard(
                                task: task,
                                onToggle: () async {
                                  final error = await tasks.setStatus(
                                    task,
                                    task.isDone ? 'todo' : 'done',
                                  );
                                  if (error != null) _toast(error);
                                },
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TaskFormScreen(task: task),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onTap,
  });

  Color get _priorityColor {
    switch (task.priority) {
      case 'high':
        return AppTheme.dangerRed;
      case 'medium':
        return AppTheme.warning;
      default:
        return AppTheme.textMuted;
    }
  }

  String get _priorityLabel =>
      task.priority[0].toUpperCase() + task.priority.substring(1);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                task.isDone
                    ? Icons.check_circle
                    : (task.status == 'in_progress'
                        ? Icons.timelapse
                        : Icons.radio_button_unchecked),
                color: task.isDone ? AppTheme.successGreen : AppTheme.primaryBlue,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    decoration: task.isDone ? TextDecoration.lineThrough : null,
                    color: task.isDone ? AppTheme.textMuted : AppTheme.textDark,
                  ),
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Pill(
                      label: _priorityLabel,
                      color: _priorityColor,
                      icon: Icons.flag_outlined,
                    ),
                    if (task.dueDate != null)
                      Pill(
                        label: task.isOverdue
                            ? 'Overdue • ${Fmt.shortDate(task.dueDate!)}'
                            : Fmt.shortDate(task.dueDate!),
                        color: task.isOverdue
                            ? AppTheme.dangerRed
                            : AppTheme.textMuted,
                        icon: Icons.event_outlined,
                      ),
                    if (task.assignedTo.isNotEmpty)
                      Pill(
                        label: task.assignedTo,
                        color: AppTheme.primaryBlue,
                        icon: Icons.person_outline,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
