import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../auth/auth_session.dart';
import '../models/task_model.dart';

class TaskApiException implements Exception {
  final String message;
  TaskApiException(this.message);

  @override
  String toString() => message;
}

class TaskApiService {
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (AuthSession.token != null)
          'Authorization': 'Bearer ${AuthSession.token}',
      };

  Uri _uri(String path) => Uri.parse('${ApiConstants.baseUrl}$path');

  Future<http.Response> _run(Future<http.Response> Function() call) async {
    try {
      final res = await call().timeout(const Duration(seconds: 15));
      if (res.statusCode == 401) {
        AuthSession.onUnauthorized?.call();
      }
      if (res.statusCode >= 400) {
        var message = 'Request failed (${res.statusCode})';
        try {
          final detail = jsonDecode(res.body)['detail'];
          if (detail is String) message = detail;
        } catch (_) {}
        throw TaskApiException(message);
      }
      return res;
    } on TaskApiException {
      rethrow;
    } catch (_) {
      throw TaskApiException('Cannot reach the server. Check your connection.');
    }
  }

  Future<List<TaskModel>> fetchTasks() async {
    final res = await _run(
      () => http.get(_uri(ApiConstants.tasksEndpoint), headers: _headers),
    );
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((e) => TaskModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> fetchUsernames() async {
    final res = await _run(
      () => http.get(_uri(ApiConstants.directoryEndpoint), headers: _headers),
    );
    final data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => (e as Map<String, dynamic>)['username'].toString()).toList();
  }

  Future<void> createTask(TaskModel task) async {
    await _run(
      () => http.post(
        _uri(ApiConstants.tasksEndpoint),
        headers: _headers,
        body: jsonEncode(task.toJson()),
      ),
    );
  }

  Future<void> updateTask(TaskModel task) async {
    await _run(
      () => http.put(
        _uri('${ApiConstants.tasksEndpoint}/${task.id}'),
        headers: _headers,
        body: jsonEncode(task.toJson()),
      ),
    );
  }

  Future<void> deleteTask(String id) async {
    await _run(
      () => http.delete(
        _uri('${ApiConstants.tasksEndpoint}/$id'),
        headers: _headers,
      ),
    );
  }
}
