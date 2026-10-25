import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/attachment_widgets.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final TransactionModel? transaction;

  const AddEditTransactionScreen({super.key, this.transaction});

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
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
  late List<String> _attachments;
  late String _shipmentNumber;
  bool _photoBusy = false;

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

  final List<String> _paymentMethods = ['Cash', 'Telebirr', 'CBE', 'Other Bank'];

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
    _attachments = List.from(t?.imagePaths ?? []);
    _shipmentNumber = t?.shipmentNumber ?? '';
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

  void _saveForm() {
    if (_photoBusy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for the photo to finish uploading')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    final provider = Provider.of<FinanceProvider>(context, listen: false);

    final transaction = TransactionModel(
      id: widget.transaction?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _title,
      amount: _amount,
      category: _category,
      subcategory: _subcategory,
      paymentMethod: _paymentMethod,
      date: _date,
      note: _note,
      imagePaths: _attachments,
      type: _type,
      shipmentNumber: _shipmentNumber,
    );

    if (widget.transaction == null) {
      provider.addTransaction(transaction);
    } else {
      provider.updateTransaction(transaction);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.transaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit transaction' : 'New transaction'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(
                    value: 'expense',
                    label: Text('Expense'),
                    icon: Icon(Icons.north_east),
                  ),
                  ButtonSegment(
                    value: 'income',
                    label: Text('Income'),
                    icon: Icon(Icons.south_west),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (v) => setState(() => _type = v.first),
              ),
            ),
            _label('Details'),
            TextFormField(
              initialValue: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Title / description',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Please enter a title' : null,
              onSaved: (v) => _title = v?.trim() ?? '',
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: _amount == 0.0 ? '' : _amount.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (Br)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (v) {
                if (v == null || double.tryParse(v) == null || double.parse(v) <= 0) {
                  return 'Please enter a valid amount';
                }
                return null;
              },
              onSaved: (v) => _amount = double.parse(v!),
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: _shipmentNumber,
              decoration: const InputDecoration(
                labelText: 'Shipment number (optional)',
                prefixIcon: Icon(Icons.local_shipping_outlined),
                hintText: 'e.g. SHP-98234',
              ),
              onSaved: (v) => _shipmentNumber = v?.trim() ?? '',
            ),
            _label('Classification'),
            DropdownButtonFormField<String>(
              value: _categories.contains(_category) ? _category : _categories.first,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _categories.first),
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: _subcategory,
              decoration: const InputDecoration(
                labelText: 'Subcategory (optional)',
                prefixIcon: Icon(Icons.subdirectory_arrow_right),
              ),
              onSaved: (v) => _subcategory = v?.trim() ?? '',
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _paymentMethods.contains(_paymentMethod)
                  ? _paymentMethod
                  : _paymentMethods.first,
              decoration: const InputDecoration(
                labelText: 'Payment method',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
              items: _paymentMethods
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _paymentMethod = v ?? _paymentMethods.first),
            ),
            const SizedBox(height: 14),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.event_outlined),
                ),
                child: Text(DateFormat('EEEE, MMM d, yyyy').format(_date)),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: _note,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                prefixIcon: Icon(Icons.notes),
              ),
              onSaved: (v) => _note = v?.trim() ?? '',
            ),
            _label('Photos'),
            AttachmentPicker(
              references: _attachments,
              onChanged: (list) => setState(() => _attachments = list),
              onBusyChanged: (busy) => setState(() => _photoBusy = busy),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _photoBusy ? null : _saveForm,
              child: Text(_photoBusy ? 'Uploading photo...' : 'Save transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
