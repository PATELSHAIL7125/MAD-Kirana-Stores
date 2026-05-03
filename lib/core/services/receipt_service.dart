import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports for platform-specific PDF operations
import 'receipt_service_platform.dart'
    if (dart.library.html) 'receipt_service_web.dart'
    if (dart.library.io) 'receipt_service_mobile.dart';

class ReceiptService {
  Future<pw.Document> _generatePdfDocument({
    required Map<String, dynamic> businessProfile,
    required Map<String, dynamic> saleData,
  }) async {
    final pdf = pw.Document();
    final items = saleData['items'] as List;
    final totalAmount = (saleData['totalAmount'] ?? 0.0);
    final subtotal = (saleData['subtotal'] ?? totalAmount);
    final totalTax = (saleData['totalTax'] ?? 0.0);
    final upiId = businessProfile['upiId'] ?? "";
    
    // Date formatting
    DateTime dateTime;
    final createdAt = saleData['createdAt'];
    if (createdAt is String) {
      dateTime = DateTime.tryParse(createdAt) ?? DateTime.now();
    } else if (createdAt is DateTime) {
      dateTime = createdAt;
    } else {
      dateTime = DateTime.now();
    }
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    
    final shopName = _safeString(businessProfile['shopName'], "Kirana Store");
    final address = _safeString(businessProfile['address'], "");
    final phone = _safeString(businessProfile['phone'], "");
    final gstNo = _safeString(businessProfile['gstNumber'], "");
    final invoiceNo = _safeString(saleData['invoiceNumber'], 'N/A');

    // Branding Color (Emerald Green)
    const PdfColor emerald = PdfColor.fromInt(0xFF2ECC71);
    const PdfColor darkEmerald = PdfColor.fromInt(0xFF27AE60);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(shopName.toUpperCase(), 
                        style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: emerald)),
                      if (address.isNotEmpty) pw.SizedBox(height: 4),
                      if (address.isNotEmpty) pw.Text(address, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.SizedBox(height: 2),
                      if (phone.isNotEmpty) pw.Text("Phone: $phone", style: const pw.TextStyle(fontSize: 10)),
                      if (gstNo.isNotEmpty) pw.Text("GSTIN: $gstNo", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: const pw.BoxDecoration(color: emerald),
                        child: pw.Text("INVOICE", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 18)),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text("Invoice #: $invoiceNo", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                      pw.Text("Date: $dateStr", style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 40),

              // Items Table
              pw.Table(
                border: null,
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FixedColumnWidth(60),
                  2: const pw.FixedColumnWidth(80),
                  3: const pw.FixedColumnWidth(100),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: emerald),
                    children: [
                      _tableHeader("PRODUCT / ITEM"),
                      _tableHeader("QTY"),
                      _tableHeader("PRICE"),
                      _tableHeader("TOTAL"),
                    ],
                  ),
                  // Table Items
                  ...items.map((item) {
                    final itemName = _safeString(item['name'], 'Unknown');
                    final qty = item['qty'] ?? 0;
                    final price = (item['price'] ?? 0.0);
                    final total = (item['total'] ?? 0.0);
                    return pw.TableRow(
                      decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5))),
                      children: [
                        _tableCell(itemName, align: pw.Alignment.centerLeft),
                        _tableCell("$qty"),
                        _tableCell("Rs. ${price.toStringAsFixed(2)}"),
                        _tableCell("Rs. ${total.toStringAsFixed(2)}", isBold: true),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 30),

              // Summary Section
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left Side: Payment QR
                  if (upiId.isNotEmpty)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("SCAN TO PAY", style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                        pw.SizedBox(height: 8),
                        pw.Container(
                          width: 100,
                          height: 100,
                          child: pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: "upi://pay?pa=$upiId&pn=$shopName&am=${totalAmount.toStringAsFixed(2)}&cu=INR",
                            drawText: false,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text("UPI: $upiId", style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  
                  pw.Spacer(),

                  // Right Side: Totals
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      _summaryRow("Subtotal:", "Rs. ${subtotal.toStringAsFixed(2)}"),
                      if (totalTax > 0) ...[
                        _summaryRow("CGST (9%):", "Rs. ${(totalTax / 2).toStringAsFixed(2)}"),
                        _summaryRow("SGST (9%):", "Rs. ${(totalTax / 2).toStringAsFixed(2)}"),
                        _summaryRow("Total Tax:", "Rs. ${totalTax.toStringAsFixed(2)}"),
                      ],
                      pw.Container(height: 1, width: 200, color: PdfColors.grey400, margin: const pw.EdgeInsets.symmetric(vertical: 8)),
                      pw.Row(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text("GRAND TOTAL: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                          pw.Text("Rs. ${totalAmount.toStringAsFixed(2)}", 
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18, color: darkEmerald)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),

              // Footer
              pw.Divider(color: emerald, thickness: 2),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text("Thank you for choosing $shopName!", 
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: emerald)),
                    pw.SizedBox(height: 4),
                    pw.Text("This is a computer-generated invoice.", style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _tableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: pw.Text(text, style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
    );
  }

  pw.Widget _tableCell(String text, {pw.Alignment align = pw.Alignment.center, bool isBold = false}) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 10, fontWeight: isBold ? pw.FontWeight.bold : null)),
    );
  }

  pw.Widget _summaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.SizedBox(width: 40),
          pw.Container(width: 80, alignment: pw.Alignment.centerRight, child: pw.Text(value, style: const pw.TextStyle(fontSize: 10))),
        ],
      ),
    );
  }

  // Helper method to safely extract string values
  String _safeString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  /// Share/Download the receipt
  /// On web: Downloads the PDF file
  /// On mobile: Opens share dialog
  Future<void> shareReceiptToWhatsApp({
    required Map<String, dynamic> businessProfile,
    required Map<String, dynamic> saleData,
  }) async {
    try {
      final pdf = await _generatePdfDocument(
        businessProfile: businessProfile,
        saleData: saleData,
      );
      
      final bytes = await pdf.save();
      final filename = 'receipt_${saleData['invoiceNumber'] ?? DateTime.now().millisecondsSinceEpoch}.pdf';
      
      await sharePdfPlatform(bytes, filename);
    } catch (e) {
      print('Error sharing PDF: $e');
      rethrow;
    }
  }

  /// Print the receipt
  Future<void> printReceipt({
    required Map<String, dynamic> businessProfile,
    required Map<String, dynamic> saleData,
  }) async {
    try {
      final pdf = await _generatePdfDocument(
        businessProfile: businessProfile,
        saleData: saleData,
      );
      
      final bytes = await pdf.save();
      await printPdfPlatform(bytes);
    } catch (e) {
      print('Error printing PDF: $e');
      rethrow;
    }
  }
}
