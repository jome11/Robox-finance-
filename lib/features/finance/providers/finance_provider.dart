import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import '../models/transaction_model.dart';
import '../services/finance_api_service.dart';

class FinanceProvider with ChangeNotifier {
  final FinanceApiService _apiService = FinanceApiService();

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String _selectedPeriod = 'Month'; // 'Week', 'Month', 'Year'

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
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

  // Shipment-specific transactions grouped by shipment ID (shipment number), ordered as entered
  List<TransactionModel> get shipmentTransactions {
    return _transactions.where((t) => t.shipmentNumber.trim().isNotEmpty).toList();
  }

  Map<String, List<TransactionModel>> get shipmentsMap {
    final Map<String, List<TransactionModel>> map = {};
    // Transactions are already in entry order (newest or oldest)
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

  Map<String, double> getGroupedChartData() {
    final Map<String, double> grouped = {};

    for (var t in filteredTransactions) {
      String key;
      if (_selectedPeriod == 'Week') {
        key = '${t.date.month}/${t.date.day}';
      } else if (_selectedPeriod == 'Month') {
        key = '${t.date.month}/${t.date.day}';
      } else {
        key = 'M${t.date.month}';
      }
      grouped[key] = (grouped[key] ?? 0.0) + t.amount;
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
        return now.difference(t.date).inDays <= 7;
      } else if (_selectedPeriod == 'Month') {
        return t.date.year == now.year && t.date.month == now.month;
      } else if (_selectedPeriod == 'Year') {
        return t.date.year == now.year;
      }
      return true;
    }).toList();
  }

  Future<String?> exportToExcel() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Transactions'];
      excel.setDefaultSheet('Transactions');

      sheetObject.appendRow([
        TextCellValue('ID'),
        TextCellValue('Title'),
        TextCellValue('Type'),
        TextCellValue('Amount'),
        TextCellValue('Category'),
        TextCellValue('Subcategory'),
        TextCellValue('Payment Method'),
        TextCellValue('Shipment Number'),
        TextCellValue('Date'),
        TextCellValue('Note'),
      ]);

      for (var t in _transactions) {
        sheetObject.appendRow([
          TextCellValue(t.id),
          TextCellValue(t.title),
          TextCellValue(t.type),
          DoubleCellValue(t.amount),
          TextCellValue(t.category),
          TextCellValue(t.subcategory),
          TextCellValue(t.paymentMethod),
          TextCellValue(t.shipmentNumber),
          TextCellValue(t.date.toIso8601String()),
          TextCellValue(t.note),
        ]);
      }

      final fileBytes = excel.save();
      if (fileBytes != null) {
        return 'Excel export generated successfully (${_transactions.length} records)';
      }
    } catch (_) {}
    return null;
  }
}
