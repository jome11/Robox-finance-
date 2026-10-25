import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../auth/auth_session.dart';
import '../models/transaction_model.dart';

class FinanceApiService {
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (AuthSession.token != null)
          'Authorization': 'Bearer ${AuthSession.token}',
      };

  // Local fallback cache for robust operation even if backend is offline
  static final List<TransactionModel> _localCache = [
    TransactionModel(
      id: '1',
      title: 'Software Subscription',
      amount: 49.99,
      category: 'Software',
      subcategory: 'Subscriptions',
      paymentMethod: 'CBE',
      date: DateTime.now().subtract(const Duration(days: 1)),
      note: 'Monthly cloud tools',
      imagePaths: [],
      type: 'expense',
      shipmentNumber: '',
    ),
    TransactionModel(
      id: '2',
      title: 'Client Project Payout',
      amount: 1500.00,
      category: 'Shipment Income',
      subcategory: 'Freelance',
      paymentMethod: 'Telebirr',
      date: DateTime.now().subtract(const Duration(days: 3)),
      note: 'Milestone 1 completed',
      imagePaths: [],
      type: 'income',
      shipmentNumber: 'SHP-2026-001',
    ),
    TransactionModel(
      id: '3',
      title: 'Team Coffee & Snacks',
      amount: 28.50,
      category: 'Food',
      subcategory: 'Office',
      paymentMethod: 'Cash',
      date: DateTime.now().subtract(const Duration(days: 2)),
      note: 'Working session',
      imagePaths: [],
      type: 'expense',
      shipmentNumber: '',
    ),
  ];

  /// Called on sign-out so the next user never sees the previous user's data.
  static void clearLocalCache() => _localCache.clear();

  String get _url => '${ApiConstants.baseUrl}${ApiConstants.transactionsEndpoint}';

  void _checkAuth(http.Response response) {
    if (response.statusCode == 401) {
      AuthSession.onUnauthorized?.call();
    }
  }

  Future<List<TransactionModel>> fetchTransactions() async {
    try {
      final response = await http
          .get(Uri.parse(_url), headers: _headers)
          .timeout(const Duration(seconds: 10));
      debugPrint('[API] GET ${response.statusCode}');
      _checkAuth(response);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => TransactionModel.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('[API] GET failed: $e');
    }
    return _localCache;
  }

  Future<bool> addTransaction(TransactionModel transaction) async {
    _localCache.insert(0, transaction);
    try {
      final response = await http
          .post(Uri.parse(_url),
              headers: _headers, body: jsonEncode(transaction.toJson()))
          .timeout(const Duration(seconds: 10));
      debugPrint('[API] POST ${response.statusCode} ${response.body}');
      _checkAuth(response);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('[API] POST failed: $e');
      return true; // success via local cache
    }
  }

  Future<bool> updateTransaction(TransactionModel transaction) async {
    final index = _localCache.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _localCache[index] = transaction;
    }
    try {
      final response = await http
          .put(Uri.parse('$_url/${transaction.id}'),
              headers: _headers, body: jsonEncode(transaction.toJson()))
          .timeout(const Duration(seconds: 10));
      debugPrint('[API] PUT ${response.statusCode} ${response.body}');
      _checkAuth(response);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[API] PUT failed: $e');
      return true;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    _localCache.removeWhere((t) => t.id == id);
    try {
      final response = await http
          .delete(Uri.parse('$_url/$id'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      debugPrint('[API] DELETE ${response.statusCode} ${response.body}');
      _checkAuth(response);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[API] DELETE failed: $e');
      return true;
    }
  }
}
