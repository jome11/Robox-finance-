import 'dart:convert';

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final String category;
  final String subcategory;
  final String paymentMethod;
  final DateTime date;
  final String note;
  final List<String> imagePaths;
  final String type; // 'income' or 'expense'
  final String shipmentNumber; // Shipment tracking number for shipment expenses/income
  final String deletedAt;
  final String deletedBy;
  bool get isDeleted => deletedAt.isNotEmpty;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.subcategory,
    required this.paymentMethod,
    required this.date,
    required this.note,
    required this.imagePaths,
    required this.type,
    required this.shipmentNumber,
    this.deletedAt = '',
    this.deletedBy = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'subcategory': subcategory,
      'paymentMethod': paymentMethod,
      'date': date.toIso8601String(),
      'note': note,
      'imagePaths': jsonEncode(imagePaths),
      'type': type,
      'shipmentNumber': shipmentNumber,
      'deletedAt': deletedAt,
      'deletedBy': deletedBy,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedImages = [];
    if (json['imagePaths'] != null) {
      if (json['imagePaths'] is String) {
        try {
          final decoded = jsonDecode(json['imagePaths']);
          if (decoded is List) {
            parsedImages = decoded.map((e) => e.toString()).toList();
          }
        } catch (_) {
          parsedImages = [json['imagePaths'].toString()];
        }
      } else if (json['imagePaths'] is List) {
        parsedImages = (json['imagePaths'] as List).map((e) => e.toString()).toList();
      }
    }

    return TransactionModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title']?.toString() ?? '',
      amount: (json['amount'] != null) ? double.tryParse(json['amount'].toString()) ?? 0.0 : 0.0,
      category: json['category']?.toString() ?? 'General',
      subcategory: json['subcategory']?.toString() ?? '',
      paymentMethod: json['paymentMethod']?.toString() ?? 'Cash',
      date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now() : DateTime.now(),
      note: json['note']?.toString() ?? '',
      imagePaths: parsedImages,
      type: json['type']?.toString() ?? 'expense',
      shipmentNumber: json['shipmentNumber']?.toString() ?? '',
      deletedAt: json['deletedAt']?.toString() ?? '',
      deletedBy: json['deletedBy']?.toString() ?? '',
    );
  }

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    String? category,
    String? subcategory,
    String? paymentMethod,
    DateTime? date,
    String? note,
    List<String>? imagePaths,
    String? type,
    String? shipmentNumber,
    String? deletedAt,
    String? deletedBy,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      note: note ?? this.note,
      imagePaths: imagePaths ?? this.imagePaths,
      type: type ?? this.type,
      shipmentNumber: shipmentNumber ?? this.shipmentNumber,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
    );
  }
}
