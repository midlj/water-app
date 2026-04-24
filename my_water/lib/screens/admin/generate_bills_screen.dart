import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/bill_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../models/bill_model.dart';
import '../../widgets/common/custom_button.dart';

class GenerateBillsScreen extends StatefulWidget {
  const GenerateBillsScreen({super.key});

  @override
  State<GenerateBillsScreen> createState() => _GenerateBillsScreenState();
}

class _GenerateBillsScreenState extends State<GenerateBillsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUsers(role: 'client');
      context.read<BillProvider>().loadAllBills();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppColors.primary,
          child: TabBar(
            controller: _tabCtrl,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: const [Tab(text: 'Generate Bill'), Tab(text: 'All Bills')],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: const [_GenerateBillTab(), _AllBillsTab()],
          ),
        ),
      ],
    );
  }
}

class _GenerateBillTab extends StatefulWidget {
  const _GenerateBillTab();

  @override
  State<_GenerateBillTab> createState() => _GenerateBillTabState();
}

class _GenerateBillTabState extends State<_GenerateBillTab> {
  UserModel? _selectedUser;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int _dueDays = 30;

  Future<void> _generate() async {
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client'), backgroundColor: AppColors.warning),
      );
      return;
    }
    final provider = context.read<BillProvider>();
    final ok = await provider.generateBill({
      'userId': _selectedUser!.id,
      'month': _selectedMonth,
      'year': _selectedYear,
      'dueDays': _dueDays,
    });
    if (!mounted) return;
    final snackColor = ok ? AppColors.success : AppColors.error;
    final msg = ok ? provider.successMessage : provider.error;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg ?? ''), backgroundColor: snackColor));
    provider.clearMessages();
    if (ok) setState(() => _selectedUser = null);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = List.generate(5, (i) => now.year - i);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(16)),
            child: const Row(children: [
              Icon(Icons.receipt_long_rounded, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Generate Bill', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                Text('Auto-calculates from meter reading', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),

          const Text('Select Client *', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Consumer<UserProvider>(
            builder: (_, provider, __) => DropdownButtonFormField<UserModel>(
              value: _selectedUser,
              hint: const Text('Choose a client'),
              isExpanded: true,
              decoration: InputDecoration(
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: provider.users.map((u) => DropdownMenuItem(
                value: u,
                child: Text('${u.name} ${u.meterNumber != null ? "(${u.meterNumber})" : ""}', overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (u) => setState(() => _selectedUser = u),
            ),
          ),
          const SizedBox(height: 16),

          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Month *', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedMonth,
                decoration: InputDecoration(filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(AppConstants.monthName(i + 1)))),
                onChanged: (v) => setState(() => _selectedMonth = v!),
              ),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Year *', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _selectedYear,
                decoration: InputDecoration(filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                onChanged: (v) => setState(() => _selectedYear = v!),
              ),
            ])),
          ]),
          const SizedBox(height: 16),

          const Text('Due in (days)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: Slider(
              value: _dueDays.toDouble(),
              min: 7, max: 90, divisions: 17,
              label: '$_dueDays days',
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() => _dueDays = v.round()),
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(8)),
              child: Text('$_dueDays days', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
            ),
          ]),
          const SizedBox(height: 24),

          Consumer<BillProvider>(
            builder: (_, p, __) => PrimaryButton(
              label: 'Generate Bill',
              onPressed: _generate,
              isLoading: p.loading,
              icon: Icons.auto_awesome_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllBillsTab extends StatelessWidget {
  const _AllBillsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<BillProvider>(
      builder: (_, provider, __) {
        if (provider.loading) return const Center(child: CircularProgressIndicator());
        if (provider.bills.isEmpty) {
          return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.textHint),
            SizedBox(height: 12),
            Text('No bills generated yet', style: TextStyle(color: AppColors.textSecondary)),
          ]));
        }
        return RefreshIndicator(
          onRefresh: () => provider.loadAllBills(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.bills.length,
            itemBuilder: (_, i) => _BillCard(bill: provider.bills[i]),
          ),
        );
      },
    );
  }
}

class _BillCard extends StatelessWidget {
  final BillModel bill;
  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final isPaid = bill.status == 'paid';
    final statusColor = isPaid ? AppColors.paid : AppColors.unpaid;
    final statusBg = isPaid ? AppColors.successLight : AppColors.warningLight;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(bill.billNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
              child: Text(bill.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 6),
          if (bill.userName != null)
            Text(bill.userName!, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text('${AppConstants.monthName(bill.month)} ${bill.year} • ${bill.unitsConsumed.toStringAsFixed(0)} units',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const Divider(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Due Date', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
              Text(DateFormat('dd MMM yyyy').format(bill.dueDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            ]),
            Text('\$${bill.totalAmount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: statusColor)),
          ]),
        ]),
      ),
    );
  }
}
