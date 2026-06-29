import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:personal_wallet/features/expenses/domain/models/transaction.dart';
import 'package:personal_wallet/shared/localization/app_localizations.dart';

class ExportService {
  // Share file helper
  static Future<void> _shareFile(String filePath, String subject) async {
    final file = XFile(filePath);
    await Share.shareXFiles([file], subject: subject);
  }

  // Export to CSV
  static Future<String> exportToCSV(List<Transaction> transactions, AppLocalizations l10n) async {
    final List<List<dynamic>> rows = [];
    
    // Headers
    rows.add([
      l10n.translate('type'),
      l10n.translate('amount'),
      l10n.translate('category'),
      l10n.translate('description'),
      'Date',
      'Time',
      'Created At'
    ]);

    for (var tx in transactions) {
      final isDeposit = tx.type == 'deposit';
      final prefix = isDeposit ? '+' : '-';
      final typeText = isDeposit ? l10n.translate('deposit') : l10n.translate('expense');

      rows.add([
        typeText,
        '$prefix${tx.amount.toStringAsFixed(2)}',
        l10n.getCategoryTranslation(tx.category),
        tx.description,
        tx.date,
        tx.time,
        tx.createdAt.toIso8601String(),
      ]);
    }

    final csvContent = const ListToCsvConverter().convert(rows);
    
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/wallet_report_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvContent);

    await _shareFile(file.path, 'Wallet Transactions Report (CSV)');
    return file.path;
  }

  // Export to Excel
  static Future<String> exportToExcel(List<Transaction> transactions, AppLocalizations l10n) async {
    var excel = Excel.createExcel();
    var sheet = excel['Transactions'];
    
    excel.link('Transactions', sheet);
    excel.setDefaultSheet('Transactions');
    
    CellStyle headerStyle = CellStyle(
      bold: true,
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      backgroundColorHex: ExcelColor.fromHexString('#0D9488'), // Teal 600
    );

    // Headers
    sheet.appendRow([
      TextCellValue(l10n.translate('type')),
      TextCellValue(l10n.translate('amount')),
      TextCellValue(l10n.translate('category')),
      TextCellValue(l10n.translate('description')),
      TextCellValue('Date'),
      TextCellValue('Time'),
      TextCellValue('Created At')
    ]);

    // Apply header style
    for (int i = 0; i < 7; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.cellStyle = headerStyle;
    }

    for (var tx in transactions) {
      final isDeposit = tx.type == 'deposit';
      final prefix = isDeposit ? '+' : '-';
      final typeText = isDeposit ? l10n.translate('deposit') : l10n.translate('expense');

      sheet.appendRow([
        TextCellValue(typeText),
        TextCellValue('$prefix${tx.amount.toStringAsFixed(2)}'),
        TextCellValue(l10n.getCategoryTranslation(tx.category)),
        TextCellValue(tx.description),
        TextCellValue(tx.date),
        TextCellValue(tx.time),
        TextCellValue(tx.createdAt.toIso8601String()),
      ]);
    }

    final fileBytes = excel.encode();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/wallet_report_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
      await _shareFile(file.path, 'Wallet Transactions Report (Excel)');
    }
    
    return file.path;
  }

  // Export to PDF
  static Future<String> exportToPDF(List<Transaction> transactions, AppLocalizations l10n) async {
    final pdf = pw.Document();

    double totalDeposits = transactions.where((t) => t.type == 'deposit').fold(0.0, (sum, item) => sum + item.amount);
    double totalExpenses = transactions.where((t) => t.type == 'expense').fold(0.0, (sum, item) => sum + item.amount);
    double balance = totalDeposits - totalExpenses;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Personal Wallet - Money Manager Report', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.Text(DateTime.now().toIso8601String().substring(0, 10), style: const pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Deposits: +${totalDeposits.toStringAsFixed(2)} EGP', style: pw.TextStyle(fontSize: 12, color: PdfColors.green700)),
                pw.Text('Expenses: -${totalExpenses.toStringAsFixed(2)} EGP', style: pw.TextStyle(fontSize: 12, color: PdfColors.red700)),
                pw.Text('Balance: ${balance.toStringAsFixed(2)} EGP', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.teal700),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Type', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Amount (EGP)', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Category', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Description', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Date', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                // Rows
                ...transactions.map((tx) {
                  final isDeposit = tx.type == 'deposit';
                  final sign = isDeposit ? '+' : '-';
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(isDeposit ? 'Deposit' : 'Expense', style: pw.TextStyle(color: isDeposit ? PdfColors.green700 : PdfColors.red700, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$sign${tx.amount.toStringAsFixed(2)}', style: pw.TextStyle(color: isDeposit ? PdfColors.green700 : PdfColors.red700))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(tx.category)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(tx.description)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${tx.date} ${tx.time}')),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/wallet_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    await _shareFile(file.path, 'Wallet Transactions Report (PDF)');
    return file.path;
  }
}
