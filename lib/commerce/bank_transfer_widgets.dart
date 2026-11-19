import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shared/image_compress.dart';
import '../theme.dart';
import 'commerce_prototype_store.dart';

final _store = CommercePrototypeStore.instance;

String _date(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

/// Short label and colour for where a bank transfer stands.
(String, Color) transferStage(ShopOrder order) {
  if (order.paymentStatus == 'Paid') {
    return ('Payment received', Colors.green.shade700);
  }
  if (order.proofStatus == 'Expired' || order.paymentStatus == 'Failed') {
    return ('Cancelled, not paid in time', Colors.red.shade700);
  }
  return switch (order.proofStatus) {
    'Submitted' => ('Receipt submitted, awaiting verification', royalBlue),
    'Rejected' => ('Receipt not accepted, upload again', Colors.red.shade700),
    _ => ('Awaiting your transfer', Colors.orange.shade800),
  };
}

class TransferStageChip extends StatelessWidget {
  const TransferStageChip({super.key, required this.order, this.admin = false});
  final ShopOrder order;
  final bool admin;
  @override
  Widget build(BuildContext context) {
    var (label, color) = transferStage(order);
    if (admin && order.awaitingTransfer && order.proofStatus != 'Submitted') {
      label = order.proofStatus == 'Rejected'
          ? 'Receipt rejected, waiting for customer'
          : 'Waiting for customer transfer';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12.5,
        ),
      ),
    );
  }
}

/// Customer view: how to pay, then upload the receipt.
class BankTransferCard extends StatefulWidget {
  const BankTransferCard({super.key, required this.order});
  final ShopOrder order;
  @override
  State<BankTransferCard> createState() => _BankTransferCardState();
}

