import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:mechanic_app/widgets/app_avatar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _supabase = Supabase.instance.client;
  String _roleFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    var query = _supabase.from('profiles').stream(primaryKey: ['id']);
    if (_roleFilter != 'all') {
      query = query.eq('role', _roleFilter);
    }
    final Stream<List<Map<String, dynamic>>> usersStream = query.order('full_name');

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Global Management', 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildFilterBar(isDark),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: usersStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data ?? [];

                if (users.isEmpty) {
                  return Center(child: Text('No users found for this category', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey)));
                }

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.all(20),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _UserCard(
                      user: user,
                      onToggleBlock: () => _toggleBlock(user['id'], user['is_blocked'] ?? false),
                      onChangeRole: (newRole) => _changeRole(user['id'], newRole),
                      onDelete: () => _deleteUser(user['id']),
                      isDark: isDark,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    final roles = ['all', 'customer', 'mechanic', 'admin'];
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: roles.length,
        itemBuilder: (context, index) {
          final role = roles[index];
          bool isSelected = _roleFilter == role;
          return GestureDetector(
            onTap: () => setState(() => _roleFilter = role),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? (isDark ? AppColors.neonGreen : AppColors.primary) : (isDark ? AppColors.darkSurface : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? Colors.transparent : (isDark ? Colors.white10 : AppColors.divider)),
              ),
              child: Text(
                role.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.black : (isDark ? Colors.white70 : AppColors.textDark),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleBlock(String userId, bool currentBlocked) async {
    try {
      await _supabase.from('profiles').update({'is_blocked': !currentBlocked}).eq('id', userId);
    } catch (e) {
      debugPrint('Error toggling block: $e');
    }
  }

  Future<void> _changeRole(String userId, String newRole) async {
    try {
      await _supabase.from('profiles').update({'role': newRole}).eq('id', userId);
    } catch (e) {
      debugPrint('Error changing role: $e');
    }
  }

  Future<void> _deleteUser(String userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member?'),
        content: const Text('This will delete the profile data permanently.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase.from('profiles').delete().eq('id', userId);
      } catch (e) {
        debugPrint('Error deleting user: $e');
      }
    }
  }
}

class _UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isDark;
  final VoidCallback onToggleBlock;
  final Function(String) onChangeRole;
  final VoidCallback onDelete;

  const _UserCard({required this.user, required this.isDark, required this.onToggleBlock, required this.onChangeRole, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final bool isBlocked = user['is_blocked'] ?? false;
    final String currentRole = user['role'] ?? 'customer';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AppAvatar(url: user['avatar_url'], fallbackId: user['id'], radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['full_name'] ?? 'No Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : AppColors.textDark)),
                    Text(user['email'] ?? 'No Email', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 12)),
                  ],
                ),
              ),
              _buildRoleBadge(currentRole),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _ActionButton(
                    icon: isBlocked ? Icons.lock_open_rounded : Icons.block_flipped, 
                    label: isBlocked ? 'Unblock' : 'Block', 
                    color: isBlocked ? Colors.green : Colors.red, 
                    onTap: onToggleBlock,
                  ),
                  const SizedBox(width: 12),
                  _ActionButton(
                    icon: Icons.admin_panel_settings_rounded, 
                    label: currentRole == 'admin' ? 'Revoke Admin' : 'Make Admin', 
                    color: Colors.blue, 
                    onTap: () => onChangeRole(currentRole == 'admin' ? 'customer' : 'admin'),
                  ),
                ],
              ),
              IconButton(
                onPressed: onDelete, 
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color = Colors.blue;
    if (role == 'mechanic') color = Colors.orange;
    if (role == 'admin') color = AppColors.neonGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(role.toUpperCase(), style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w900)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.2))),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
