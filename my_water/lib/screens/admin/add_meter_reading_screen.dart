import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/meter_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

class AddMeterReadingScreen extends StatefulWidget {
  const AddMeterReadingScreen({super.key});

  @override
  State<AddMeterReadingScreen> createState() => _AddMeterReadingScreenState();
}

class _AddMeterReadingScreenState extends State<AddMeterReadingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _readingCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  UserModel? _selectedUser;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUsers(role: 'client');
    });
  }

  @override
  void dispose() {
    _readingCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a client'), backgroundColor: AppColors.warning),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<MeterProvider>();
    final ok = await provider.addReading({
      'userId': _selectedUser!.id,
      'reading': double.parse(_readingCtrl.text),
      'month': _selectedMonth,
      'year': _selectedYear,
      'notes': _notesCtrl.text.trim(),
    });

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.successMessage ?? 'Reading recorded!'), backgroundColor: AppColors.success),
      );
      _readingCtrl.clear();
      _notesCtrl.clear();
      setState(() => _selectedUser = null);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Error'), backgroundColor: AppColors.error),
      );
    }
    provider.clearMessages();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = List.generate(5, (i) => now.year - i);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.speed_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add Meter Reading', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                        Text('Record monthly water consumption', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Client selection
            const Text('Select Client *', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Consumer<UserProvider>(
              builder: (_, provider, __) {
                return DropdownButtonFormField<UserModel>(
                  value: _selectedUser,
                  hint: const Text('Choose a client'),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                  ),
                  isExpanded: true,
                  items: provider.users.map((u) => DropdownMenuItem(
                    value: u,
                    child: Text('${u.name} ${u.meterNumber != null ? "(${u.meterNumber})" : ""}', overflow: TextOverflow.ellipsis),
                  )).toList(),
                  onChanged: (u) => setState(() => _selectedUser = u),
                );
              },
            ),
            const SizedBox(height: 16),

            // Month & Year row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Month *', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _selectedMonth,
                        decoration: InputDecoration(
                          filled: true, fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                        ),
                        items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(AppConstants.monthName(i + 1)))),
                        onChanged: (v) => setState(() => _selectedMonth = v!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Year *', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: _selectedYear,
                        decoration: InputDecoration(
                          filled: true, fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                        ),
                        items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                        onChanged: (v) => setState(() => _selectedYear = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Reading value
            AppTextField(
              label: 'Current Meter Reading (units) *',
              hint: 'e.g. 1250',
              controller: _readingCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              prefixIcon: const Icon(Icons.speed_outlined, size: 20),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Reading value is required';
                if (double.tryParse(v) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            AppTextField(label: 'Notes (optional)', controller: _notesCtrl, maxLines: 3,
                hint: 'Any additional notes about this reading...'),
            const SizedBox(height: 24),

            Consumer<MeterProvider>(
              builder: (_, p, __) => PrimaryButton(
                label: 'Record Reading',
                onPressed: _submit,
                isLoading: p.loading,
                icon: Icons.save_rounded,
              ),
            ),
            const SizedBox(height: 24),

            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text('Tariff Information', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
                  ]),
                  SizedBox(height: 8),
                  Text('• 0–10 units: \$2.00/unit\n• 11–20 units: \$3.00/unit\n• 21+ units: \$4.50/unit\n• Service charge: \$5.00 flat\n• Tax: 5% on water charges',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
