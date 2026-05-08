import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/expense_model.dart';
import '../models/currency_model.dart';

class PdfReportGenerator {
  static Future<File> generateAndShare({
    required String userName,
    required String currency,
    required DateTime startDate,
    required DateTime endDate,
    required double totalExpense,
    required double totalIncome,
    required Map<String, double> expenseCategoryTotals,
    required Map<String, double> incomeCategoryTotals,
    required List<ExpenseModel> transactions,
    double? budget,
  }) async {
    final pdf = pw.Document();
    final currencyInfo = AppCurrencies.getByCode(currency);
    final symbol = currencyInfo.symbol;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final netBalance = totalIncome - totalExpense;

    const primaryColor = PdfColor.fromInt(0xFF6366F1);
    const greenColor = PdfColor.fromInt(0xFF10B981);
    const redColor = PdfColor.fromInt(0xFFEF4444);
    const headerBg = PdfColor.fromInt(0xFF1E293B);
    const cardBg = PdfColor.fromInt(0xFFF8FAFC);
    const borderColor = PdfColor.fromInt(0xFFE2E8F0);

    String fmtCur(double amount) {
      return '$symbol${NumberFormat('#,##0.00').format(amount)}';
    }

    final periodLabel = '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildPageHeader(userName, periodLabel, dateFormat, primaryColor),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 16),
          child: pw.Text('FinFlow Report  |  Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        ),
        build: (context) {
          final widgets = <pw.Widget>[];

          // ── Summary Table ──
          widgets.add(pw.SizedBox(height: 8));
          widgets.add(pw.Table(
            border: pw.TableBorder.all(color: borderColor, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: headerBg),
                children: ['Total Income', 'Total Expense', 'Net Balance'].map((h) =>
                  pw.Padding(padding: const pw.EdgeInsets.all(10),
                    child: pw.Text(h, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                      textAlign: pw.TextAlign.center))).toList(),
              ),
              pw.TableRow(children: [
                pw.Padding(padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(fmtCur(totalIncome), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: greenColor),
                    textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(10),
                  child: pw.Text(fmtCur(totalExpense), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: redColor),
                    textAlign: pw.TextAlign.center)),
                pw.Padding(padding: const pw.EdgeInsets.all(10),
                  child: pw.Text('${netBalance >= 0 ? '+' : ''}${fmtCur(netBalance.abs())}',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: netBalance >= 0 ? greenColor : redColor),
                    textAlign: pw.TextAlign.center)),
              ]),
            ],
          ));

          if (budget != null && budget > 0) {
            final remaining = (budget - totalExpense).clamp(0.0, double.infinity);
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(color: cardBg, border: pw.Border.all(color: borderColor)),
              child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                pw.Text('Monthly Budget: ${fmtCur(budget)}', style: const pw.TextStyle(fontSize: 10)),
                pw.Text('Remaining: ${fmtCur(remaining)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold,
                  color: remaining > 0 ? greenColor : redColor)),
              ]),
            ));
          }

          // ── Expense Category Breakdown ──
          if (expenseCategoryTotals.isNotEmpty) {
            widgets.add(pw.SizedBox(height: 20));
            widgets.add(pw.Text('EXPENSE BREAKDOWN', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700, letterSpacing: 1)));
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(_buildCategoryTable(expenseCategoryTotals, totalExpense, symbol, redColor, headerBg, borderColor));
          }

          // ── Income Category Breakdown ──
          if (incomeCategoryTotals.isNotEmpty) {
            widgets.add(pw.SizedBox(height: 20));
            widgets.add(pw.Text('INCOME BREAKDOWN', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700, letterSpacing: 1)));
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(_buildCategoryTable(incomeCategoryTotals, totalIncome, symbol, greenColor, headerBg, borderColor));
          }

          // ── All Transactions ──
          if (transactions.isNotEmpty) {
            widgets.add(pw.SizedBox(height: 20));
            widgets.add(pw.Text('ALL TRANSACTIONS (${transactions.length})', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700, letterSpacing: 1)));
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(_buildTransactionTable(transactions, symbol, greenColor, redColor, headerBg, borderColor));
          }

          return widgets;
        },
      ),
    );

    // Save to temp directory
    final output = await getTemporaryDirectory();
    final fileName = 'FinFlow_Report_${DateFormat('yyyyMMdd').format(startDate)}_to_${DateFormat('yyyyMMdd').format(endDate)}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    // Share the file
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'FinFlow Financial Report',
    );

    return file;
  }

  static pw.Widget _buildPageHeader(String userName, String period, DateFormat fmt, PdfColor accent) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0), width: 1))),
      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('FinFlow', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: accent)),
          pw.Text('Financial Report', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text(userName, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Text(period, style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
          pw.SizedBox(height: 2),
          pw.Text('Generated: ${fmt.format(DateTime.now())}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey400)),
        ]),
      ]),
    );
  }

  static pw.Widget _buildCategoryTable(Map<String, double> totals, double grandTotal, String symbol, PdfColor accentColor, PdfColor headerBg, PdfColor borderColor) {
    final formatter = NumberFormat('#,##0.00');
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(3),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerBg),
          children: ['Category', 'Amount', '%', 'Bar'].map((h) =>
            pw.Padding(padding: const pw.EdgeInsets.all(8),
              child: pw.Text(h, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)))).toList(),
        ),
        ...totals.entries.toList().asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final pct = grandTotal > 0 ? e.value / grandTotal : 0.0;
          final bg = i % 2 == 0 ? PdfColors.white : const PdfColor.fromInt(0xFFF8FAFC);
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(6),
                child: pw.Text(e.key, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
              pw.Padding(padding: const pw.EdgeInsets.all(6),
                child: pw.Text('$symbol${formatter.format(e.value)}', style: const pw.TextStyle(fontSize: 9))),
              pw.Padding(padding: const pw.EdgeInsets.all(6),
                child: pw.Text('${(pct * 100).toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 9))),
              pw.Padding(padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                child: pw.ClipRRect(horizontalRadius: 3, verticalRadius: 3,
                  child: pw.LinearProgressIndicator(value: pct, minHeight: 8,
                    backgroundColor: PdfColors.grey200, valueColor: accentColor))),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTransactionTable(List<ExpenseModel> transactions, String symbol, PdfColor greenColor, PdfColor redColor, PdfColor headerBg, PdfColor borderColor) {
    final formatter = NumberFormat('#,##0.00');
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(1.8),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerBg),
          children: ['Title', 'Category', 'Type', 'Date', 'Amount'].map((h) =>
            pw.Padding(padding: const pw.EdgeInsets.all(8),
              child: pw.Text(h, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white)))).toList(),
        ),
        ...transactions.asMap().entries.map((entry) {
          final i = entry.key;
          final e = entry.value;
          final bg = i % 2 == 0 ? PdfColors.white : const PdfColor.fromInt(0xFFF8FAFC);
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(6),
                child: pw.Text(e.title, style: const pw.TextStyle(fontSize: 8), maxLines: 1)),
              pw.Padding(padding: const pw.EdgeInsets.all(6),
                child: pw.Text(e.category, style: const pw.TextStyle(fontSize: 8), maxLines: 1)),
              pw.Padding(padding: const pw.EdgeInsets.all(6),
                child: pw.Text(e.isIncome ? 'IN' : 'OUT', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold,
                  color: e.isIncome ? greenColor : redColor))),
              pw.Padding(padding: const pw.EdgeInsets.all(6),
                child: pw.Text(DateFormat('MMM dd').format(e.date), style: const pw.TextStyle(fontSize: 8))),
              pw.Padding(padding: const pw.EdgeInsets.all(6),
                child: pw.Text('${e.isIncome ? '+' : '-'}$symbol${formatter.format(e.amount)}',
                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold,
                    color: e.isIncome ? greenColor : redColor))),
            ],
          );
        }),
      ],
    );
  }
}
