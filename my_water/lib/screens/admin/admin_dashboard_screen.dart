import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../providers/bill_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/stat_card.dart';

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
      onRefresh: () async => _loadData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, ${user?.name.split(' ').first ?? 'Admin'}!',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(DateFormat('EEEE, MMM d yyyy').format(DateTime.now()),
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 32),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats grid
            const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            Consumer<UserProvider>(
              builder: (_, provider, __) {
                final s = provider.stats;
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    StatCard(
                      title: 'Total Clients',
                      value: '${s['totalClients'] ?? 0}',
                      icon: Icons.people_rounded,
                      color: AppColors.primary,
                      bgColor: AppColors.infoLight,
                    ),
                    StatCard(
                      title: 'Active Clients',
                      value: '${s['activeClients'] ?? 0}',
                      icon: Icons.person_outline_rounded,
                      color: AppColors.success,
                      bgColor: AppColors.successLight,
                    ),
                    StatCard(
                      title: 'Total Bills',
                      value: '${s['totalBills'] ?? 0}',
                      icon: Icons.receipt_long_rounded,
                      color: AppColors.accent,
                      bgColor: AppColors.infoLight,
                    ),
                    StatCard(
                      title: 'Unpaid Bills',
                      value: '${s['unpaidBills'] ?? 0}',
                      icon: Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      bgColor: AppColors.warningLight,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Consumer<UserProvider>(
              builder: (_, provider, __) {
                final revenue = (provider.stats['totalRevenue'] ?? 0.0).toDouble();
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.cardGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_money_rounded, color: Colors.white, size: 36),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Revenue Collected', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text('\$${revenue.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Recent bills
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Bills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                TextButton(onPressed: () {}, child: const Text('View All')),
              ],
            ),
            const SizedBox(height: 8),
            Consumer<BillProvider>(
              builder: (_, provider, __) {
                if (provider.loading) return const Center(child: CircularProgressIndicator());
                final bills = provider.bills.take(5).toList();
                if (bills.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No bills yet')));
                }
                return Column(
                  children: bills.map((bill) {
                    final color = bill.isPaid ? AppColors.paid : AppColors.unpaid;
                    final bgColor = bill.isPaid ? AppColors.successLight : AppColors.warningLight;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: bgColor,
                          child: Icon(bill.isPaid ? Icons.check_circle_outline : Icons.pending_outlined, color: color, size: 22),
                        ),
                        title: Text(bill.billNumber, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text('${bill.userName ?? ''} • ${_monthName(bill.month)} ${bill.year}',
                            style: const TextStyle(fontSize: 12)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('\$${bill.totalAmount.toStringAsFixed(2)}',
                                style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                            Text(bill.status.toUpperCase(), style: TextStyle(fontSize: 10, color: color)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 16),
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
