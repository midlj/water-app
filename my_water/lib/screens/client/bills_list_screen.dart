import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/bill_provider.dart';
import '../../models/bill_model.dart';
import '../../widgets/common/custom_button.dart';
import 'payment_screen.dart';

class BillsListScreen extends StatefulWidget {
  final String userId;
  const BillsListScreen({super.key, required this.userId});

  @override
  State<BillsListScreen> createState() => _BillsListScreenState();
}

class _BillsListScreenState extends State<BillsListScreen> {
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BillProvider>().loadBillsByUser(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _FilterChip(label: 'All', selected: _filterStatus == null, onTap: () => setState(() => _filterStatus = null)),
              const SizedBox(width: 8),
              _FilterChip(label: 'Unpaid', selected: _filterStatus == 'unpaid', onTap: () => setState(() => _filterStatus = 'unpaid')),
              const SizedBox(width: 8),
              _FilterChip(label: 'Paid', selected: _filterStatus == 'paid', onTap: () => setState(() => _filterStatus = 'paid')),
            ]),
          ),
        ),
        Expanded(
          child: Consumer<BillProvider>(
            builder: (_, provider, __) {
              if (provider.loading) return const Center(child: CircularProgressIndicator());
              if (provider.error != null) return Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)));

              var bills = provider.bills;
              if (_filterStatus != null) bills = bills.where((b) => b.status == _filterStatus).toList();

              if (bills.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text(_filterStatus == null ? 'No bills found' : 'No ${_filterStatus} bills',
                      style: const TextStyle(color: AppColors.textSecondary)),
                ]));
              }

              return RefreshIndicator(
                onRefresh: () => provider.loadBillsByUser(widget.userId),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: bills.length,
                  itemBuilder: (_, i) => _BillDetailCard(bill: bills[i], userId: widget.userId),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
          boxShadow: selected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : [],
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}

class _BillDetailCard extends StatelessWidget {
  final BillModel bill;
  final String userId;
  const _BillDetailCard({required this.bill, required this.userId});

  @override
  Widget build(BuildContext context) {
    final isPaid = bill.status == 'paid';
    final isOverdue = !isPaid && bill.dueDate.isBefore(DateTime.now());
    final statusColor = isPaid ? AppColors.paid : isOverdue ? AppColors.overdue : AppColors.unpaid;
    final statusBg = isPaid ? AppColors.successLight : isOverdue ? AppColors.errorLight : AppColors.warningLight;

    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: CircleAvatar(
          backgroundColor: statusBg,
          child: Icon(isPaid ? Icons.check_circle_outline : Icons.receipt_long_outlined, color: statusColor, size: 22),
        ),
        title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(bill.billNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
            child: Text(bill.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
        subtitle: Text('${AppConstants.monthName(bill.month)} ${bill.year} • ${bill.unitsConsumed.toStringAsFixed(0)} units',
            style: const TextStyle(fontSize: 12)),
        trailing: Text('\$${bill.totalAmount.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: statusColor)),
        children: [
          const Divider(),
          // Tariff breakdown
          ...bill.tariffBreakdown.map((t) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(t.tier, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('\$${t.amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
          )),
          const Divider(height: 16),
          _BillRow('Service Charge', '\$${bill.serviceCharge.toStringAsFixed(2)}'),
          _BillRow('Tax (5%)', '\$${bill.taxAmount.toStringAsFixed(2)}'),
          const Divider(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            Text('\$${bill.totalAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: statusColor)),
          ]),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Due: ${DateFormat('dd MMM yyyy').format(bill.dueDate)}',
                style: TextStyle(fontSize: 12, color: isOverdue ? AppColors.error : AppColors.textSecondary)),
            if (bill.paidDate != null)
              Text('Paid: ${DateFormat('dd MMM yyyy').format(bill.paidDate!)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.success)),
          ]),
          if (!isPaid) ...[
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Pay \$${bill.totalAmount.toStringAsFixed(2)}',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PaymentScreen(bill: bill)),
              ).then((_) => context.read<BillProvider>().loadBillsByUser(userId)),
              icon: Icons.payment_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  const _BillRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
