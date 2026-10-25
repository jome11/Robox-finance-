import 'package:flutter/foundation.dart';
import '../models/transaction_model.dart';
import '../services/excel_export_service.dart';
import '../services/finance_api_service.dart';

class FinanceProvider with ChangeNotifier {
  final FinanceApiService _apiService = FinanceApiService();

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  bool _exporting = false;
  String _selectedPeriod = 'Month'; // 'Week', 'Month', 'Year'

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isExporting => _exporting;
  String get selectedPeriod => _selectedPeriod;

  double get totalIncome {
    return _transactions
        .where((t) => t.type.toLowerCase() == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalExpenses {
    return _transactions
        .where((t) => t.type.toLowerCase() == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get netBalance => totalIncome - totalExpenses;

  // Shipment-specific transactions and metrics
  List<TransactionModel> get shipmentTransactions {
    return _transactions.where((t) => t.shipmentNumber.trim().isNotEmpty).toList();
  }

  double get shipmentIncome {
    return shipmentTransactions
        .where((t) => t.type.toLowerCase() == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get shipmentExpenses {
    return shipmentTransactions
        .where((t) => t.type.toLowerCase() == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get shipmentNetBalance => shipmentIncome - shipmentExpenses;

  Map<String, List<TransactionModel>> get shipmentsMap {
    final Map<String, List<TransactionModel>> map = {};
    for (var t in shipmentTransactions) {
      final sId = t.shipmentNumber.trim();
      if (!map.containsKey(sId)) {
        map[sId] = [];
      }
      map[sId]!.add(t);
    }
    return map;
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    notifyListeners();

    _transactions = await _apiService.fetchTransactions();
    _isLoading = false;
    notifyListeners();
  }

  void setPeriod(String period) {
    _selectedPeriod = period;
    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    _isLoading = true;
    notifyListeners();

    await _apiService.addTransaction(transaction);
    _transactions = await _apiService.fetchTransactions();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    _isLoading = true;
    notifyListeners();

    await _apiService.updateTransaction(transaction);
    _transactions = await _apiService.fetchTransactions();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    _isLoading = true;
    notifyListeners();

    await _apiService.deleteTransaction(id);
    _transactions = await _apiService.fetchTransactions();

    _isLoading = false;
    notifyListeners();
  }

  Map<String, double> getExpensesByCategory() {
    final Map<String, double> map = {};
    for (var t in _transactions.where((t) => t.type.toLowerCase() == 'expense')) {
      map[t.category] = (map[t.category] ?? 0.0) + t.amount;
    }
    return map;
  }

  // Correctly group data differently for Week, Month, and Year
  Map<String, double> getGroupedChartData() {
    final Map<String, double> grouped = {};

    for (var t in filteredTransactions) {
      String key;
      if (_selectedPeriod == 'Week') {
        // Week: group by individual day (MM/DD) over the last 7 days
        key = '${t.date.month}/${t.date.day}';
      } else if (_selectedPeriod == 'Month') {
        // Month: group by week of the month (Week 1, Week 2, Week 3, Week 4, Week 5)
        int weekNumber = ((t.date.day - 1) ~/ 7) + 1;
        key = 'Week $weekNumber';
      } else {
        // Year: group by Month name
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        key = months[t.date.month - 1];
      }
      grouped[key] = (grouped[key] ?? 0.0) + t.amount;
    }

    if (_selectedPeriod == 'Year') {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final Map<String, double> sortedMap = {};
      for (var m in months) {
        if (grouped.containsKey(m)) {
          sortedMap[m] = grouped[m]!;
        }
      }
      for (var k in grouped.keys) {
        if (!sortedMap.containsKey(k)) {
          sortedMap[k] = grouped[k]!;
        }
      }
      return sortedMap;
    }

    final sortedKeys = grouped.keys.toList()..sort();
    final Map<String, double> sortedMap = {};
    for (var k in sortedKeys) {
      sortedMap[k] = grouped[k]!;
    }
    return sortedMap;
  }

  List<TransactionModel> get filteredTransactions {
    final now = DateTime.now();
    return _transactions.where((t) {
      if (_selectedPeriod == 'Week') {
        return now.difference(t.date).inDays <= 7 && t.date.isBefore(now.add(const Duration(days: 1)));
      } else if (_selectedPeriod == 'Month') {
        return t.date.year == now.year && t.date.month == now.month;
      } else if (_selectedPeriod == 'Year') {
        return t.date.year == now.year;
      }
      return true;
    }).toList();
  }

  /// Builds an Excel file (with photos) and opens the share / save sheet.
  /// Returns a message to show the user.
  Future<String?> exportToExcel({bool includePhotos = true}) async {
    if (_exporting) return 'An export is already running. Please wait.';
    _exporting = true;
    notifyListeners();
    try {
      return await ExcelExportService.export(
        _transactions,
        includePhotos: includePhotos,
      );
    } catch (e) {
      debugPrint('[EXPORT] failed: $e');
      return 'Export failed: $e';
    } finally {
      _exporting = false;
      notifyListeners();
    }
  }
}
