import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/shimmer_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    context.read<UserProvider>().loadStats();
    context.read<BillProvider>().loadAllBills();
    context.read<PaymentProvider>().loadAllPayments();
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
            // ── Greeting hero ─────────────────────────────────────────────────
            _GreetingCard(name: user?.name.split(' ').first ?? 'Admin')
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: -0.12, end: 0),

            const SizedBox(height: 24),

            // ── Stats grid ────────────────────────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Overview',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              TextButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ]).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 10),

            Consumer<UserProvider>(builder: (_, provider, __) {
              if (provider.loading) return const ShimmerStatGrid();
              final s = provider.stats;
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: [
                  _StatCard(
                    title: 'Total Clients',
                    value: '${s['totalClients'] ?? 0}',
                    icon: Icons.people_rounded,
                    color: AppColors.primary,
                    bgColor: AppColors.infoLight,
                    index: 0,
                  ),
                  _StatCard(
                    title: 'Active Clients',
                    value: '${s['activeClients'] ?? 0}',
                    icon: Icons.verified_user_rounded,
                    color: AppColors.success,
                    bgColor: AppColors.successLight,
                    index: 1,
                  ),
                  _StatCard(
                    title: 'Total Bills',
                    value: '${s['totalBills'] ?? 0}',
                    icon: Icons.receipt_long_rounded,
                    color: AppColors.accent,
                    bgColor: AppColors.infoLight,
                    index: 2,
                  ),
                  _StatCard(
                    title: 'Unpaid Bills',
                    value: '${s['unpaidBills'] ?? 0}',
                    icon: Icons.pending_actions_rounded,
                    color: AppColors.warning,
                    bgColor: AppColors.warningLight,
                    index: 3,
                  ),
                ],
              );
            }),

            const SizedBox(height: 12),

            // ── Revenue card ──────────────────────────────────────────────────
            Consumer<UserProvider>(builder: (_, provider, __) {
              if (provider.loading) {
                return const ShimmerCard(height: 90);
              }
              final revenue = (provider.stats['totalRevenue'] ?? 0.0).toDouble();
              return _RevenueCard(revenue: revenue)
                  .animate()
                  .fadeIn(delay: 350.ms)
                  .slideX(begin: 0.05, end: 0);
            }),

            const SizedBox(height: 24),

            // ── Recent bills ──────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Bills',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Last 5',
                      style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms),

            const SizedBox(height: 10),

            Consumer<BillProvider>(builder: (_, provider, __) {
              if (provider.loading) {
                return Column(
                  children: List.generate(3, (_) => const ShimmerListTile()),
                );
              }
              final bills = provider.bills.take(5).toList();
              if (bills.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(children: [
                      Icon(Icons.receipt_long_outlined,
                          size: 56, color: AppColors.textHint.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      const Text('No bills yet',
                          style: TextStyle(color: AppColors.textSecondary)),
                    ]),
                  ),
                );
              }
              return Column(
                children: bills.asMap().entries.map((e) {
                  final i = e.key;
                  final bill = e.value;
                  return _BillListTile(bill: bill)
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: 450 + i * 60))
                      .slideX(begin: 0.05, end: 0);
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Greeting card ─────────────────────────────────────────────────────────────
class _GreetingCard extends StatelessWidget {
  final String name;
  const _GreetingCard({required this.name});

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
          Text(
            'Hello, $name! 👋',
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, MMM d yyyy').format(DateTime.now()),
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Admin Dashboard',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
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

// ── Stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final int index;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800, color: color, height: 1.1)),
            const SizedBox(height: 2),
            Text(title,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500)),
          ]),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 200 + index * 60))
        .scale(begin: const Offset(0.92, 0.92), duration: 300.ms);
  }
}

// ── Revenue card ──────────────────────────────────────────────────────────────
class _RevenueCard extends StatelessWidget {
  final double revenue;
  const _RevenueCard({required this.revenue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.3),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.account_balance_wallet_rounded,
              color: Colors.white, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Total Revenue Collected',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            '\$${revenue.toStringAsFixed(2)}',
            style: const TextStyle(
                color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
          ),
        ])),
        const Icon(Icons.trending_up_rounded, color: Colors.white54, size: 28),
      ]),
    );
  }
}

// ── Bill list tile ────────────────────────────────────────────────────────────
class _BillListTile extends StatelessWidget {
  final dynamic bill;
  const _BillListTile({required this.bill});

  @override
  Widget build(BuildContext context) {
    final isPaid = bill.isPaid as bool;
    final color = isPaid ? AppColors.paid : AppColors.unpaid;
    final bgColor = isPaid ? AppColors.successLight : AppColors.warningLight;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
          child: Icon(
            isPaid ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: color,
            size: 20,
          ),
        ),
        title: Text(bill.billNumber as String,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          '${bill.userName ?? ''} · ${_monthName(bill.month as int)} ${bill.year}',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${(bill.totalAmount as double).toStringAsFixed(2)}',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: color, fontSize: 14),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                (bill.status as String).toUpperCase(),
                style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m - 1];
}
