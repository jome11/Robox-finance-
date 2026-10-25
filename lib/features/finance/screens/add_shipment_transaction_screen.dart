import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/attachment_widgets.dart';
import '../models/transaction_model.dart';
import '../providers/finance_provider.dart';

class AddShipmentTransactionScreen extends StatefulWidget {
  const AddShipmentTransactionScreen({super.key});

  @override
  State<AddShipmentTransactionScreen> createState() =>
      _AddShipmentTransactionScreenState();
}

class _AddShipmentTransactionScreenState
    extends State<AddShipmentTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  String _shipmentNumber = '';
  String _title = '';
  double _amount = 0.0;
  String _type = 'expense';
  String _paymentMethod = 'Telebirr';
  DateTime _date = DateTime.now();
  String _note = '';
  List<String> _attachments = [];
  bool _photoBusy = false;

  final List<String> _paymentMethods = ['Telebirr', 'CBE', 'Other Bank', 'Cash'];

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

    provider.addTransaction(
      TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _title,
        amount: _amount,
        category: _type == 'income' ? 'Shipment Income' : 'Shipment Expense',
        subcategory: 'Shipment',
        paymentMethod: _paymentMethod,
        date: _date,
        note: _note,
        imagePaths: _attachments,
        type: _type,
        shipmentNumber: _shipmentNumber.trim(),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New shipment transaction')),
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
            _label('Shipment'),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Shipment number / ID',
                prefixIcon: Icon(Icons.local_shipping_outlined),
                hintText: 'e.g. SHP-2026-001',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Please enter a shipment number'
                  : null,
              onSaved: (v) => _shipmentNumber = v ?? '',
            ),
            _label('Details'),
            TextFormField(
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
            DropdownButtonFormField<String>(
              value: _paymentMethod,
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
              child: Text(
                _photoBusy ? 'Uploading photo...' : 'Save shipment transaction',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
