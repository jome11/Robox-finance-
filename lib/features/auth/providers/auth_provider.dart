import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../finance/services/finance_api_service.dart';
import '../auth_session.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class UserModel {
  final String id;
  final String email;
  final String username;
  final String role;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'].toString(),
        email: (json['email'] ?? json['username'] ?? '').toString(),
        username: (json['username'] ?? json['email'] ?? '').toString(),
        role: json['role'].toString(),
      );
}

class AuthProvider with ChangeNotifier {
  static const _tokenKey = 'auth_token';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  bool _busy = false;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  bool get busy => _busy;
  String? get error => _error;

  AuthProvider() {
    AuthSession.onUnauthorized = _handleUnauthorized;
  }

  Uri _uri(String path) => Uri.parse('${ApiConstants.baseUrl}$path');

  /// Restores a saved session on app start.
  Future<void> init() async {
    try {
      final saved = await _storage.read(key: _tokenKey);
      if (saved == null) {
        _status = AuthStatus.unauthenticated;
      } else {
        final res = await http
            .get(_uri(ApiConstants.meEndpoint),
                headers: {'Authorization': 'Bearer $saved'})
            .timeout(const Duration(seconds: 15));
        if (res.statusCode == 200) {
          AuthSession.token = saved;
          _user = UserModel.fromJson(jsonDecode(res.body));
          _status = AuthStatus.authenticated;
        } else {
          if (res.statusCode == 401) await _storage.delete(key: _tokenKey);
          _status = AuthStatus.unauthenticated;
        }
      }
    } catch (e) {
      debugPrint('[AUTH] init failed: $e');
      _error = 'Cannot reach the server. Check your connection.';
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final res = await http
          .post(
            _uri(ApiConstants.loginEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 20));
      debugPrint('[AUTH] login ${res.statusCode}');

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final token = data['token'] as String;
        await _storage.write(key: _tokenKey, value: token);
        AuthSession.token = token;
        _user = UserModel.fromJson(data['user']);
        _status = AuthStatus.authenticated;
        _busy = false;
        notifyListeners();
        return true;
      }

      String message = 'Login failed. Please try again.';
      try {
        final detail = jsonDecode(res.body)['detail'];
        if (detail is String) message = detail;
      } catch (_) {}
      _error = message;
    } catch (e) {
      debugPrint('[AUTH] login failed: $e');
      _error = 'Cannot reach the server. Check your connection.';
    }
    _busy = false;
    notifyListeners();
    return false;
  }

  Future<bool> signup(String email, String password) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final res = await http
          .post(
            _uri(ApiConstants.signupEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'username': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 20));
      debugPrint('[AUTH] signup ${res.statusCode}');

      if (res.statusCode == 200 || res.statusCode == 201) {
        _busy = false;
        notifyListeners();
        return await login(email, password);
      }

      String message = 'Signup failed. Please try again.';
      try {
        final detail = jsonDecode(res.body)['detail'];
        if (detail is String) message = detail;
      } catch (_) {}
      _error = message;
    } catch (e) {
      debugPrint('[AUTH] signup failed: $e');
      _error = 'Cannot reach the server. Check your connection.';
    }
    _busy = false;
    notifyListeners();
    return false;
  }

  Future<void> logout({String? message}) async {
    AuthSession.token = null;
    FinanceApiService.clearLocalCache();
    try {
      await _storage.delete(key: _tokenKey);
    } catch (_) {}
    _user = null;
    _error = message;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void _handleUnauthorized() {
    if (_status == AuthStatus.authenticated) {
      logout(message: 'Session expired. Please sign in again.');
    }
  }
}
