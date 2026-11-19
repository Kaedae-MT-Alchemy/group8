import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../shared/file_export.dart';
import '../shared/pdf_print.dart';
import 'commerce_prototype_store.dart';

// Lecturer palette.
const _royal = PdfColor.fromInt(0xFF2412B8);
const _gold = PdfColor.fromInt(0xFFFCC931);
const _ink = PdfColor.fromInt(0xFF1B1840);
const _muted = PdfColor.fromInt(0xFF6B6880);
const _line = PdfColor.fromInt(0xFFE3E0F2);
const _tint = PdfColor.fromInt(0xFFF6F4FF);

const companyPhone = '+60 11-7239 9249';
const companyEmail = 'mabeltan.alchemy@gmail.com';

/// "Receipt" once an order is paid, otherwise "Invoice".
String invoiceTitle(ShopOrder order) =>
    order.paymentStatus == 'Paid' ? 'Receipt' : 'Invoice';

/// Document number derived from the order number.
String invoiceNumber(ShopOrder order) =>
    '${order.paymentStatus == 'Paid' ? 'RCT' : 'INV'}-${order.number}';

String invoiceFileName(ShopOrder order) =>
    '${invoiceTitle(order).toLowerCase()}-${order.number}.pdf';

/// Course, Digital or Physical.
String lineType(CartLine line) => CommercePrototypeStore.isCourseLine(line)
    ? 'Course'
    : line.product.digital
    ? 'Digital'
    : 'Physical';

String _rm(double v) {
  final fixed = v.abs().toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return '${v < 0 ? '-' : ''}RM $whole.${parts[1]}';
}

