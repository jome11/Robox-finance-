import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../services/task_api_service.dart';

class TasksProvider with ChangeNotifier {
  final TaskApiService _api = TaskApiService();

  List<TaskModel> _tasks = [];
  List<String> _usernames = [];
  bool _loading = false;
  String? _error;

  List<TaskModel> get tasks => _tasks;
  List<String> get usernames => _usernames;
  bool get isLoading => _loading;
  String? get error => _error;

  List<TaskModel> get openTasks => sorted(_tasks.where((t) => !t.isDone));

  int get overdueCount => _tasks.where((t) => t.isOverdue).length;

  /// Due date first (no date last), then higher priority first.
  List<TaskModel> sorted(Iterable<TaskModel> items) {
    final list = items.toList();
    list.sort((a, b) {
      if (a.dueDate == null && b.dueDate != null) return 1;
      if (a.dueDate != null && b.dueDate == null) return -1;
      if (a.dueDate != null && b.dueDate != null) {
        final c = a.dueDate!.compareTo(b.dueDate!);
        if (c != 0) return c;
      }
      return _weight(b.priority).compareTo(_weight(a.priority));
    });
    return list;
  }

  static int _weight(String p) => p == 'high' ? 3 : (p == 'medium' ? 2 : 1);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _tasks = await _api.fetchTasks();
    } on TaskApiException catch (e) {
      _error = e.message;
    }
    try {
      _usernames = await _api.fetchUsernames();
    } on TaskApiException catch (_) {}
    _loading = false;
    notifyListeners();
  }

  /// Returns an error message, or null on success.
  Future<String?> save(TaskModel task, {required bool isNew}) async {
    try {
      if (isNew) {
        await _api.createTask(task);
      } else {
        await _api.updateTask(task);
      }
      _tasks = await _api.fetchTasks();
      _error = null;
      notifyListeners();
      return null;
    } on TaskApiException catch (e) {
      return e.message;
    }
  }

  /// Optimistic status change; reverts and returns a message on failure.
  Future<String?> setStatus(TaskModel task, String status) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return null;
    final previous = _tasks[index];
    final updated = previous.copyWith(status: status);
    _tasks[index] = updated;
    notifyListeners();
    try {
      await _api.updateTask(updated);
      return null;
    } on TaskApiException catch (e) {
      final i = _tasks.indexWhere((t) => t.id == task.id);
      if (i != -1) _tasks[i] = previous;
      notifyListeners();
      return e.message;
    }
  }

  Future<String?> remove(String id) async {
    try {
      await _api.deleteTask(id);
      _tasks.removeWhere((t) => t.id == id);
      notifyListeners();
      return null;
    } on TaskApiException catch (e) {
      return e.message;
    }
  }
}
