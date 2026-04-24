import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/meter_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';
import 'qr_scanner_screen.dart';

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
  bool _scannedMatch = false;

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

  void _onQrScanned(String value, List<UserModel> users) {
    final match = users.cast<UserModel?>().firstWhere(
      (u) => u?.meterNumber?.toUpperCase() == value.toUpperCase(),
      orElse: () => null,
    );
    if (match != null) {
      setState(() {
        _selectedUser = match;
        _scannedMatch = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Matched: ${match.name} (${match.meterNumber})'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No client for meter: $value'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _openScanner(List<UserModel> users) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(
          onScanned: (v) => _onQrScanned(v, users),
          title: 'Scan Meter',
          subtitle: 'Point camera at meter QR code or barcode',
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a client'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
        SnackBar(
          content: Text(provider.successMessage ?? 'Reading recorded!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      _readingCtrl.clear();
      _notesCtrl.clear();
      setState(() {
        _selectedUser = null;
        _scannedMatch = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Error'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    provider.clearMessages();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final years = List.generate(5, (i) => now.year - i);

    return Consumer<UserProvider>(
      builder: (_, userProvider, __) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── QR Scan Hero ──────────────────────────────────────────────
                _ScanHeroCard(
                  onScan: () => _openScanner(userProvider.users),
                  scannedUser: _scannedMatch ? _selectedUser : null,
                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.15, end: 0),

                const SizedBox(height: 24),

                // ── Divider ───────────────────────────────────────────────────
                Row(children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR SELECT MANUALLY',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ]).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 20),

                // ── Client dropdown ───────────────────────────────────────────
                _sectionLabel('Client *'),
                const SizedBox(height: 8),
                DropdownButtonFormField<UserModel>(
                  value: _selectedUser,
                  hint: const Text('Choose a client'),
                  decoration: _inputDecoration(prefixIcon: Icons.person_search_rounded),
                  isExpanded: true,
                  items: userProvider.users.map((u) => DropdownMenuItem(
                    value: u,
                    child: Text(
                      '${u.name}${u.meterNumber != null ? " · ${u.meterNumber}" : ""}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  )).toList(),
                  onChanged: (u) => setState(() {
                    _selectedUser = u;
                    _scannedMatch = false;
                  }),
                ).animate().fadeIn(delay: 150.ms).slideX(begin: 0.05, end: 0),

                // ── Selected client pill ──────────────────────────────────────
                if (_selectedUser != null) ...[
                  const SizedBox(height: 10),
                  _ClientPill(user: _selectedUser!, isQrMatch: _scannedMatch)
                      .animate()
                      .scale(begin: const Offset(0.95, 0.95), duration: 250.ms)
                      .fadeIn(),
                ],

                const SizedBox(height: 20),

                // ── Month & Year ──────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Month *'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _selectedMonth,
                          decoration: _inputDecoration(),
                          items: List.generate(12, (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(AppConstants.monthName(i + 1)),
                          )),
                          onChanged: (v) => setState(() => _selectedMonth = v!),
                        ),
                      ],
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('Year *'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          value: _selectedYear,
                          decoration: _inputDecoration(),
                          items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                          onChanged: (v) => setState(() => _selectedYear = v!),
                        ),
                      ],
                    )),
                  ],
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 16),

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
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 16),

                AppTextField(
                  label: 'Notes (optional)',
                  controller: _notesCtrl,
                  maxLines: 3,
                  hint: 'Any additional notes...',
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 24),

                Consumer<MeterProvider>(
                  builder: (_, p, __) => PrimaryButton(
                    label: 'Record Reading',
                    onPressed: _submit,
                    isLoading: p.loading,
                    icon: Icons.save_rounded,
                  ),
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2, end: 0),

                const SizedBox(height: 20),
                _TariffInfoCard().animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontSize: 13,
        ),
      );

  InputDecoration _inputDecoration({IconData? prefixIcon}) => InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: AppColors.textSecondary) : null,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      );
}

// ── Scan hero card ────────────────────────────────────────────────────────────
class _ScanHeroCard extends StatelessWidget {
  final VoidCallback onScan;
  final UserModel? scannedUser;
  const _ScanHeroCard({required this.onScan, this.scannedUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.speed_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add Meter Reading',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
              Text('Scan QR or select client manually',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          )),
        ]),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onScan,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 26),
              const SizedBox(width: 10),
              Text(
                'Scan Meter QR / Barcode',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ]),
          ),
        ),
        if (scannedUser != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                'Matched: ${scannedUser!.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

// ── Selected client pill ───────────────────────────────────────────────────────
class _ClientPill extends StatelessWidget {
  final UserModel user;
  final bool isQrMatch;
  const _ClientPill({required this.user, required this.isQrMatch});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.primary.withOpacity(0.15),
          child: Text(
            user.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.name,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            if (user.meterNumber != null)
              Text('Meter: ${user.meterNumber}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        )),
        if (isQrMatch)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.qr_code_2_rounded, size: 13, color: AppColors.success),
              SizedBox(width: 4),
              Text('Scanned',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success)),
            ]),
          ),
      ]),
    );
  }
}

// ── Tariff info card ───────────────────────────────────────────────────────────
class _TariffInfoCard extends StatelessWidget {
  const _TariffInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
          SizedBox(width: 8),
          Text('Tariff Information',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 14)),
        ]),
        const SizedBox(height: 12),
        const _TariffRow(label: '0 – 10 units', value: '\$2.00 / unit'),
        const _TariffRow(label: '11 – 20 units', value: '\$3.00 / unit'),
        const _TariffRow(label: '21+ units', value: '\$4.50 / unit'),
        const Divider(height: 16, color: AppColors.divider),
        const _TariffRow(label: 'Service charge', value: '\$5.00 flat'),
        const _TariffRow(label: 'Tax', value: '5% on water charges'),
      ]),
    );
  }
}

class _TariffRow extends StatelessWidget {
  final String label;
  final String value;
  const _TariffRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ]),
    );
  }
}
