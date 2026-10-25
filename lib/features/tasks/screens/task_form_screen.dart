import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../models/task_model.dart';
import '../providers/tasks_provider.dart';

class TaskFormScreen extends StatefulWidget {
  final TaskModel? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late String _status;
  late String _priority;
  late String _assignee;
  DateTime? _due;
  bool _saving = false;
  String? _titleError;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _title = TextEditingController(text: t?.title ?? '');
    _description = TextEditingController(text: t?.description ?? '');
    _status = t?.status ?? 'todo';
    _priority = t?.priority ?? 'medium';
    _assignee = t?.assignedTo ?? '';
    _due = t?.dueDate;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _due = picked);
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _titleError = 'Please enter a title');
      return;
    }
    setState(() {
      _titleError = null;
      _saving = true;
    });

    final task = TaskModel(
      id: widget.task?.id ?? '',
      title: _title.text.trim(),
      description: _description.text.trim(),
      status: _status,
      priority: _priority,
      dueDate: _due,
      assignedTo: _assignee,
      createdBy: widget.task?.createdBy ?? '',
    );

    final error = await context.read<TasksProvider>().save(task, isNew: !_isEdit);
    if (!mounted) return;
    if (error != null) {
      setState(() => _saving = false);
      _toast(error);
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This removes the task for everyone.'),
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
    if (ok != true || !mounted) return;
    final error = await context.read<TasksProvider>().remove(widget.task!.id);
    if (!mounted) return;
    if (error != null) {
      _toast(error);
      return;
    }
    Navigator.pop(context);
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final usernames = context.watch<TasksProvider>().usernames;
    final assignees = <String>{...usernames};
    if (_assignee.isNotEmpty) assignees.add(_assignee);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit task' : 'New task'),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.dangerRed),
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          _label('Title'),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'What needs to be done?',
              errorText: _titleError,
            ),
          ),
          _label('Description'),
          TextField(
            controller: _description,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'Add details (optional)'),
          ),
          _label('Status'),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'todo', label: Text('To do')),
                ButtonSegment(value: 'in_progress', label: Text('In progress')),
                ButtonSegment(value: 'done', label: Text('Done')),
              ],
              selected: {_status},
              onSelectionChanged: (v) => setState(() => _status = v.first),
            ),
          ),
          _label('Priority'),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'low', label: Text('Low')),
                ButtonSegment(value: 'medium', label: Text('Medium')),
                ButtonSegment(value: 'high', label: Text('High')),
              ],
              selected: {_priority},
              onSelectionChanged: (v) => setState(() => _priority = v.first),
            ),
          ),
          _label('Due date'),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.event_outlined),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _due == null
                          ? 'No due date'
                          : DateFormat('EEEE, MMM d, yyyy').format(_due!),
                      style: TextStyle(
                        color: _due == null
                            ? AppTheme.textMuted
                            : AppTheme.textDark,
                      ),
                    ),
                  ),
                  if (_due != null)
                    GestureDetector(
                      onTap: () => setState(() => _due = null),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: AppTheme.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
          _label('Assign to'),
          DropdownButtonFormField<String>(
            value: _assignee,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.person_outline),
            ),
            items: [
              const DropdownMenuItem(value: '', child: Text('Unassigned')),
              for (final name in assignees)
                DropdownMenuItem(value: name, child: Text(name)),
            ],
            onChanged: (v) => setState(() => _assignee = v ?? ''),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_isEdit ? 'Save changes' : 'Create task'),
          ),
        ],
      ),
    );
  }
}