class _BankTransferCardState extends State<BankTransferCard> {
  final _ref = TextEditingController();
  Uint8List? _receipt;
  String? _fileName;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _ref.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.singleOrNull;
    if (file?.bytes == null) return;
    final compressed = compressImage(
      file!.bytes!,
      maxSide: 1400,
      targetBytes: 450 * 1024,
    );
    setState(() {
      _error = compressed == null
          ? 'That file is not an image. Upload a JPG, PNG or screenshot of the receipt.'
          : null;
      _receipt = compressed;
      _fileName = compressed == null ? null : file.name;
    });
  }

  Future<void> _submit() async {
    if (_ref.text.trim().length < 4) {
      setState(
        () => _error = 'Enter the reference number shown on your bank receipt.',
      );
      return;
    }
    if (_receipt == null) {
      setState(() => _error = 'Attach a photo or screenshot of the receipt.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await _store.submitTransferProof(
      widget.order.number,
      transferReference: _ref.text,
      receipt: _receipt!,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
      if (error == null) {
        _receipt = null;
        _fileName = null;
        _ref.clear();
      }
    });
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Receipt uploaded. Our finance team will verify it, usually within one working day.',
          ),
        ),
      );
    }
  }

  Widget _row(String label, String value, {bool copy = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(label, style: const TextStyle(color: Colors.black54)),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        if (copy)
          IconButton(
            tooltip: 'Copy $label',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.copy_rounded, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('$label copied')));
            },
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final canUpload =
        order.awaitingTransfer && order.proofStatus != 'Submitted';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_outlined, color: royalBlue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Pay by bank transfer',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TransferStageChip(order: order),
          const SizedBox(height: 12),
          if (order.awaitingTransfer) ...[
            _row('Amount', money(order.total), copy: true),
            for (final e in CommercePrototypeStore.bankDetails.entries)
              _row(e.key, e.value, copy: e.key == 'Account number'),
            _row(
              'Reference',
              order.paymentReference ?? order.number,
              copy: true,
            ),
            _row('Pay before', _date(order.transferDueAt)),
            const SizedBox(height: 8),
            Text(
              'Quote the reference so we can match your payment. Stock is held for you until ${_date(order.transferDueAt)}; after that an unpaid order is cancelled automatically.',
              style: const TextStyle(color: Colors.black54, height: 1.45),
            ),
          ],
          if (order.proofStatus == 'Rejected' &&
              order.rejectReason != null) ...[
            const SizedBox(height: 10),
            Text(
              'Why it was not accepted: ${order.rejectReason}',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ],
          if (order.proofStatus == 'Submitted' && order.awaitingTransfer) ...[
            const SizedBox(height: 10),
            Text(
              'We received your receipt (ref ${order.transferReference}) on ${_date(order.proofSubmittedAt ?? order.date)}. Finance will confirm it against our bank statement, usually within one working day. You will get a notification.',
              style: const TextStyle(height: 1.45),
            ),
          ],
          if (canUpload) ...[
            const Divider(height: 28),
            Text(
              'Already paid? Upload your receipt',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ref,
              decoration: const InputDecoration(
                labelText: 'Bank reference / transaction ID',
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : _pick,
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    _fileName == null ? 'Attach receipt image' : 'Change file',
                  ),
                ),
                if (_fileName != null)
                  Text(_fileName!, overflow: TextOverflow.ellipsis),
              ],
            ),
            if (_receipt != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(_receipt!, height: 140, fit: BoxFit.cover),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Colors.red.shade700)),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: const Text('Submit receipt for verification'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Admin view inside an order card: check the receipt, then confirm or
/// reject.
class TransferReviewPanel extends StatelessWidget {
  const TransferReviewPanel({super.key, required this.order});
  final ShopOrder order;

  Future<void> _viewReceipt(BuildContext context) async {
    final bytes = await _store.transferProof(order.number);
    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Receipt for ${order.number}'),
        content: SizedBox(
          width: 520,
          child: bytes == null
              ? const Text('No receipt image was found for this order.')
              : InteractiveViewer(
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm payment received?'),
        content: Text(
          'Only confirm after you see ${money(order.total)} with reference ${order.paymentReference ?? order.number} on the company bank statement. The customer is notified and the order moves to fulfilment.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm payment'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final done = _store.verifyTransfer(order.number);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          done
              ? 'Order ${order.number} marked as paid.'
              : 'Could not confirm: check stock for this order.',
        ),
      ),
    );
  }

  Future<void> _reject(BuildContext context) async {
    final reason = TextEditingController(
      text: 'We could not find this transfer on our bank statement.',
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject receipt'),
        content: SizedBox(
          width: 440,
          child: TextField(
            controller: reason,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason shown to the customer',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject receipt'),
          ),
        ],
      ),
    );
    if (ok != true || reason.text.trim().isEmpty || !context.mounted) return;
    _store.rejectTransfer(order.number, reason.text);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Customer asked to upload a new receipt for ${order.number}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(top: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F8FF),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE8DFFE)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.account_balance_outlined,
              size: 20,
              color: royalBlue,
            ),
            const SizedBox(width: 6),
            const Text(
              'Bank transfer',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 10),
            Flexible(child: TransferStageChip(order: order, admin: true)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Expected: ${money(order.total)} · reference ${order.paymentReference ?? order.number} · due ${_date(order.transferDueAt)}',
        ),
        if (order.transferReference != null)
          Text(
            'Customer bank ref: ${order.transferReference} · sent ${_date(order.proofSubmittedAt ?? order.date)}',
          ),
        if (order.proofStatus == 'Rejected' && order.rejectReason != null)
          Text(
            'Rejected: ${order.rejectReason}',
            style: TextStyle(color: Colors.red.shade700),
          ),
        if (order.awaitingTransfer) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (order.proofStatus == 'Submitted')
                OutlinedButton.icon(
                  onPressed: () => _viewReceipt(context),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('View receipt'),
                ),
              FilledButton.icon(
                onPressed: () => _confirm(context),
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Confirm payment received'),
              ),
              if (order.proofStatus == 'Submitted')
                OutlinedButton.icon(
                  onPressed: () => _reject(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Reject receipt'),
                ),
            ],
          ),
        ] else if (order.proofStatus == 'Verified' ||
            order.proofStatus == 'Submitted')
          TextButton.icon(
            onPressed: () => _viewReceipt(context),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('View receipt'),
          ),
      ],
    ),
  );
}
