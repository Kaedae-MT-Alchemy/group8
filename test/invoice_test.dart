import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:publicwebsite/commerce/commerce_prototype_store.dart';
import 'package:publicwebsite/commerce/invoice_pdf.dart';

ShopOrder sampleOrder({String status = 'Paid'}) => ShopOrder(
  number: 'MA1795101047606000',
  date: DateTime(2026, 11, 19, 10, 30),
  lines: [
    CartLine(
      product: CommercePrototypeStore.courseProduct(
        courseId: 'leadership',
        title: 'Leadership Essentials',
        price: 699,
      ),
      quantity: 1,
    ),
    const CartLine(
      product: ShopProduct(
        id: 'clarity-workbook',
        name: 'Emotional Clarity Workbook',
        description: 'Workbook',
        price: 29,
        category: 'Digital',
        icon: Icons.menu_book_outlined,
        digital: true,
      ),
      quantity: 1,
    ),
    const CartLine(
      product: ShopProduct(
        id: 'mindful-journal',
        name: 'Mindful Reflection Journal',
        description: 'Journal',
        price: 48,
        category: 'Physical',
        icon: Icons.auto_stories_outlined,
      ),
      quantity: 2,
    ),
  ],
  total: 699 + 29 + 96 + 10,
  paymentStatus: status,
  paymentMethod: 'Bank transfer',
  fulfilmentStatus: 'Processing',
  customerName: 'Aisha Rahman',
  customerEmail: 'aisha@example.com',
  customerPhone: '+60 12 345 6789',
  billingAddress: '12 Jalan Bukit Bintang, 55100 Kuala Lumpur',
  shippingAddress: '12 Jalan Bukit Bintang, 55100 Kuala Lumpur',
  stockReserved: true,
  paymentReference: 'MA1795101047606000',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('title and number follow the payment status', () {
    expect(invoiceTitle(sampleOrder()), 'Receipt');
    expect(invoiceNumber(sampleOrder()), 'RCT-MA1795101047606000');
    final pending = sampleOrder(status: 'Pending');
    expect(invoiceTitle(pending), 'Invoice');
    expect(invoiceNumber(pending), 'INV-MA1795101047606000');
    expect(invoiceFileName(pending), 'invoice-MA1795101047606000.pdf');
  });

  test('line types are course, digital or physical', () {
    expect(sampleOrder().lines.map(lineType), [
      'Course',
      'Digital',
      'Physical',
    ]);
  });

  test('builds a PDF for paid and pending orders', () async {
    for (final status in ['Paid', 'Pending', 'Failed']) {
      final bytes = await buildInvoicePdf(sampleOrder(status: status));
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
      expect(bytes.length, greaterThan(20000)); // fonts and logo embedded
    }
    // Keep a copy for a visual check when asked: INVOICE_PREVIEW=path.pdf
    final out = Platform.environment['INVOICE_PREVIEW'];
    if (out != null) {
      File(out).writeAsBytesSync(await buildInvoicePdf(sampleOrder()));
      File(
        out.replaceFirst('.pdf', '-pending.pdf'),
      ).writeAsBytesSync(await buildInvoicePdf(sampleOrder(status: 'Pending')));
    }
  });
}
