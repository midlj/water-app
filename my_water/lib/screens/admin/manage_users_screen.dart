import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/user_provider.dart';
import '../../models/user_model.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_text_field.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateUserDialog,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Client'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppTextField(
              label: 'Search clients',
              hint: 'Name, email or meter number...',
              controller: _searchCtrl,
              prefixIcon: const Icon(Icons.search, size: 20),
              onChanged: (v) => context.read<UserProvider>().loadUsers(role: 'client', search: v),
            ),
          ),
          Expanded(
            child: Consumer<UserProvider>(
              builder: (_, provider, __) {
                if (provider.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.error != null) {
                  return Center(child: Text(provider.error!, style: const TextStyle(color: AppColors.error)));
                }
                if (provider.users.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: AppColors.textHint),
                        SizedBox(height: 12),
                        Text('No clients found', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => provider.loadUsers(role: 'client'),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                    itemCount: provider.users.length,
                    itemBuilder: (_, i) {
                      final user = provider.users[i];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: user.isActive ? AppColors.infoLight : Colors.grey.shade100,
                            child: Text(
                              user.name.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: user.isActive ? AppColors.primary : Colors.grey,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.email, style: const TextStyle(fontSize: 12)),
                              if (user.meterNumber != null)
                                Text('Meter: ${user.meterNumber}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: user.isActive ? AppColors.successLight : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  user.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: user.isActive ? AppColors.success : Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                                onPressed: () => _showEditUserDialog(user),
                              ),
                            ],
                          ),
                          isThreeLine: user.meterNumber != null,
                        ),
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
    _nameCtrl.dispose(); _emailCtrl.dispose(); _passCtrl.dispose();
    _phoneCtrl.dispose(); _addressCtrl.dispose(); _meterCtrl.dispose();
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
        const SnackBar(content: Text('Client created successfully'), backgroundColor: AppColors.success),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Error'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Client', style: TextStyle(fontWeight: FontWeight.w700)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(label: 'Full Name *', controller: _nameCtrl,
                    validator: (v) => v!.trim().isEmpty ? 'Name required' : null),
                const SizedBox(height: 12),
                AppTextField(label: 'Email *', controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v!.contains('@') ? null : 'Valid email required'),
                const SizedBox(height: 12),
                AppTextField(label: 'Password *', controller: _passCtrl, obscureText: true,
                    validator: (v) => v!.length >= 6 ? null : 'Min 6 characters'),
                const SizedBox(height: 12),
                AppTextField(label: 'Phone', controller: _phoneCtrl, keyboardType: TextInputType.phone),
                const SizedBox(height: 12),
                AppTextField(label: 'Address', controller: _addressCtrl, maxLines: 2),
                const SizedBox(height: 12),
                AppTextField(label: 'Meter Number', controller: _meterCtrl),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        Consumer<UserProvider>(
          builder: (_, p, __) => ElevatedButton(
            onPressed: p.loading ? null : _submit,
            child: p.loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create'),
          ),
        ),
      ],
    );
  }
}

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
    _nameCtrl.dispose(); _phoneCtrl.dispose(); _addressCtrl.dispose(); _meterCtrl.dispose();
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
      title: const Text('Edit Client', style: TextStyle(fontWeight: FontWeight.w700)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(label: 'Full Name', controller: _nameCtrl,
                  validator: (v) => v!.trim().isEmpty ? 'Name required' : null),
              const SizedBox(height: 12),
              AppTextField(label: 'Phone', controller: _phoneCtrl, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              AppTextField(label: 'Address', controller: _addressCtrl, maxLines: 2),
              const SizedBox(height: 12),
              AppTextField(label: 'Meter Number', controller: _meterCtrl),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Active Account', style: TextStyle(fontSize: 14)),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
