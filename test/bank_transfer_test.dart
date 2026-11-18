import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:publicwebsite/commerce/commerce_prototype_store.dart';
import 'package:publicwebsite/data/mock_data.dart';
import 'package:publicwebsite/shared/video_embed.dart';

import 'support/fake_backend.dart';

void main() {
  setUp(setUpFakeBackend);
  final store = CommercePrototypeStore.instance;

  ShopOrder placeTransfer() {
    final course = mockCourses.firstWhere((c) => c.id == 'leadership');
    return store.placeOrder(
      customerName: 'Learner',
      customerEmail: 'learner@mtalchemy.demo',
      customerPhone: '1',
      billingAddress: 'KL',
      address: '',
      paymentMethod: 'Bank transfer',
      paymentStatus: 'Pending',
      items: [
        CartLine(
          product: CommercePrototypeStore.courseProduct(
            courseId: course.id,
            title: course.title,
            price: course.price,
          ),
          quantity: 1,
        ),
      ],
    )!;
  }

  test(
    'bank transfer: pending with reference, receipt saved, admin verifies',
    () async {
      await signInAs('learner');
      final order = placeTransfer();
      expect(order.paymentStatus, 'Pending');
      expect(order.paymentReference, order.number);
      expect(order.awaitingTransfer, isTrue);
      expect(order.transferOverdue, isFalse);
      await store.flush();

      final error = await store.submitTransferProof(
        order.number,
        transferReference: 'MBB123456',
        receipt: Uint8List.fromList(List.filled(64, 7)),
      );
      expect(error, isNull);
      final proof = await fakeDb
          .collection('paymentProofs')
          .doc(order.number)
          .get();
      expect(proof.data()?['transferReference'], 'MBB123456');
      final saved = await fakeDb.collection('orders').doc(order.number).get();
      expect(saved.data()?['proofStatus'], 'Submitted');
      expect(saved.data()?['paymentStatus'], 'Pending');

      await signInAs('admin');
      expect(store.orderByNumber(order.number)?.proofStatus, 'Submitted');
      expect(await store.transferProof(order.number), isNotNull);
      expect(store.verifyTransfer(order.number), isTrue);
      await store.flush();
      final paid = await fakeDb.collection('orders').doc(order.number).get();
      expect(paid.data()?['paymentStatus'], 'Paid');
      expect(paid.data()?['proofStatus'], 'Verified');
    },
  );

  test('bank transfer: admin rejects receipt with a reason', () async {
    await signInAs('learner');
    final order = placeTransfer();
    await store.flush();
    await store.submitTransferProof(
      order.number,
      transferReference: 'X1234',
      receipt: Uint8List.fromList([1, 2, 3]),
    );
    await signInAs('admin');
    expect(
      store.rejectTransfer(order.number, 'Amount does not match.'),
      isTrue,
    );
    final o = store.orderByNumber(order.number)!;
    expect(o.proofStatus, 'Rejected');
    expect(o.rejectReason, 'Amount does not match.');
    expect(o.paymentStatus, 'Pending');
  });

  test('unpaid bank transfers become overdue after 3 days', () {
    final old = ShopOrder(
      number: 'MA1',
      date: DateTime.now().subtract(const Duration(days: 4)),
      lines: const [],
      total: 10,
      paymentStatus: 'Pending',
      paymentMethod: 'Bank transfer',
      fulfilmentStatus: 'Pending',
      customerName: 'A',
    );
    expect(old.transferOverdue, isTrue);
    expect(old.copyWith(proofStatus: 'Submitted').transferOverdue, isFalse);
    expect(old.copyWith(paymentMethod: 'Card').transferOverdue, isFalse);
  });

  test('YouTube links are recognised', () {
    expect(
      youTubeId('https://www.youtube.com/watch?v=qp0HIF3SfI4'),
      'qp0HIF3SfI4',
    );
    expect(youTubeId('https://youtu.be/qp0HIF3SfI4'), 'qp0HIF3SfI4');
    expect(
      youTubeId('https://www.youtube.com/embed/qp0HIF3SfI4'),
      'qp0HIF3SfI4',
    );
    expect(youTubeId('https://example.com/video.mp4'), isNull);
    expect(mockCourses.every((c) => youTubeId(c.videoUrl) != null), isTrue);
  });
}
