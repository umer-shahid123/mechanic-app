import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mechanic_app/screens/admin/admin_bookings_management.dart';
import 'package:mechanic_app/screens/admin/admin_emergency_hub.dart';
import 'package:mechanic_app/screens/admin/admin_reports_download_screen.dart';
import 'package:mechanic_app/screens/admin/dispute_management_screen.dart';
import 'package:mechanic_app/screens/admin/mechanic_management_screen.dart';
import 'package:mechanic_app/screens/admin/mechanic_verification_workflow.dart';
import 'package:mechanic_app/screens/admin/payment_reports_screen.dart';
import 'package:mechanic_app/screens/admin/platform_broadcast_screen.dart';
import 'package:mechanic_app/screens/admin/platform_heatmap_screen.dart';
import 'package:mechanic_app/screens/admin/service_management_screen.dart';
import 'package:mechanic_app/screens/admin/user_management_screen.dart';
import 'package:mechanic_app/screens/admin/withdrawal_requests_screen.dart';
import 'package:mechanic_app/screens/login_screen.dart';
import 'package:mechanic_app/screens/settings_screen.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:mechanic_app/widgets/admin/revenue_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _supabase = Supabase.instance.client;
  int _selectedIndex = 0;

  Future<void> _handleLogout() async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to exit admin mode?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Stream<List<Map<String, dynamic>>> profilesStream = _supabase.from('profiles').stream(primaryKey: ['id']);
    final Stream<List<Map<String, dynamic>>> bookingsStream = _supabase.from('bookings').stream(primaryKey: ['id']);
    final Stream<List<Map<String, dynamic>>> transStream = _supabase.from('transactions').stream(primaryKey: ['id']).eq('type', 'payout');

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          AdminHomeContent(
            profilesStream: profilesStream,
            bookingsStream: bookingsStream,
            transStream: transStream,
            onLogout: _handleLogout,
          ),
          const UserManagementScreen(),
          const PaymentReportsScreen(),
          const MechanicManagementScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildCustomAdminNavBar(isDark),
    );
  }

  Widget _buildCustomAdminNavBar(bool isDark) {
    const Color activeColor = Color(0xFFFFD700);
    return Container(
      height: 70,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2A),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.dashboard_rounded, 'Stats', activeColor),
              _buildNavItem(1, Icons.people_rounded, 'Users', activeColor),
              const SizedBox(width: 50),
              _buildNavItem(3, Icons.engineering_rounded, 'Team', activeColor),
              _buildNavItem(4, Icons.settings_rounded, 'Set', activeColor),
            ],
          ),
          Positioned(
            top: -28,
            child: GestureDetector(
              onTap: () => setState(() => _selectedIndex = 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 58,
                    width: 58,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00BFA5), Color(0xFF00E676)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0D1B2A), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00E676).withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Reports',
                    style: TextStyle(
                      color: _selectedIndex == 2 ? const Color(0xFF00E676) : Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, Color selectedColor) {
    bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? selectedColor : Colors.white.withValues(alpha: 0.6),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedColor : Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminHomeContent extends StatelessWidget {
  final Stream<List<Map<String, dynamic>>> profilesStream;
  final Stream<List<Map<String, dynamic>>> bookingsStream;
  final Stream<List<Map<String, dynamic>>> transStream;
  final VoidCallback onLogout;

  const AdminHomeContent({
    super.key, 
    required this.profilesStream,
    required this.bookingsStream,
    required this.transStream,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Admin Console',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: onLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Platform Statistics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: profilesStream,
              builder: (context, pSnapshot) {
                final profiles = pSnapshot.data ?? [];
                final userCount = profiles.where((p) => p['role'] == 'customer').length;
                final mechCount = profiles.where((p) => p['role'] == 'mechanic').length;
                final pendingCount = profiles.where((p) => p['role'] == 'mechanic' && p['verification_status'] == 'unverified').length;

                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: bookingsStream,
                  builder: (context, bSnapshot) {
                    final bookingCount = bSnapshot.data?.length ?? 0;

                    return StreamBuilder<List<Map<String, dynamic>>>(
                      stream: transStream,
                      builder: (context, tSnapshot) {
                        double totalEarnings = 0;
                        for (var tx in (tSnapshot.data ?? [])) {
                          totalEarnings += (tx['amount'] as num).toDouble();
                        }

                        return Column(
                          children: [
                            GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.4,
                              children: [
                                _StatCard(label: 'Total Users', value: userCount.toString(), icon: Icons.people_rounded, color: Colors.blue, isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UserManagementScreen()))),
                                _StatCard(label: 'Verified Mechs', value: (mechCount - pendingCount).toString(), icon: Icons.engineering_rounded, color: Colors.orange, isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MechanicManagementScreen()))),
                                _StatCard(label: 'Pending Approvals', value: pendingCount.toString(), icon: Icons.verified_user_rounded, color: Colors.red, isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MechanicVerificationWorkflow()))),
                                _StatCard(label: 'Total Bookings', value: bookingCount.toString(), icon: Icons.book_online_rounded, color: Colors.green, isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminBookingsManagement()))),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _StatCard(
                              label: 'Total Platform Revenue', 
                              value: 'PKR ${NumberFormat("#,###").format(totalEarnings)}', 
                              icon: Icons.payments_rounded, 
                              color: Colors.purple, 
                              isDark: isDark,
                              fullWidth: true,
                            ),
                          ],
                        );
                      }
                    );
                  }
                );
              }
            ),

            const SizedBox(height: 28),
            Text(
              'Newest Registrations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: profilesStream,
              builder: (context, snapshot) {
                final profiles = snapshot.data ?? [];
                // Sort by created_at if available, otherwise just show top 3
                final recent = profiles.where((p) => p['role'] != 'admin').toList();
                recent.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));
                final items = recent.take(3).toList();

                if (items.isEmpty) return Center(child: Text('No users found', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 12)));

                return Column(
                  children: items.map((user) => _RecentUserTile(user: user, isDark: isDark)).toList(),
                );
              },
            ),

            const SizedBox(height: 28),
            Text(
              'Management Shortcuts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
              children: [
                _AdminToolBtn(icon: Icons.sos_rounded, label: 'SOS', color: AppColors.sosRed, isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminEmergencyHub()))),
                _AdminToolBtn(icon: Icons.verified_user_rounded, label: 'Verify', color: Colors.blue, isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MechanicVerificationWorkflow()))),
                _AdminToolBtn(icon: Icons.campaign_rounded, label: 'Alert', color: Colors.orange, isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlatformBroadcastScreen()))),
                _AdminToolBtn(icon: Icons.design_services_rounded, label: 'Services', color: Colors.green, isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ServiceManagementScreen()))),
                _AdminToolBtn(icon: Icons.book_online_rounded, label: 'Bookings', color: Colors.amber, isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminBookingsManagement()))),
                _AdminToolBtn(icon: Icons.report_problem_rounded, label: 'Disputes', color: Colors.red, isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DisputeManagementScreen()))),
                _AdminToolBtn(icon: Icons.analytics_rounded, label: 'Data', color: Colors.purple, isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminReportsDownloadScreen()))),
                _AdminToolBtn(icon: Icons.map_rounded, label: 'Live Map', color: Colors.teal, isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlatformHeatmapScreen()))),
                _AdminToolBtn(icon: Icons.account_balance_wallet_rounded, label: 'Payouts', color: Colors.indigo, isDark: isDark, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WithdrawalRequestsScreen()))),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Revenue Overview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: transStream,
              builder: (context, snapshot) {
                return Container(
                  height: 200,
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
                    boxShadow: isDark ? [] : AppColors.softShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Weekly Performance', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : AppColors.grey)),
                          Text('+12.5% Today', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: RevenueChart(
                          transactions: snapshot.data ?? [],
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                );
              }
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _AdminToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _AdminToolBtn({required this.icon, required this.label, required this.color, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: isDark ? Colors.white : AppColors.textDark)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool fullWidth;
  final VoidCallback? onTap;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color, required this.isDark, this.fullWidth = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
          boxShadow: isDark ? [] : AppColors.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.neonGreen : color).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isDark ? AppColors.neonGreen : color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: fullWidth ? 20 : 16,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: isDark ? AppColors.darkGrey : AppColors.grey,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentUserTile extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isDark;
  const _RecentUserTile({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bool isMech = user['role'] == 'mechanic';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
      ),
      child: Row(
        children: [
          const CircleAvatar(radius: 18, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=user')),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['full_name'] ?? 'New Member', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : AppColors.textDark)),
                Text(user['email'] ?? '', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isMech ? Colors.orange : Colors.blue).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              user['role']?.toString().toUpperCase() ?? 'USER',
              style: TextStyle(color: isMech ? Colors.orange : Colors.blue, fontSize: 8, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
