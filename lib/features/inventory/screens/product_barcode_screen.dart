import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ProductBarcodeScreen extends StatelessWidget {
  final String productName;
  final String barcode;
  final int sellingPriceCents;

  const ProductBarcodeScreen({
    super.key,
    required this.productName,
    required this.barcode,
    required this.sellingPriceCents,
  });

  Future<void> _printBarcode(BuildContext context) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(50 * PdfPageFormat.mm, 30 * PdfPageFormat.mm),
        margin: const pw.EdgeInsets.all(4),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Text(productName, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text('Rs ${(sellingPriceCents / 100).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 4),
              pw.BarcodeWidget(
                barcode: pw.Barcode.code128(),
                data: barcode,
                width: 130,
                height: 50,
                drawText: true,
              ),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    try {
      await Printing.layoutPdf(onLayout: (_) async => bytes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Print Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Product Barcode'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                productName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Rs ${(sellingPriceCents / 100).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, color: Color(0xFFD6A51D), fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              // Clean white barcode card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 16)],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: BarcodeWidget(
                  barcode: Barcode.code128(),
                  data: barcode,
                  width: 250,
                  height: 100,
                  drawText: true,
                  style: const TextStyle(color: Colors.black, fontSize: 12),
                  color: Colors.black,
                  backgroundColor: Colors.white,
                  errorBuilder: (context, error) => Center(child: Text(error)),
                ),
              ),
              const SizedBox(height: 16),
              Text(barcode, style: const TextStyle(color: Colors.black54, letterSpacing: 2)),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => _printBarcode(context),
                icon: const Icon(Icons.print),
                label: const Text('Print Barcode Label'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD6A51D),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
