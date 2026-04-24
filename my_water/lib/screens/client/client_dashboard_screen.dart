import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/bill_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/bill_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/shimmer_card.dart';
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
      color: AppColors.primary,
      onRefresh: () async => _loadData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Welcome hero ──────────────────────────────────────────────────
            _WelcomeCard(
              name: user?.name.split(' ').first ?? '',
              meterNumber: user?.meterNumber,
            ).animate().fadeIn(duration: 450.ms).slideY(begin: -0.12, end: 0),

            const SizedBox(height: 20),

            // ── Quick stats + usage indicator ─────────────────────────────────
            Consumer<BillProvider>(builder: (_, provider, __) {
              if (provider.loading) {
                return Row(children: const [
                  Expanded(child: ShimmerCard(height: 90)),
                  SizedBox(width: 12),
                  Expanded(child: ShimmerCard(height: 90)),
                ]);
              }
              final unpaid = provider.bills.where((b) => b.status == 'unpaid').length;
              final totalDue = provider.bills
                  .where((b) => b.status == 'unpaid')
                  .fold(0.0, (s, b) => s + b.totalAmount);
              final latestBill = provider.bills.isNotEmpty ? provider.bills.first : null;
              final units = latestBill?.unitsConsumed ?? 0.0;
              const maxUnits = 50.0;
              final pct = (units / maxUnits).clamp(0.0, 1.0);

              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(children: [
                      _QuickStat(
                        label: 'Unpaid Bills',
                        value: '$unpaid',
                        icon: Icons.receipt_long_rounded,
                        color: unpaid > 0 ? AppColors.warning : AppColors.success,
                        bgColor: unpaid > 0 ? AppColors.warningLight : AppColors.successLight,
                      ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05, end: 0),
                      const SizedBox(height: 12),
                      _QuickStat(
                        label: 'Amount Due',
                        value: '\$${totalDue.toStringAsFixed(2)}',
                        icon: Icons.account_balance_wallet_rounded,
                        color: totalDue > 0 ? AppColors.error : AppColors.success,
                        bgColor: totalDue > 0 ? AppColors.errorLight : AppColors.successLight,
                      ).animate().fadeIn(delay: 160.ms).slideX(begin: -0.05, end: 0),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _UsageCircle(
                      units: units,
                      percent: pct,
                    ).animate().fadeIn(delay: 200.ms).scale(
                          begin: const Offset(0.85, 0.85),
                          duration: 350.ms,
                        ),
                  ),
                ],
              );
            }),

            const SizedBox(height: 24),

            // ── Pending bill ──────────────────────────────────────────────────
            Consumer<BillProvider>(builder: (_, provider, __) {
              if (provider.loading) return const ShimmerCard(height: 160);

              final unpaidBills =
                  provider.bills.where((b) => b.status == 'unpaid').toList();

              if (unpaidBills.isEmpty) {
                return _AllPaidCard()
                    .animate()
                    .fadeIn(delay: 250.ms)
                    .slideY(begin: 0.05, end: 0);
              }
              return _PendingBillCard(
                bill: unpaidBills.first,
                userId: widget.userId,
              ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05, end: 0);
            }),

            const SizedBox(height: 24),

            // ── Recent payments ───────────────────────────────────────────────
            const Text('Recent Payments',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary))
                .animate()
                .fadeIn(delay: 300.ms),

            const SizedBox(height: 10),

            Consumer<PaymentProvider>(builder: (_, provider, __) {
              if (provider.loading) {
                return Column(
                    children: List.generate(3, (_) => const ShimmerListTile()));
              }
              final payments = provider.payments.take(4).toList();
              if (payments.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('No payment history',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                );
              }
              return Column(
                children: payments.asMap().entries.map((e) {
                  final i = e.key;
                  final p = e.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 20),
                      ),
                      title: Text('\$${p.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      subtitle: Text(
                        p.billNumber != null
                            ? 'Bill: ${p.billNumber}'
                            : p.transactionId,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(DateFormat('dd MMM').format(p.paymentDate),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500)),
                          const Text('Paid',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 350 + i * 60))
                      .slideX(begin: 0.04, end: 0);
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Welcome card ──────────────────────────────────────────────────────────────
class _WelcomeCard extends StatelessWidget {
  final String name;
  final String? meterNumber;
  const _WelcomeCard({required this.name, this.meterNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hi, $name! 👋',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text(DateFormat('EEEE, MMM d yyyy').format(DateTime.now()),
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
          if (meterNumber != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.speed_rounded, color: Colors.white, size: 13),
                const SizedBox(width: 5),
                Text('Meter: $meterNumber',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ]),
            ),
          ],
        ])),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 36),
        ),
      ]),
    );
  }
}

