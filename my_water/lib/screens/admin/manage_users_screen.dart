import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/shimmer_card.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUsers(role: 'client');
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showCreateUserDialog() {
    showDialog(context: context, builder: (_) => const _CreateUserDialog());
  }

  void _showEditUserDialog(UserModel user) {
    showDialog(context: context, builder: (_) => _EditUserDialog(user: user));
  }

  void _showQrCode(UserModel user) {
    if (user.meterNumber == null || user.meterNumber!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No meter number assigned to this client'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _QrBottomSheet(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateUserDialog,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Client'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: AppTextField(
              label: 'Search clients',
              hint: 'Name, email or meter number...',
              controller: _searchCtrl,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              onChanged: (v) =>
                  context.read<UserProvider>().loadUsers(role: 'client', search: v),
            ),
          ).animate().fadeIn(duration: 350.ms).slideY(begin: -0.1, end: 0),

          // ── List ────────────────────────────────────────────────────────────
          Expanded(
            child: Consumer<UserProvider>(
              builder: (_, provider, __) {
                if (provider.loading) {
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: 5,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: ShimmerListTile(),
                    ),
                  );
                }
                if (provider.error != null) {
                  return Center(
                    child: Text(provider.error!,
                        style: const TextStyle(color: AppColors.error)),
                  );
                }
                if (provider.users.isEmpty) {
                  return Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.people_outline_rounded,
                          size: 72, color: AppColors.textHint.withOpacity(0.4)),
                      const SizedBox(height: 14),
                      const Text('No clients found',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 15)),
                    ]),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () =>
                      provider.loadUsers(role: 'client'),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                    itemCount: provider.users.length,
                    itemBuilder: (_, i) {
                      final user = provider.users[i];
                      return _UserCard(
                        user: user,
                        onEdit: () => _showEditUserDialog(user),
                        onQr: () => _showQrCode(user),
                        index: i,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── User card ─────────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback onEdit;
  final VoidCallback onQr;
  final int index;

  const _UserCard({
    required this.user,
    required this.onEdit,
    required this.onQr,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: user.isActive
                ? AppColors.primary.withOpacity(0.12)
                : Colors.grey.shade100,
            child: Text(
              user.name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: user.isActive ? AppColors.primary : Colors.grey,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(user.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: user.isActive ? AppColors.successLight : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    user.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: user.isActive ? AppColors.success : Colors.grey,
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 3),
              Text(user.email,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis),
              if (user.meterNumber != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.speed_rounded, size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(user.meterNumber!,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ]),
              ],
            ],
          )),

          const SizedBox(width: 6),

          // Actions
          Column(mainAxisSize: MainAxisSize.min, children: [
            _ActionBtn(
              icon: Icons.qr_code_rounded,
              color: AppColors.accent,
              bgColor: AppColors.infoLight,
              onTap: onQr,
              tooltip: 'Show QR',
            ),
            const SizedBox(height: 6),
            _ActionBtn(
              icon: Icons.edit_outlined,
              color: AppColors.primary,
              bgColor: AppColors.infoLight,
              onTap: onEdit,
              tooltip: 'Edit',
            ),
          ]),
        ]),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 60 * index))
        .slideX(begin: 0.05, end: 0, delay: Duration(milliseconds: 60 * index));
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
      ),
    );
  }
}

// ── QR bottom sheet ───────────────────────────────────────────────────────────
class _QrBottomSheet extends StatelessWidget {
  final UserModel user;
  const _QrBottomSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),

        // Header
        CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.infoLight,
          child: Text(
            user.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 24),
          ),
        ),
        const SizedBox(height: 10),
        Text(user.name,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(user.email,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.infoLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Meter: ${user.meterNumber}',
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary),
          ),
        ),

        const SizedBox(height: 24),

        // QR code
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: QrImageView(
            data: user.meterNumber!,
            version: QrVersions.auto,
            size: 200,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: AppColors.primaryDark,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: AppColors.primary,
            ),
          ),
        ),

        const SizedBox(height: 16),
        const Text(
          'Admin can scan this QR to auto-select the client\nwhen recording meter readings.',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12, color: AppColors.textHint, height: 1.5),
        ),
      ]).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
    );
  }
}

// ── Create user dialog ────────────────────────────────────────────────────────
class _CreateUserDialog extends StatefulWidget {
  const _CreateUserDialog();

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _meterCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _meterCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<UserProvider>();
    final ok = await provider.createUser({
      'name': _nameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'password': _passCtrl.text,
      'phone': _phoneCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'meterNumber': _meterCtrl.text.trim(),
      'role': 'client',
    });
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client created successfully'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Error'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Client',
          style: TextStyle(fontWeight: FontWeight.w700)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AppTextField(
                  label: 'Full Name *',
                  controller: _nameCtrl,
                  validator: (v) =>
                      v!.trim().isEmpty ? 'Name required' : null),
              const SizedBox(height: 12),
              AppTextField(
                  label: 'Email *',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      v!.contains('@') ? null : 'Valid email required'),
              const SizedBox(height: 12),
              AppTextField(
                  label: 'Password *',
                  controller: _passCtrl,
                  obscureText: true,
                  validator: (v) =>
                      v!.length >= 6 ? null : 'Min 6 characters'),
              const SizedBox(height: 12),
              AppTextField(
                  label: 'Phone',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              AppTextField(
                  label: 'Address', controller: _addressCtrl, maxLines: 2),
              const SizedBox(height: 12),
              AppTextField(
                  label: 'Meter Number', controller: _meterCtrl),
            ]),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        Consumer<UserProvider>(
          builder: (_, p, __) => ElevatedButton(
            onPressed: p.loading ? null : _submit,
            child: p.loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Create'),
          ),
        ),
      ],
    );
  }
}

// ── Edit user dialog ──────────────────────────────────────────────────────────
class _EditUserDialog extends StatefulWidget {
  final UserModel user;
  const _EditUserDialog({required this.user});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _meterCtrl;
  late bool _isActive;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user.name);
    _phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
    _addressCtrl = TextEditingController(text: widget.user.address ?? '');
    _meterCtrl = TextEditingController(text: widget.user.meterNumber ?? '');
    _isActive = widget.user.isActive;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _meterCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<UserProvider>().updateUser(widget.user.id, {
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'meterNumber': _meterCtrl.text.trim(),
      'isActive': _isActive,
    });
    if (!mounted) return;
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Client',
          style: TextStyle(fontWeight: FontWeight.w700)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AppTextField(
                label: 'Full Name',
                controller: _nameCtrl,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Name required' : null),
            const SizedBox(height: 12),
            AppTextField(
                label: 'Phone',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            AppTextField(
                label: 'Address', controller: _addressCtrl, maxLines: 2),
            const SizedBox(height: 12),
            AppTextField(label: 'Meter Number', controller: _meterCtrl),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Active Account',
                  style: TextStyle(fontSize: 14)),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primary,
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        Consumer<UserProvider>(
          builder: (_, p, __) => ElevatedButton(
            onPressed: p.loading ? null : _submit,
            child: const Text('Update'),
          ),
        ),
      ],
    );
  }
}
