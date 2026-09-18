import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../app_theme.dart';
import '../models/gym_user.dart';
import '../services/auth_service.dart';

class MemberDetailScreen extends StatefulWidget {
  final GymUser member;
  const MemberDetailScreen({super.key, required this.member});

  @override
  State<MemberDetailScreen> createState() => _MemberDetailScreenState();
}

class _MemberDetailScreenState extends State<MemberDetailScreen> {
  late GymUser _member;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
  }

  Future<void> _toggleStatus() async {
    setState(() => _toggling = true);
    await AuthService().toggleMemberStatus(_member.uid, !_member.isActive);
    setState(() {
      _member = GymUser(
        uid: _member.uid,
        name: _member.name,
        email: _member.email,
        role: _member.role,
        phone: _member.phone,
        membershipType: _member.membershipType,
        membershipExpiry: _member.membershipExpiry,
        qrCode: _member.qrCode,
        photoUrl: _member.photoUrl,
        createdAt: _member.createdAt,
        isActive: !_member.isActive,
      );
      _toggling = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(_member.isActive ? 'Member activated' : 'Member deactivated'),
        backgroundColor: _member.isActive ? AppTheme.green : AppTheme.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _member.isMembershipActive;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        foregroundColor: Colors.white,
        title: const Text('Member Details',
            style: TextStyle(fontWeight: FontWeight.w700)),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _member.isActive
                  ? Icons.block_outlined
                  : Icons.check_circle_outline,
              color: _member.isActive ? AppTheme.red : AppTheme.green,
            ),
            onPressed: _toggling ? null : _toggleStatus,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar + Name
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor:
                        active ? AppTheme.primaryDim : AppTheme.bgCardAlt,
                    child: Text(
                      _member.name.isNotEmpty
                          ? _member.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: active ? AppTheme.primary : AppTheme.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_member.name, style: AppTheme.displayMd),
                  const SizedBox(height: 4),
                  Text(_member.email, style: AppTheme.bodyMuted),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? AppTheme.greenDim : AppTheme.redDim,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      active
                          ? '${_member.daysRemaining} days remaining'
                          : 'Membership Expired',
                      style: TextStyle(
                        color: active ? AppTheme.green : AppTheme.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // QR Code card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.card(glowPrimary: true),
              child: Column(
                children: [
                  const Text('MEMBER QR CODE', style: AppTheme.label),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: _member.uid,
                      version: QrVersions.auto,
                      size: 180,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Admin scans this to record attendance',
                      style: AppTheme.bodyMuted, textAlign: TextAlign.center),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Info card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.card(),
              child: Column(
                children: [
                  _row('Phone', _member.phone ?? '—', Icons.phone_outlined),
                  _divider(),
                  _row('Membership', _member.membershipType ?? '—',
                      Icons.card_membership_outlined),
                  _divider(),
                  _row(
                      'Expiry Date',
                      _member.membershipExpiry != null
                          ? '${_member.membershipExpiry!.day}/${_member.membershipExpiry!.month}/${_member.membershipExpiry!.year}'
                          : '—',
                      Icons.event_outlined),
                  _divider(),
                  _row(
                      'Joined',
                      '${_member.createdAt.day}/${_member.createdAt.month}/${_member.createdAt.year}',
                      Icons.person_outlined),
                  _divider(),
                  _row('Status', _member.isActive ? 'Active' : 'Inactive',
                      Icons.circle,
                      color: _member.isActive ? AppTheme.green : AppTheme.red),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Deactivate button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _toggling ? null : _toggleStatus,
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      _member.isActive ? AppTheme.red : AppTheme.green,
                  side: BorderSide(
                      color: _member.isActive ? AppTheme.red : AppTheme.green),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _member.isActive ? 'Deactivate Member' : 'Activate Member',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? AppTheme.textMuted),
          const SizedBox(width: 12),
          Text(label, style: AppTheme.bodyMuted),
          const Spacer(),
          Text(value,
              style: TextStyle(
                color: color ?? Colors.white,
                fontWeight: FontWeight.w600,
              )),
        ],
      ),
    );
  }

  Widget _divider() => const Divider(color: AppTheme.border, height: 1);
}
