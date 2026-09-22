import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class ZReportPdfService {
  static final _currencyFmt = NumberFormat.currency(symbol: '', decimalDigits: 2);

  static Future<File> generateZReport({
    required DateTime shiftStart,
    required DateTime shiftEnd,
    required int startingCashCents,
    required int totalSalesCents,
    required int cashSalesCents,
    required int totalCostCents,
    required int expensesCents,
    required int creditReceivedCents, // if any
  }) async {
    final pdf = pw.Document();
    final expectedCashCents = startingCashCents + cashSalesCents + creditReceivedCents - expensesCents;
    final grossProfitCents = totalSalesCents - totalCostCents;
    final netProfitCents = grossProfitCents - expensesCents;
    final formatter = DateFormat('dd-MM-yyyy hh:mm a');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(12),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text('Z-REPORT (DAY END)', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Start: ${formatter.format(shiftStart)}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('End:   ${formatter.format(shiftEnd)}', style: const pw.TextStyle(fontSize: 10)),
              pw.Divider(),
              
              // Cash Drawer Summary
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('CASH DRAWER', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 4),
              _buildRow('Starting Balance', startingCashCents),
              _buildRow('(+) Cash Sales', cashSalesCents),
              _buildRow('(+) Credit Paid In', creditReceivedCents),
              _buildRow('(-) Expenses Paid', expensesCents),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              _buildRow('Expected Cash', expectedCashCents, isBold: true),
              
              pw.Divider(),

              // Business Performance
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('BUSINESS PERFORMANCE', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 4),
              _buildRow('Total Sales', totalSalesCents),
              _buildRow('Total Cost', totalCostCents),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              _buildRow('Gross Profit', grossProfitCents, isBold: true),
              _buildRow('Less Expenses', expensesCents),
              pw.Divider(borderStyle: pw.BorderStyle.dashed),
              _buildRow('Net Profit', netProfitCents, isBold: true),

              pw.SizedBox(height: 16),
              pw.Text('--- END OF REPORT ---', style: const pw.TextStyle(fontSize: 10)),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/z_report_${shiftEnd.millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildRow(String label, int amountCents, {bool isBold = false}) {
    final style = pw.TextStyle(fontSize: 11, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal);
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text('Rs ${_currencyFmt.format(amountCents / 100)}', style: style),
      ],
    );
  }

  static Future<void> shareReport(File file) async {
    await Share.shareXFiles([XFile(file.path)], text: 'Day End Z-Report');
  }
}
