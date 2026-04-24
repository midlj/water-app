import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/bill_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/bill_model.dart';
import '../../widgets/common/custom_button.dart';
import 'payment_screen.dart';

class ClientDashboardScreen extends StatefulWidget {
  final String userId;
  const ClientDashboardScreen({super.key, required this.userId});

  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardScreenState();
}

class _ClientDashboardScreenState extends State<ClientDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    context.read<BillProvider>().loadBillsByUser(widget.userId);
    context.read<PaymentProvider>().loadPaymentsByUser(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    return RefreshIndicator(
      onRefresh: () async => _loadData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hi, ${user?.name.split(' ').first ?? ''}!',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(DateFormat('EEEE, MMM d yyyy').format(DateTime.now()),
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                  if (user?.meterNumber != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text('Meter: ${user!.meterNumber}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                    ),
                  ],
                ])),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 32),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            // Quick stats
            Consumer<BillProvider>(
              builder: (_, provider, __) {
                final unpaid = provider.bills.where((b) => b.status == 'unpaid').length;
                final totalDue = provider.bills.where((b) => b.status == 'unpaid').fold(0.0, (s, b) => s + b.totalAmount);
                return Row(children: [
                  Expanded(child: _QuickStatCard(
                    label: 'Unpaid Bills',
                    value: '$unpaid',
                    icon: Icons.receipt_long_rounded,
                    color: unpaid > 0 ? AppColors.warning : AppColors.success,
                    bgColor: unpaid > 0 ? AppColors.warningLight : AppColors.successLight,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _QuickStatCard(
                    label: 'Amount Due',
                    value: '\$${totalDue.toStringAsFixed(2)}',
                    icon: Icons.account_balance_wallet_rounded,
                    color: totalDue > 0 ? AppColors.error : AppColors.success,
                    bgColor: totalDue > 0 ? AppColors.errorLight : AppColors.successLight,
                  )),
                ]);
              },
            ),
            const SizedBox(height: 24),

            // Latest unpaid bill — pay now
            Consumer<BillProvider>(
              builder: (_, provider, __) {
                if (provider.loading) return const Center(child: CircularProgressIndicator());
                final unpaidBills = provider.bills.where((b) => b.status == 'unpaid').toList();
                if (unpaidBills.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.success.withOpacity(0.3))),
                    child: const Row(children: [
                      Icon(Icons.check_circle_rounded, color: AppColors.success, size: 36),
                      SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('All Paid!', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.success, fontSize: 16)),
                        Text('No pending bills', style: TextStyle(color: AppColors.success, fontSize: 13)),
                      ]),
                    ]),
                  );
                }
                final bill = unpaidBills.first;
                return _PendingBillCard(bill: bill);
              },
            ),
            const SizedBox(height: 24),

            // Recent payments
            const Text('Recent Payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Consumer<PaymentProvider>(
              builder: (_, provider, __) {
                if (provider.loading) return const Center(child: CircularProgressIndicator());
                final payments = provider.payments.take(4).toList();
                if (payments.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.all(20),
                      child: Text('No payment history', style: TextStyle(color: AppColors.textSecondary))));
                }
                return Column(
                  children: payments.map((p) => Card(
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: AppColors.successLight,
                          child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20)),
                      title: Text('\$${p.amount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text(p.billNumber != null ? 'Bill: ${p.billNumber}' : p.transactionId,
                          style: const TextStyle(fontSize: 12)),
                      trailing: Text(DateFormat('dd MMM').format(p.paymentDate),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _QuickStatCard({required this.label, required this.value, required this.icon, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
      ]),
    );
  }
}

class _PendingBillCard extends StatelessWidget {
  final BillModel bill;
  const _PendingBillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final isOverdue = bill.dueDate.isBefore(DateTime.now());
    final headerColor = isOverdue ? AppColors.overdue : AppColors.warning;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: headerColor.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: headerColor.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: headerColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Icon(isOverdue ? Icons.warning_rounded : Icons.pending_rounded, color: headerColor, size: 20),
              const SizedBox(width: 8),
              Text(isOverdue ? 'OVERDUE BILL' : 'BILL DUE',
                  style: TextStyle(color: headerColor, fontWeight: FontWeight.w700, fontSize: 13)),
            ]),
            Text(bill.billNumber, style: TextStyle(color: headerColor, fontSize: 12)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${AppConstants.monthName(bill.month)} ${bill.year}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('\$${bill.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: headerColor)),
            ]),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('${bill.unitsConsumed.toStringAsFixed(0)} units consumed',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('Due: ${DateFormat('dd MMM yyyy').format(bill.dueDate)}',
                  style: TextStyle(fontSize: 12, color: isOverdue ? AppColors.error : AppColors.textSecondary)),
            ]),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Pay Now',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PaymentScreen(bill: bill)),
              ).then((_) => context.read<BillProvider>().loadBillsByUser(bill.userId)),
              icon: Icons.payment_rounded,
            ),
          ]),
        ),
      ]),
    );
  }
}