String _date(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

Future<pw.Font?> _font(String asset) async {
  try {
    return pw.Font.ttf(await rootBundle.load(asset));
  } catch (_) {
    return null;
  }
}

/// Builds a one-page (or longer, for big orders) A4 invoice or receipt.
Future<Uint8List> buildInvoicePdf(ShopOrder order) async {
  final body = await _font('assets/fonts/Lexend-400.ttf');
  final bodyBold = await _font('assets/fonts/Lexend-600.ttf');
  final serif = await _font('assets/fonts/Fraunces-600.ttf');
  final serifItalic = await _font('assets/fonts/Fraunces-500-Italic.ttf');
  pw.MemoryImage? logo;
  try {
    final data = await rootBundle.load('assets/images/logo_mt_alchemy.jpeg');
    logo = pw.MemoryImage(data.buffer.asUint8List());
  } catch (_) {}

  final title = invoiceTitle(order);
  final paid = order.paymentStatus == 'Paid';
  final subtotal = order.lines.fold<double>(0, (s, l) => s + l.subtotal);
  final adjustment = order.total - subtotal;
  final reference =
      order.transferReference ?? order.paymentReference ?? order.number;
  final (badgeBg, badgeFg) = switch (order.paymentStatus) {
    'Paid' => (
      const PdfColor.fromInt(0xFFE3F5E8),
      const PdfColor.fromInt(0xFF1D7A3A),
    ),
    'Failed' => (
      const PdfColor.fromInt(0xFFFDE5E5),
      const PdfColor.fromInt(0xFFB3261E),
    ),
    'Refunded' => (
      const PdfColor.fromInt(0xFFECECEC),
      const PdfColor.fromInt(0xFF444444),
    ),
    _ => (
      const PdfColor.fromInt(0xFFFFF4D6),
      const PdfColor.fromInt(0xFF8A5A00),
    ),
  };

  final theme = pw.ThemeData.withFont(
    base: body,
    bold: bodyBold,
    italic: serifItalic,
  );
  pw.TextStyle t(double size, {PdfColor color = _ink, bool bold = false}) =>
      pw.TextStyle(
        fontSize: size,
        color: color,
        font: bold ? bodyBold : body,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      );
  pw.TextStyle label() =>
      t(7.5, color: _muted, bold: true).copyWith(letterSpacing: 1.1);

  pw.Widget block(String heading, List<String> lines) => pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(heading.toUpperCase(), style: label()),
      pw.SizedBox(height: 5),
      for (final (i, l) in lines.indexed)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 2),
          child: pw.Text(l, style: t(9.5, bold: i == 0)),
        ),
    ],
  );

  pw.Widget totalRow(String l, String v, {bool strong = false}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 3),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(l, style: t(strong ? 11 : 9.5, bold: strong)),
        pw.Text(v, style: t(strong ? 11 : 9.5, bold: strong)),
      ],
    ),
  );

  final doc = pw.Document(
    title: '$title ${invoiceNumber(order)}',
    author: 'MT Alchemy',
    theme: theme,
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
      header: (context) => context.pageNumber == 1
          ? pw.SizedBox()
          : pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Text(
                '$title ${invoiceNumber(order)} (continued)',
                style: t(9, color: _muted),
              ),
            ),
      footer: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(height: 1, color: _line),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'MT Alchemy · $companyPhone · $companyEmail',
                style: t(8, color: _muted),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: t(8, color: _muted),
              ),
            ],
          ),
        ],
      ),
      build: (context) => [
        // Gold rule across the top.
        pw.Container(height: 5, color: _gold),
        pw.SizedBox(height: 18),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null)
              pw.ClipRRect(
                horizontalRadius: 8,
                verticalRadius: 8,
                child: pw.Image(logo, width: 54, height: 54),
              ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'MT Alchemy',
                    style: pw.TextStyle(
                      font: serif,
                      fontSize: 20,
                      color: _royal,
                    ),
                  ),
                  pw.Text(
                    'Made to Thrive',
                    style: pw.TextStyle(
                      font: serifItalic,
                      fontSize: 10.5,
                      color: _muted,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(companyPhone, style: t(8.5, color: _muted)),
                  pw.Text(companyEmail, style: t(8.5, color: _muted)),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(font: serif, fontSize: 30, color: _royal),
                ),
                pw.SizedBox(height: 2),
                pw.Text(invoiceNumber(order), style: t(10, bold: true)),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: pw.BoxDecoration(
                    color: badgeBg,
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Text(
                    order.paymentStatus.toUpperCase(),
                    style: t(
                      8,
                      color: badgeFg,
                      bold: true,
                    ).copyWith(letterSpacing: 1),
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 22),
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: _tint,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: block('Bill to', [
                  order.customerName,
                  if (order.customerEmail.isNotEmpty) order.customerEmail,
                  if (order.customerPhone.isNotEmpty) order.customerPhone,
                  if (order.billingAddress != null) order.billingAddress!,
                ]),
              ),
              if (order.hasPhysical) ...[
                pw.SizedBox(width: 14),
                pw.Expanded(
                  child: block('Ship to', [
                    order.customerName,
                    order.shippingAddress ?? 'Same as billing address',
                  ]),
                ),
              ],
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: block('Details', [
                  'Issued ${_date(order.date)}',
                  'Order ${order.number}',
                  'Payment: ${order.paymentMethod}',
                  if (order.trackingNumber != null)
                    'Tracking: ${order.trackingNumber}',
                ]),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        pw.TableHelper.fromTextArray(
          headers: ['Item', 'Type', 'Qty', 'Unit price', 'Amount'],
          data: [
            for (final l in order.lines)
              [
                l.product.name,
                lineType(l),
                '${l.quantity}',
                _rm(l.product.price),
                _rm(l.subtotal),
              ],
          ],
          border: null,
          headerDecoration: const pw.BoxDecoration(color: _royal),
          headerStyle: t(8.5, color: PdfColors.white, bold: true),
          cellStyle: t(9.5),
          headerPadding: const pw.EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 7,
          ),
          cellPadding: const pw.EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ),
          rowDecoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _line, width: .8)),
          ),
          oddRowDecoration: const pw.BoxDecoration(
            color: _tint,
            border: pw.Border(bottom: pw.BorderSide(color: _line, width: .8)),
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(4.2),
            1: const pw.FlexColumnWidth(1.4),
            2: const pw.FlexColumnWidth(.7),
            3: const pw.FlexColumnWidth(1.6),
            4: const pw.FlexColumnWidth(1.6),
          },
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.center,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.centerRight,
          },
          headerAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerLeft,
            2: pw.Alignment.center,
            3: pw.Alignment.centerRight,
            4: pw.Alignment.centerRight,
          },
        ),
        pw.SizedBox(height: 14),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.only(right: 24),
                child: block('Payment', [
                  paid
                      ? 'Paid by ${order.paymentMethod}'
                      : switch (order.paymentStatus) {
                          'Failed' => 'Payment was not completed',
                          'Refunded' => 'Refunded',
                          _ => 'Awaiting payment (${order.paymentMethod})',
                        },
                  'Reference: $reference',
                  if (!paid && order.isBankTransfer)
                    'Use the reference above when you transfer, then upload your receipt in My Orders.',
                ]),
              ),
            ),
            pw.SizedBox(
              width: 210,
              child: pw.Column(
                children: [
                  totalRow('Subtotal', _rm(subtotal)),
                  if (adjustment > 0.004)
                    totalRow('Shipping', _rm(adjustment))
                  else if (adjustment < -0.004)
                    totalRow('Discount', _rm(adjustment))
                  else
                    totalRow(
                      'Shipping',
                      order.hasPhysical ? _rm(0) : 'Not required',
                    ),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _gold,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: totalRow(
                      paid ? 'Total paid' : 'Total due',
                      _rm(order.total),
                      strong: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 28),
        pw.Text(
          'Thank you for learning with MT Alchemy.',
          style: pw.TextStyle(font: serifItalic, fontSize: 13, color: _royal),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Courses and digital products are available in your account once payment is confirmed. '
          'Physical items are dispatched after payment and tracking appears in My Orders. '
          'For questions about this ${title.toLowerCase()}, contact us at $companyEmail or $companyPhone and quote ${order.number}. '
          'This document was generated electronically and is valid without a signature.',
          style: t(8.5, color: _muted),
        ),
      ],
    ),
  );
  return doc.save();
}

/// Download and Print buttons for an order's invoice / receipt.
class InvoiceActions extends StatefulWidget {
  const InvoiceActions({super.key, required this.order, this.dense = false});
  final ShopOrder order;
  final bool dense;

  @override
  State<InvoiceActions> createState() => _InvoiceActionsState();
}

class _InvoiceActionsState extends State<InvoiceActions> {
  bool busy = false;

  Future<void> _run(bool print) async {
    setState(() => busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = await buildInvoicePdf(widget.order);
      if (print) {
        final shown = await printPdf(bytes);
        if (!shown) await saveLocalFile(invoiceFileName(widget.order), bytes);
      } else {
        final path = await saveLocalFile(invoiceFileName(widget.order), bytes);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              path == null
                  ? 'PDF saving is unavailable on this device.'
                  : '${invoiceTitle(widget.order)} saved: $path',
            ),
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not create the PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = invoiceTitle(widget.order);
    final style = widget.dense
        ? OutlinedButton.styleFrom(visualDensity: VisualDensity.compact)
        : null;
    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          style: style,
          onPressed: busy ? null : () => _run(false),
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: Text('Download ${title.toLowerCase()}'),
        ),
        OutlinedButton.icon(
          style: style,
          onPressed: busy ? null : () => _run(true),
          icon: const Icon(Icons.print_outlined, size: 18),
          label: Text('Print ${title.toLowerCase()}'),
        ),
      ],
    );
  }
}
