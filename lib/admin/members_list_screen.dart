import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../services/auth_service.dart';
import '../models/gym_user.dart';
import 'member_detail_screen.dart';
import 'register_member_screen.dart';

class MembersListScreen extends StatefulWidget {
  const MembersListScreen({super.key});

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  List<GymUser> _all = [];
  List<GymUser> _filtered = [];
  bool _loading = true;
  String _search = '';
  String _filter = 'all'; // all | active | expired

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final members = await AuthService().getAllMembers();
      setState(() {
        _all = members;
        _apply();
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  void _apply() {
    var list = _all.where((m) {
      final q = _search.toLowerCase();
      return m.name.toLowerCase().contains(q) ||
          m.email.toLowerCase().contains(q);
    }).toList();

    if (_filter == 'active') {
      list = list.where((m) => m.isMembershipActive).toList();
    }
    if (_filter == 'expired') {
      list = list.where((m) => !m.isMembershipActive).toList();
    }

    _filtered = list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        foregroundColor: Colors.white,
        title: const Text('Members',
            style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: false,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: AppTheme.primary),
            onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RegisterMemberScreen()))
                .then((_) => _load()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              children: [
                // Search bar
                TextFormField(
                  style: const TextStyle(color: Colors.white),
                  decoration: AppTheme.inputDecoration(
                          'Search by name or email',
                          icon: Icons.search)
                      .copyWith(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14)),
                  onChanged: (v) => setState(() {
                    _search = v;
                    _apply();
                  }),
                ),
                const SizedBox(height: 12),
                // Filter chips
                Row(
                  children: [
                    _filterChip('All', 'all'),
                    const SizedBox(width: 8),
                    _filterChip('Active', 'active'),
                    const SizedBox(width: 8),
                    _filterChip('Expired', 'expired'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary))
                : _filtered.isEmpty
                    ? const Center(
                        child:
                            Text('No members found', style: AppTheme.bodyMuted))
                    : RefreshIndicator(
                        color: AppTheme.primary,
                        backgroundColor: AppTheme.bgCard,
                        onRefresh: _load,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _MemberTile(
                            member: _filtered[i],
                            onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => MemberDetailScreen(
                                            member: _filtered[i])))
                                .then((_) => _load()),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() {
        _filter = value;
        _apply();
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryDim : AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppTheme.primary : AppTheme.border),
        ),
        child: Text(label,
            style: TextStyle(
              color: active ? AppTheme.primary : AppTheme.textMuted,
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            )),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final GymUser member;
  final VoidCallback onTap;
  const _MemberTile({required this.member, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = member.isMembershipActive;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.card(),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: active ? AppTheme.primaryDim : AppTheme.bgCardAlt,
              child: Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: active ? AppTheme.primary : AppTheme.textMuted,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(member.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      )),
                  const SizedBox(height: 2),
                  Text(member.email,
                      style: AppTheme.bodyMuted.copyWith(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    member.membershipType != null
                        ? '${member.membershipType![0].toUpperCase()}${member.membershipType!.substring(1)} plan'
                        : 'No plan',
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: active ? AppTheme.greenDim : AppTheme.redDim,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(active ? 'Active' : 'Expired',
                      style: TextStyle(
                        color: active ? AppTheme.green : AppTheme.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      )),
                ),
                const SizedBox(height: 4),
                if (active)
                  Text('${member.daysRemaining}d left',
                      style: AppTheme.bodyMuted.copyWith(fontSize: 11)),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}
