import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';

class RegisterMemberScreen extends StatefulWidget {
  const RegisterMemberScreen({super.key});

  @override
  State<RegisterMemberScreen> createState() => _RegisterMemberScreenState();
}

class _RegisterMemberScreenState extends State<RegisterMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _membershipType = 'monthly';
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30));
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  bool _success = false;

  final _membershipOptions = [
    ('monthly', 'Monthly', '30 days'),
    ('quarterly', 'Quarterly', '90 days'),
    ('annual', 'Annual', '365 days'),
  ];

  void _onMembershipChange(String type) {
    setState(() {
      _membershipType = type;
      final now = DateTime.now();
      _expiryDate = switch (type) {
        'quarterly' => now.add(const Duration(days: 90)),
        'annual' => now.add(const Duration(days: 365)),
        _ => now.add(const Duration(days: 30)),
      };
    });
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService().registerMember(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        phone: _phoneCtrl.text.trim(),
        membershipType: _membershipType,
        membershipExpiry: _expiryDate,
      );
      setState(() {
        _success = true;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _reset() {
    _formKey.currentState?.reset();
    _nameCtrl.clear();
    _emailCtrl.clear();
    _passCtrl.clear();
    _phoneCtrl.clear();
    setState(() {
      _success = false;
      _membershipType = 'monthly';
      _expiryDate = DateTime.now().add(const Duration(days: 30));
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        foregroundColor: Colors.white,
        title: const Text('Register Member',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: false,
        elevation: 0,
      ),
      body: _success ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: AppTheme.greenDim,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: AppTheme.green, size: 48),
            ),
            const SizedBox(height: 24),
            const Text('Member Registered!', style: AppTheme.displayMd),
            const SizedBox(height: 12),
            Text(
              '${_nameCtrl.text} has been registered successfully.\nThey can now log in with their email and password.',
              textAlign: TextAlign.center,
              style: AppTheme.bodyMuted,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.card(),
              child: Column(
                children: [
                  _infoRow('Name', _nameCtrl.text),
                  _infoRow('Email', _emailCtrl.text),
                  _infoRow('Phone', _phoneCtrl.text),
                  _infoRow('Membership', _membershipType),
                  _infoRow('Expires',
                      '${_expiryDate.day}/${_expiryDate.month}/${_expiryDate.year}'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppTheme.border),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Go Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _reset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Add Another'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.bodyMuted),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('PERSONAL INFORMATION'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: AppTheme.inputDecoration('Full Name',
                  icon: Icons.person_outline),
              validator: (v) =>
                  (v?.trim().isNotEmpty ?? false) ? null : 'Required',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: Colors.white),
              decoration: AppTheme.inputDecoration('Phone Number',
                  icon: Icons.phone_outlined),
              validator: (v) =>
                  (v?.trim().isNotEmpty ?? false) ? null : 'Required',
            ),
            const SizedBox(height: 28),
            _sectionLabel('ACCOUNT CREDENTIALS'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: AppTheme.inputDecoration('Email Address',
                  icon: Icons.email_outlined),
              validator: (v) =>
                  (v?.contains('@') ?? false) ? null : 'Valid email required',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscure,
              style: const TextStyle(color: Colors.white),
              decoration:
                  AppTheme.inputDecoration('Password', icon: Icons.lock_outline)
                      .copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppTheme.textMuted,
                      size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) =>
                  (v?.length ?? 0) >= 6 ? null : 'Min 6 characters',
            ),
            const SizedBox(height: 28),
            _sectionLabel('MEMBERSHIP PLAN'),
            const SizedBox(height: 12),
            Row(
              children: _membershipOptions.map((opt) {
                final (type, label, days) = opt;
                final selected = _membershipType == type;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onMembershipChange(type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selected ? AppTheme.primaryDim : AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? AppTheme.primary : AppTheme.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(label,
                              style: TextStyle(
                                color:
                                    selected ? AppTheme.primary : Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              )),
                          const SizedBox(height: 4),
                          Text(days,
                              style: TextStyle(
                                color: selected
                                    ? AppTheme.primaryLight
                                    : AppTheme.textMuted,
                                fontSize: 11,
                              )),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: AppTheme.card(),
              child: Row(
                children: [
                  const Icon(Icons.event_outlined,
                      color: AppTheme.textMuted, size: 20),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Membership expires',
                          style: AppTheme.bodyMuted),
                      Text(
                        '${_expiryDate.day} / ${_expiryDate.month} / ${_expiryDate.year}',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.redDim,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppTheme.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: AppTheme.red, fontSize: 13))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Register Member',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        )),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text, style: AppTheme.label);
}
