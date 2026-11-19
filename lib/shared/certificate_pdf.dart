import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

const _deepBlue = PdfColor.fromInt(0xFF16105B);
const _purple = PdfColor.fromInt(0xFF47416F);
const _yellow = PdfColor.fromInt(0xFFFCC931);
const _canvas = PdfColor.fromInt(0xFFF7F5FF);
const _muted = PdfColor.fromInt(0xFF6B6880);

/// Builds the certificate as a landscape A4 PDF that matches the on-screen
/// design: deep-blue frame, yellow inner border, logo, name, course,
/// facts and a QR code that opens the public verification page.
Future<Uint8List> buildCertificatePdf({
  required String learnerName,
  required String courseTitle,
  required String date,
  required String certificateId,
  required String trainer,
  required String verifyUrl,
  String? score,
}) async {
  pw.MemoryImage? logo;
  try {
    final data = await rootBundle.load('assets/images/logo_mt_alchemy.jpeg');
    logo = pw.MemoryImage(data.buffer.asUint8List());
  } catch (_) {}

  pw.Widget fact(String label, String value) => pw.Column(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _muted)),
      pw.SizedBox(height: 4),
      pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: _deepBlue,
        ),
      ),
    ],
  );

  final doc = pw.Document(
    title: 'Certificate $certificateId',
    author: 'MT Alchemy',
  );
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(24),
      build: (context) => pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: _deepBlue,
          borderRadius: pw.BorderRadius.circular(16),
        ),
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 28),
          decoration: pw.BoxDecoration(
            color: _canvas,
            borderRadius: pw.BorderRadius.circular(10),
            border: pw.Border.all(color: _yellow, width: 3),
          ),
          child: pw.Column(
            children: [
              if (logo != null)
                pw.ClipRRect(
                  horizontalRadius: 8,
                  verticalRadius: 8,
                  child: pw.Image(logo, height: 54),
                ),
              pw.SizedBox(height: 8),
              pw.Text(
                'MT ALCHEMY',
                style: pw.TextStyle(
                  fontSize: 11,
                  letterSpacing: 3,
                  fontWeight: pw.FontWeight.bold,
                  color: _purple,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Certificate of Completion',
                style: pw.TextStyle(
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                  color: _deepBlue,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'This is to certify that',
                style: const pw.TextStyle(fontSize: 13),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                learnerName,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 30,
                  fontWeight: pw.FontWeight.bold,
                  color: _deepBlue,
                ),
              ),
              pw.Container(
                width: 260,
                height: 2,
                margin: const pw.EdgeInsets.symmetric(vertical: 8),
                color: _yellow,
              ),
              pw.Text(
                'has successfully completed',
                style: const pw.TextStyle(fontSize: 13),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                courseTitle,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: _purple,
                ),
              ),
              if (score != null && score.isNotEmpty) ...[
                pw.SizedBox(height: 6),
                pw.Text(
                  'Assessment passed with a score of $score',
                  style: const pw.TextStyle(fontSize: 11, color: _muted),
                ),
              ],
              pw.Spacer(),
              pw.Divider(color: PdfColor.fromInt(0xFFDDD8EA)),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  fact('Generated date', date),
                  fact('Certificate ID', certificateId),
                  pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        trainer,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: _deepBlue,
                        ),
                      ),
                      pw.Container(
                        width: 150,
                        height: 1,
                        margin: const pw.EdgeInsets.symmetric(vertical: 4),
                        color: _deepBlue,
                      ),
                      pw.Text(
                        'Trainer',
                        style: const pw.TextStyle(fontSize: 9, color: _muted),
                      ),
                    ],
                  ),
                  pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.all(4),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          border: pw.Border.all(color: _deepBlue),
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.BarcodeWidget(
                          barcode: pw.Barcode.qrCode(),
                          data: verifyUrl,
                          width: 72,
                          height: 72,
                          color: _deepBlue,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Scan to verify',
                        style: const pw.TextStyle(fontSize: 8, color: _muted),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return doc.save();
}
