import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/payment_provider.dart';
import '../../models/bill_model.dart';
import '../../widgets/common/custom_button.dart';

class PaymentScreen extends StatefulWidget {
  final BillModel bill;
  const PaymentScreen({super.key, required this.bill});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _paymentMethod = 'online';
  bool _confirmed = false;

  final Map<String, String> _methodLabels = {
    'online': 'Online Payment',
    'card': 'Credit / Debit Card',
    'upi': 'UPI',
    'bank_transfer': 'Bank Transfer',
    'cash': 'Cash',
  };

  final Map<String, IconData> _methodIcons = {
    'online': Icons.language_rounded,
    'card': Icons.credit_card_rounded,
    'upi': Icons.qr_code_scanner_rounded,
    'bank_transfer': Icons.account_balance_rounded,
    'cash': Icons.payments_rounded,
  };

  Future<void> _pay() async {
    final provider = context.read<PaymentProvider>();
    final ok = await provider.makePayment({
      'billId': widget.bill.id,
      'amount': widget.bill.totalAmount,
      'paymentMethod': _paymentMethod,
    });
    if (!mounted) return;
    if (ok) {
      _showSuccessDialog(provider.successMessage ?? 'Payment successful!');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Payment failed'), backgroundColor: AppColors.error),
      );
    }
    provider.clearMessages();
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 52),
          ),
          const SizedBox(height: 16),
          const Text('Payment Successful!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.success)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ]),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              Navigator.pop(context); // go back to bills
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bill = widget.bill;
    return Scaffold(
      appBar: AppBar(title: const Text('Make Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Bill summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 40),
              const SizedBox(height: 12),
              Text('\$${bill.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, color: Colors.white)),
              const SizedBox(height: 4),
              Text('${AppConstants.monthName(bill.month)} ${bill.year} Water Bill',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _SummaryItem('Bill No.', bill.billNumber),
                _SummaryItem('Units', '${bill.unitsConsumed.toStringAsFixed(0)}'),
                _SummaryItem('Due', DateFormat('dd MMM').format(bill.dueDate)),
              ]),
            ]),
          ),
          const SizedBox(height: 24),

          // Breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.07), blurRadius: 8)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Bill Breakdown', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Divider(height: 16),
              ...bill.tariffBreakdown.map((t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(t.tier, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Text('\$${t.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
                ]),
              )),
              const SizedBox(height: 4),
              _SummaryRow('Service Charge', '\$${bill.serviceCharge.toStringAsFixed(2)}'),
              _SummaryRow('Tax (5%)', '\$${bill.taxAmount.toStringAsFixed(2)}'),
              const Divider(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                Text('\$${bill.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.primary)),
              ]),
            ]),
          ),
          const SizedBox(height: 24),

          // Payment method
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.07), blurRadius: 8)]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 12),
              ..._methodLabels.entries.map((entry) => RadioListTile<String>(
                value: entry.key,
                groupValue: _paymentMethod,
                title: Row(children: [
                  Icon(_methodIcons[entry.key], size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(entry.value, style: const TextStyle(fontSize: 14)),
                ]),
                contentPadding: EdgeInsets.zero,
                dense: true,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _paymentMethod = v!),
              )),
            ]),
          ),
          const SizedBox(height: 16),

          // Confirm checkbox
          CheckboxListTile(
            value: _confirmed,
            onChanged: (v) => setState(() => _confirmed = v!),
            title: const Text('I confirm the payment details are correct', style: TextStyle(fontSize: 14)),
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          const SizedBox(height: 16),

          Consumer<PaymentProvider>(
            builder: (_, p, __) => PrimaryButton(
              label: 'Pay \$${bill.totalAmount.toStringAsFixed(2)}',
              onPressed: _confirmed && !p.loading ? _pay : null,
              isLoading: p.loading,
              icon: Icons.lock_rounded,
            ),
          ),
          const SizedBox(height: 16),

          Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
            Icon(Icons.security_rounded, size: 14, color: AppColors.textHint),
            SizedBox(width: 4),
            Text('Secured & Encrypted Payment', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
          ]),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryItem(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13)),
      ]),
    );
  }
}
