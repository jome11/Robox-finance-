import 'dart:math' as math;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xio;
import '../models/transaction_model.dart';
import 'image_api_service.dart';

class ExcelExportService {
  /// Most photos shown per transaction (each gets its own column).
  static const int _maxPhotoColumns = 4;

  static const String _xlsxMime =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  /// Downloads one photo. Excel (XlsIO) only supports JPEG and PNG.
  static Future<Uint8List?> _download(String ref) async {
    try {
      final res = await http
          .get(
            Uri.parse(ImageApiService.urlFor(ref)),
            headers: ImageApiService.authHeaders,
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) return null;
      final type = res.headers['content-type'] ?? '';
      if (!type.contains('jpeg') && !type.contains('png')) return null;
      return res.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  static void _text(
    xio.Worksheet sheet,
    int row,
    int col,
    String value,
    xio.Style style,
  ) {
    final cell = sheet.getRangeByIndex(row, col);
    cell.setText(value);
    cell.cellStyle = style;
  }

  /// Builds the workbook and opens the share / save sheet.
  /// Returns a short message for the user.
  static Future<String> export(
    List<TransactionModel> transactions, {
    bool includePhotos = true,
  }) async {
    final rows = [...transactions]..sort((a, b) => b.date.compareTo(a.date));

    // ---- 1. Download the photos (4 at a time) ----
    final photos = <String, Uint8List>{};
    var legacy = 0; // old photos that only existed on one phone
    var failed = 0;

    if (includePhotos) {
      final wanted = <String>{};
      for (final t in rows) {
        for (final ref in t.imagePaths.take(_maxPhotoColumns)) {
          if (ImageApiService.isRemote(ref)) {
            wanted.add(ref);
          } else {
            legacy++;
          }
        }
      }
      final list = wanted.toList();
      for (var i = 0; i < list.length; i += 4) {
        final batch = list.skip(i).take(4).toList();
        final results = await Future.wait(batch.map(_download));
        for (var j = 0; j < batch.length; j++) {
          final bytes = results[j];
          if (bytes == null) {
            failed++;
          } else {
            photos[batch[j]] = bytes;
          }
        }
      }
    }

    final perRow = <String, List<Uint8List>>{};
    var maxPhotos = 0;
    var embedded = 0;
    for (final t in rows) {
      final list = <Uint8List>[
        for (final ref in t.imagePaths.take(_maxPhotoColumns))
          if (photos[ref] != null) photos[ref]!,
      ];
      perRow[t.id] = list;
      maxPhotos = math.max(maxPhotos, list.length);
      embedded += list.length;
    }

    // ---- 2. Build the workbook ----
    final workbook = xio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Transactions';

    final header = workbook.styles.add('header');
    header.backColor = '#2563EB';
    header.fontColor = '#FFFFFF';
    header.bold = true;
    header.hAlign = xio.HAlignType.center;
    header.vAlign = xio.VAlignType.center;

    final text = workbook.styles.add('text');
    text.vAlign = xio.VAlignType.center;
    text.wrapText = true;

    final dateStyle = workbook.styles.add('date');
    dateStyle.vAlign = xio.VAlignType.center;
    dateStyle.numberFormat = 'yyyy-mm-dd hh:mm';

    final incomeStyle = workbook.styles.add('income');
    incomeStyle.fontColor = '#059669';
    incomeStyle.bold = true;
    incomeStyle.vAlign = xio.VAlignType.center;
    incomeStyle.numberFormat = '#,##0.00';

    final expenseStyle = workbook.styles.add('expense');
    expenseStyle.fontColor = '#E11D48';
    expenseStyle.bold = true;
    expenseStyle.vAlign = xio.VAlignType.center;
    expenseStyle.numberFormat = '#,##0.00';

    final totalLabel = workbook.styles.add('totalLabel');
    totalLabel.bold = true;
    totalLabel.hAlign = xio.HAlignType.right;

    final totalValue = workbook.styles.add('totalValue');
    totalValue.bold = true;
    totalValue.numberFormat = '#,##0.00';

    const headers = [
      'Date',
      'Title',
      'Type',
      'Amount (Br)',
      'Category',
      'Subcategory',
      'Payment method',
      'Shipment',
      'Note',
    ];
    const widths = [18.0, 30.0, 10.0, 15.0, 16.0, 16.0, 16.0, 16.0, 32.0];

    for (var c = 0; c < headers.length; c++) {
      _text(sheet, 1, c + 1, headers[c], header);
      sheet.getRangeByIndex(1, c + 1).columnWidth = widths[c];
    }
    final photoStart = headers.length + 1;
    for (var p = 0; p < maxPhotos; p++) {
      _text(sheet, 1, photoStart + p, 'Photo ${p + 1}', header);
      sheet.getRangeByIndex(1, photoStart + p).columnWidth = 14;
    }
    sheet.getRangeByIndex(1, 1).rowHeight = 24;

    var r = 2;
    double income = 0;
    double expense = 0;

    for (final t in rows) {
      final isIncome = t.type.toLowerCase() == 'income';
      if (isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
      }

      final dateCell = sheet.getRangeByIndex(r, 1);
      dateCell.setDateTime(t.date);
      dateCell.cellStyle = dateStyle;

      _text(sheet, r, 2, t.title, text);
      _text(sheet, r, 3, isIncome ? 'Income' : 'Expense', text);

      final amountCell = sheet.getRangeByIndex(r, 4);
      amountCell.setNumber(t.amount);
      amountCell.cellStyle = isIncome ? incomeStyle : expenseStyle;

      _text(sheet, r, 5, t.category, text);
      _text(sheet, r, 6, t.subcategory, text);
      _text(sheet, r, 7, t.paymentMethod, text);
      _text(sheet, r, 8, t.shipmentNumber, text);
      _text(sheet, r, 9, t.note, text);

      final pics = perRow[t.id] ?? const <Uint8List>[];
      if (pics.isNotEmpty) {
        sheet.getRangeByIndex(r, 1).rowHeight = 68;
        for (var i = 0; i < pics.length; i++) {
          final pic = sheet.pictures.addStream(r, photoStart + i, pics[i]);
          pic.width = 84;
          pic.height = 84;
        }
      }
      r++;
    }

    // Totals
    r++;
    _text(sheet, r, 3, 'Total income', totalLabel);
    final incomeTotal = sheet.getRangeByIndex(r, 4);
    incomeTotal.setNumber(income);
    incomeTotal.cellStyle = totalValue;
    r++;
    _text(sheet, r, 3, 'Total expenses', totalLabel);
    final expenseTotal = sheet.getRangeByIndex(r, 4);
    expenseTotal.setNumber(expense);
    expenseTotal.cellStyle = totalValue;
    r++;
    _text(sheet, r, 3, 'Net', totalLabel);
    final netTotal = sheet.getRangeByIndex(r, 4);
    netTotal.setNumber(income - expense);
    netTotal.cellStyle = totalValue;

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    // ---- 3. Save / share ----
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final fileName = 'robox_transactions_$stamp.xlsx';

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(bytes),
            mimeType: _xlsxMime,
            name: fileName,
          ),
        ],
        fileNameOverrides: [fileName],
        subject: fileName,
      ),
    );

    var message = 'Excel file ready: ${rows.length} records';
    if (includePhotos) message += ', $embedded photos';
    if (legacy > 0) {
      message += '. $legacy older photos were never uploaded, so they are not included';
    }
    if (failed > 0) {
      message += '. $failed photos could not be added (unsupported format or network)';
    }
    return message;
  }
}
