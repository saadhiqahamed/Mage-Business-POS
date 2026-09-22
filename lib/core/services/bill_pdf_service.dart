import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/sales_provider.dart';

class BillPdfService {
  static final _currencyFmt = NumberFormat('#,##0.00', 'en_US');

  static Future<File> generateReceipt({
    required String saleId,
    required List<CartItem> items,
    required int totalCents,
    required int receivedAmountCents, // New parameter for Received amount
    required String paymentMethod,
    String? customerName,
    int rewardPointsRedeemed = 0,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final businessName = prefs.getString('business_name') ?? 'LEEZA ENTERPRISE';
    final businessPhone = prefs.getString('business_phone') ?? '0758600747';
    final businessAddress = prefs.getString('business_address') ?? 'No. 13 Adhanamaluwa Road\nAsgiriya, Kandy';
    final businessType = prefs.getString('business_type') ?? 'CAFE';

    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy').format(now);
    final timeStr = DateFormat('hh:mm a').format(now);

    // Calculate subtotal and discounts
    final subtotalCents = items.fold<int>(0, (sum, i) => sum + (i.price * i.quantity));
    final discountCents = (subtotalCents - totalCents).abs(); // any discount including points

    // Calculate change
    int changeCents = 0;
    if (paymentMethod.toLowerCase() == 'cash' && receivedAmountCents > totalCents) {
      changeCents = receivedAmountCents - totalCents;
    }

    final double fontSize = 9;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 10),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              pw.Center(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(businessName.toUpperCase(), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    if (businessType.isNotEmpty) pw.Text(businessType.toUpperCase(), style: pw.TextStyle(fontSize: fontSize)),
                    pw.Text('Tel: $businessPhone', style: pw.TextStyle(fontSize: fontSize)),
                    pw.Text(businessAddress, style: pw.TextStyle(fontSize: fontSize), textAlign: pw.TextAlign.center),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 6),
              pw.Center(child: pw.Text('=' * 45, style: pw.TextStyle(fontSize: fontSize))),
              pw.SizedBox(height: 6),

              // â”€â”€ Sale Info â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date: $dateStr', style: pw.TextStyle(fontSize: fontSize)),
                  pw.Text('Time: $timeStr', style: pw.TextStyle(fontSize: fontSize)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Text('Bill No: INV-${saleId.substring(0, 6).toUpperCase()}', style: pw.TextStyle(fontSize: fontSize)),
              if (customerName != null && customerName.isNotEmpty)
                pw.Text('Customer: $customerName', style: pw.TextStyle(fontSize: fontSize)),

              pw.SizedBox(height: 6),
              pw.Center(child: pw.Text('-' * 45, style: pw.TextStyle(fontSize: fontSize))),
              
              // â”€â”€ Column Headers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              pw.Row(
                children: [
                  pw.Expanded(flex: 4, child: pw.Text('ITEM', style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold))),
                  pw.Expanded(flex: 1, child: pw.Text('QTY', style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center)),
                  pw.Expanded(flex: 2, child: pw.Text('PRICE', style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                  pw.Expanded(flex: 2, child: pw.Text('TOTAL', style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.right)),
                ],
              ),
              pw.Center(child: pw.Text('-' * 45, style: pw.TextStyle(fontSize: fontSize))),
              
              // â”€â”€ Line Items â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              ...items.map((item) {
                final unitPrice = item.price / 100;
                final itemTotal = (item.price * item.quantity) / 100;
                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 4, child: pw.Text(item.name, style: pw.TextStyle(fontSize: fontSize))),
                      pw.Expanded(flex: 1, child: pw.Text(item.quantity.toString(), style: pw.TextStyle(fontSize: fontSize), textAlign: pw.TextAlign.center)),
                      pw.Expanded(flex: 2, child: pw.Text(_currencyFmt.format(unitPrice), style: pw.TextStyle(fontSize: fontSize), textAlign: pw.TextAlign.right)),
                      pw.Expanded(flex: 2, child: pw.Text(_currencyFmt.format(itemTotal), style: pw.TextStyle(fontSize: fontSize), textAlign: pw.TextAlign.right)),
                    ],
                  ),
                );
              }),
              
              pw.Center(child: pw.Text('-' * 45, style: pw.TextStyle(fontSize: fontSize))),
              
              // â”€â”€ Subtotals â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text('Subtotal  ', style: pw.TextStyle(fontSize: fontSize)),
                  pw.Container(
                    width: 60,
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(_currencyFmt.format(subtotalCents / 100), style: pw.TextStyle(fontSize: fontSize)),
                  ),
                ],
              ),
              
              if (discountCents > 0)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('Discount  ', style: pw.TextStyle(fontSize: fontSize)),
                    pw.Container(
                      width: 60,
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(_currencyFmt.format(discountCents / 100), style: pw.TextStyle(fontSize: fontSize)),
                    ),
                  ],
                ),

              pw.Center(child: pw.Text('-' * 45, style: pw.TextStyle(fontSize: fontSize))),
              
              // â”€â”€ Final Total â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('TOTAL', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Rs. ${_currencyFmt.format(totalCents / 100)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              
              pw.SizedBox(height: 6),
              
              // â”€â”€ Payment Details â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              pw.Text('Payment: ${paymentMethod.toUpperCase()}', style: pw.TextStyle(fontSize: fontSize)),
              if (paymentMethod.toLowerCase() == 'cash') ...[
                pw.Row(
                  children: [
                    pw.Text('Received: ', style: pw.TextStyle(fontSize: fontSize)),
                    pw.Text('Rs. ${_currencyFmt.format(receivedAmountCents / 100)}', style: pw.TextStyle(fontSize: fontSize)),
                  ],
                ),
                pw.Row(
                  children: [
                    pw.Text('Change:     ', style: pw.TextStyle(fontSize: fontSize)),
                    pw.Text('Rs. ${_currencyFmt.format(changeCents / 100)}', style: pw.TextStyle(fontSize: fontSize)),
                  ],
                ),
              ],
              
              pw.SizedBox(height: 6),
              pw.Center(child: pw.Text('=' * 45, style: pw.TextStyle(fontSize: fontSize))),
              pw.SizedBox(height: 8),

              // â”€â”€ Footer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              pw.Center(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Thank You!', style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Please Visit Again', style: pw.TextStyle(fontSize: fontSize)),
                    pw.SizedBox(height: 12),
                    pw.Text('Powered by', style: pw.TextStyle(fontSize: 8)),
                    pw.Text('MAGE BUSINESS 0758600747', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/receipt_${saleId.substring(0, 6)}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<void> shareReceipt(File pdfFile) async {
    final prefs = await SharedPreferences.getInstance();
    final businessName = prefs.getString('business_name') ?? 'Mage Business';
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      subject: '$businessName - Receipt',
      text: 'Here is your receipt from $businessName. Thank you!',
    );
  }
}

