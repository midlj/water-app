import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/payment_provider.dart';
import '../../models/payment_model.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final String userId;
  const PaymentHistoryScreen({super.key, required this.userId});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentProvider>().loadPaymentsByUser(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (_, provider, __) {
        if (provider.loading) return const Center(child: CircularProgressIndicator());
        if (provider.error != null) return Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)));

        if (provider.payments.isEmpty) {
          return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.payment_outlined, size: 64, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('No payment history', style: TextStyle(color: AppColors.textSecondary)),
          ]));
        }

        // Total paid summary
        final totalPaid = provider.payments.fold(0.0, (s, p) => s + p.amount);

        return RefreshIndicator(
          onRefresh: () => provider.loadPaymentsByUser(widget.userId),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(gradient: AppColors.cardGradient, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 40),
                      const SizedBox(width: 16),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Total Paid', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('\$${totalPaid.toStringAsFixed(2)}',
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                        Text('${provider.payments.length} transaction${provider.payments.length > 1 ? 's' : ''}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ]),
                    ]),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _PaymentCard(payment: provider.payments[i]),
                    childCount: provider.payments.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        );
      },
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final PaymentModel payment;
  const _PaymentCard({required this.payment});

  IconData get _methodIcon {
    switch (payment.paymentMethod) {
      case 'card': return Icons.credit_card_rounded;
      case 'upi': return Icons.qr_code_rounded;
      case 'bank_transfer': return Icons.account_balance_rounded;
      case 'cash': return Icons.payments_rounded;
      default: return Icons.language_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(12)),
          child: Icon(_methodIcon, color: AppColors.success, size: 22),
        ),
        title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('\$${payment.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.success)),
          Text(DateFormat('dd MMM yyyy').format(payment.paymentDate),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ]),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (payment.billNumber != null)
            Text('Bill: ${payment.billNumber}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          Text('Txn: ${payment.transactionId}',
              style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
          Text(payment.paymentMethod.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(fontSize: 10, color: AppColors.textHint, letterSpacing: 0.5)),
        ]),
        isThreeLine: true,
      ),
    );
  }
}