// ── Quick stat ────────────────────────────────────────────────────────────────
class _QuickStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _QuickStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration:
              BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ])),
      ]),
    );
  }
}

// ── Usage circle ──────────────────────────────────────────────────────────────
class _UsageCircle extends StatelessWidget {
  final double units;
  final double percent;
  const _UsageCircle({required this.units, required this.percent});

  @override
  Widget build(BuildContext context) {
    final color = percent > 0.8
        ? AppColors.error
        : percent > 0.5
            ? AppColors.warning
            : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [
        CircularPercentIndicator(
          radius: 40,
          lineWidth: 7,
          percent: percent,
          center: Text(
            '${units.toStringAsFixed(0)}',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color),
          ),
          progressColor: color,
          backgroundColor: color.withOpacity(0.12),
          circularStrokeCap: CircularStrokeCap.round,
          animation: true,
          animationDuration: 800,
        ),
        const SizedBox(height: 6),
        const Text('units used',
            style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
        Text('this month',
            style: TextStyle(
                fontSize: 9,
                color: AppColors.textHint)),
      ]),
    );
  }
}

// ── All paid card ─────────────────────────────────────────────────────────────
class _AllPaidCard extends StatelessWidget {
  const _AllPaidCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: const Row(children: [
        Icon(Icons.check_circle_rounded, color: AppColors.success, size: 40),
        SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('All Caught Up!',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                  fontSize: 16)),
          Text('No pending bills — great job!',
              style: TextStyle(color: AppColors.success, fontSize: 13)),
        ]),
      ]),
    );
  }
}

// ── Pending bill card ─────────────────────────────────────────────────────────
class _PendingBillCard extends StatelessWidget {
  final BillModel bill;
  final String userId;
  const _PendingBillCard({required this.bill, required this.userId});

  @override
  Widget build(BuildContext context) {
    final isOverdue = bill.dueDate.isBefore(DateTime.now());
    final headerColor = isOverdue ? AppColors.overdue : AppColors.warning;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: headerColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: headerColor.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: headerColor.withOpacity(0.08),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(
                  isOverdue ? Icons.warning_rounded : Icons.pending_rounded,
                  color: headerColor,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  isOverdue ? 'OVERDUE BILL' : 'BILL DUE',
                  style: TextStyle(
                      color: headerColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ]),
              Text(bill.billNumber,
                  style: TextStyle(color: headerColor, fontSize: 12)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  '${AppConstants.monthName(bill.month)} ${bill.year}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  '${bill.unitsConsumed.toStringAsFixed(0)} units consumed',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ]),
              Text(
                '\$${bill.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: headerColor),
              ),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.calendar_today_rounded,
                  size: 12,
                  color: isOverdue ? AppColors.error : AppColors.textSecondary),
              const SizedBox(width: 5),
              Text(
                'Due: ${DateFormat('dd MMM yyyy').format(bill.dueDate)}',
                style: TextStyle(
                    fontSize: 12,
                    color: isOverdue
                        ? AppColors.error
                        : AppColors.textSecondary),
              ),
            ]),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Pay \$${bill.totalAmount.toStringAsFixed(2)} Now',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PaymentScreen(bill: bill)),
              ).then((_) =>
                  context.read<BillProvider>().loadBillsByUser(userId)),
              icon: Icons.payment_rounded,
            ),
          ]),
        ),
      ]),
    );
  }
}
