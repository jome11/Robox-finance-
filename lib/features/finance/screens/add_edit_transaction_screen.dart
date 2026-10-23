import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';
import '../../../core/theme/app_theme.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const AddEditTransactionScreen({super.key, this.transaction});

  @override
  State<AddEditTransactionScreen> createState() => _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _title;
  late double _amount;
  late String _category;
  late String _subcategory;
  late String _paymentMethod;
  late DateTime _date;
  late String _note;
  late String _type;
  late List<String> _imagePaths;
  late String _shipmentNumber;

  final ImagePicker _picker = ImagePicker();

  // ---------------------------------------------------------------------------
  // CATEGORIES DEFINITION (General categories only)
  // ---------------------------------------------------------------------------
  final List<String> _categories = [
    'General',
    'Software',
    'Food',
    'Transport',
    'Utilities',
    'Salary',
    'Freelance',
    'Entertainment',
    'Investment',
  ];

  final List<String> _paymentMethods = [
    'Cash',
    'Telebirr',
    'CBE',
    'Other Bank',
  ];

  @override
  void initState() {
    super.initState();
    final t = widget.transaction;
    _title = t?.title ?? '';
    _amount = t?.amount ?? 0.0;
    _category = t?.category ?? _categories.first;
    _subcategory = t?.subcategory ?? '';
    _paymentMethod = t?.paymentMethod ?? _paymentMethods.first;
    _date = t?.date ?? DateTime.now();
    _note = t?.note ?? '';
    _type = t?.type ?? 'expense';
    _imagePaths = List.from(t?.imagePaths ?? []);
    _shipmentNumber = t?.shipmentNumber ?? '';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 85);
      if (pickedFile != null) {
        final compressedPath = await _compressAndSaveImage(pickedFile.path);
        setState(() {
          _imagePaths.add(compressedPath);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e'), backgroundColor: AppTheme.dangerRed),
        );
      }
    }
  }

  Future<String> _compressAndSaveImage(String originalPath) async {
    try {
      final bytes = await File(originalPath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image != null) {
        img.Image resized = img.copyResize(image, width: 1024);
        final compressedBytes = img.encodeJpg(resized, quality: 80);
        
        final tempDir = Directory.systemTemp;
        final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final targetFile = File(targetPath);
        await targetFile.writeAsBytes(compressedBytes);
        return targetPath;
      }
    } catch (_) {}
    return originalPath;
  }

  void _showFullScreenImage(String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: Image.file(File(path)),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final provider = Provider.of<FinanceProvider>(context, listen: false);

      final newTransaction = TransactionModel(
        id: widget.transaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _title,
        amount: _amount,
        category: _category,
        subcategory: _subcategory,
        paymentMethod: _paymentMethod,
        date: _date,
        note: _note,
        imagePaths: _imagePaths,
        type: _type,
        shipmentNumber: _shipmentNumber,
      );

      if (widget.transaction == null) {
        provider.addTransaction(newTransaction);
      } else {
        provider.updateTransaction(newTransaction);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? 'Add Transaction' : 'Edit Transaction'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppTheme.primaryBlue),
            onPressed: _saveForm,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('Expense'), icon: Icon(Icons.arrow_upward)),
                ButtonSegment(value: 'income', label: Text('Income'), icon: Icon(Icons.arrow_downward)),
              ],
              selected: {_type},
              onSelectionChanged: (val) {
                setState(() {
                  _type = val.first;
                });
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: _title,
              decoration: const InputDecoration(labelText: 'Title / Description', prefixIcon: Icon(Icons.title)),
              validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
              onSaved: (value) => _title = value ?? '',
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _amount == 0.0 ? '' : _amount.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount (Br)', prefixIcon: Icon(Icons.money)),
              validator: (value) {
                if (value == null || double.tryParse(value) == null || double.parse(value) <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
              onSaved: (value) => _amount = double.parse(value!),
            ),
            const SizedBox(height: 16),
            // Shipment Number Field
            TextFormField(
              initialValue: _shipmentNumber,
              decoration: const InputDecoration(
                labelText: 'Shipment Number (Optional)',
                prefixIcon: Icon(Icons.local_shipping_outlined),
                hintText: 'e.g. SHP-98234',
              ),
              onSaved: (value) => _shipmentNumber = value ?? '',
            ),
            const SizedBox(height: 16),
            // Smaller Category Selector / Dropdown
            DropdownButtonFormField<String>(
              isDense: true,
              value: _categories.contains(_category) ? _category : _categories.first,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category, size: 20),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: _categories.map((c) => DropdownMenuItem(
                value: c,
                child: Text(c, style: const TextStyle(fontSize: 14)),
              )).toList(),
              onChanged: (val) => setState(() => _category = val ?? _categories.first),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _subcategory,
              decoration: const InputDecoration(labelText: 'Subcategory (Optional)', prefixIcon: Icon(Icons.subdirectory_arrow_right)),
              onSaved: (value) => _subcategory = value ?? '',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isDense: true,
              value: _paymentMethods.contains(_paymentMethod) ? _paymentMethod : _paymentMethods.first,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                prefixIcon: Icon(Icons.payment, size: 20),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              items: _paymentMethods.map((p) => DropdownMenuItem(
                value: p,
                child: Text(p, style: const TextStyle(fontSize: 14)),
              )).toList(),
              onChanged: (val) => setState(() => _paymentMethod = val ?? _paymentMethods.first),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _date = picked);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Date', prefixIcon: Icon(Icons.calendar_today)),
                child: Text(DateFormat('yyyy-MM-dd').format(_date)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _note,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Note (Optional)', prefixIcon: Icon(Icons.note)),
              onSaved: (value) => _note = value ?? '',
            ),
            const SizedBox(height: 24),
            const Text('Image Attachments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_imagePaths.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagePaths.length,
                  itemBuilder: (context, index) {
                    final path = _imagePaths[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 100,
                      height: 100,
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: () => _showFullScreenImage(path),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(path),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _imagePaths.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.dangerRed,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saveForm,
              child: const Text('Save Transaction', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
