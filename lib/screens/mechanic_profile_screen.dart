import 'package:flutter/material.dart';
import 'package:mechanic_app/screens/login_screen.dart';
import 'package:mechanic_app/screens/mechanic_reviews_screen.dart';
import 'package:mechanic_app/screens/mechanic_wallet_screen.dart';
import 'package:mechanic_app/screens/settings_screen.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:mechanic_app/widgets/app_avatar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MechanicProfileScreen extends StatefulWidget {
  const MechanicProfileScreen({super.key});

  @override
  State<MechanicProfileScreen> createState() => _MechanicProfileScreenState();
}

class _MechanicProfileScreenState extends State<MechanicProfileScreen> {
  final _supabase = Supabase.instance.client;

  void _showLogoutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out of your partner account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _supabase.auth.currentUser;

    final Stream<List<Map<String, dynamic>>> profileStream = _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user?.id ?? '');

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: profileStream,
        builder: (context, snapshot) {
          final profile = snapshot.data?.firstOrNull;
          final String name = profile?['full_name'] ?? 'Partner';
          final String specialty = profile?['shop_name'] ?? 'General Specialist';
          final bool isOnline = profile?['is_online'] ?? false;
          final double rating = (profile?['rating'] ?? 5.0).toDouble();
          final int jobs = profile?['jobs_completed'] ?? 0;
          
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: isDark ? AppColors.darkGradient : AppColors.primaryGradient,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mechanic Profile', 
                                style: TextStyle(
                                  color: isDark ? Colors.black : Colors.white, 
                                  fontSize: 22, 
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.settings_rounded, color: isDark ? Colors.black : Colors.white, size: 20),
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -50,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white, 
                            shape: BoxShape.circle,
                          ),
                          child: AppAvatar(
                            url: profile?['avatar_url'],
                            fallbackId: profile?['id'],
                            gender: profile?['gender'],
                            radius: 50,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 64),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name, 
                      style: TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.w900, 
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (profile?['is_verified'] ?? false)
                      Icon(Icons.verified_rounded, color: isDark ? AppColors.neonGreen : Colors.blue, size: 20),
                  ],
                ),
                Text(
                  specialty, 
                  style: TextStyle(
                    color: isDark ? AppColors.darkGrey : AppColors.grey, 
                    fontSize: 13, 
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 28),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _infoTag(isDark, Icons.person_pin_rounded, (profile?['gender'] ?? 'N/A').toString().toUpperCase()),
                          const SizedBox(width: 12),
                          _infoTag(isDark, Icons.cake_rounded, '${profile?['age'] ?? 'N/A'} Years'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildMechanicStatTile(context, Icons.star_rounded, 'Reviews', '$rating ($jobs reviews)', Colors.amber, isDark, screen: const MechanicReviewsScreen()),
                      _buildMechanicStatTile(context, Icons.account_balance_wallet_rounded, 'Earnings', 'Dynamic from Wallet', Colors.green, isDark, screen: const MechanicWalletScreen()),
                      _buildMechanicStatTile(context, Icons.access_time_filled_rounded, 'Working Hours', '9:00 AM - 8:00 PM', Colors.blue, isDark),
                      _buildMechanicStatTile(context, Icons.category_rounded, 'Services', 'Managed by Admin', Colors.orange, isDark),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _showLogoutDialog(context, isDark),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                        ),
                        child: const Text('Logout Account'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => _toggleOnlineStatus(user?.id, isOnline),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOnline ? Colors.redAccent : Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                        ),
                        child: Text(isOnline ? 'Go Offline' : 'Go Online'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        }
      ),
    );
  }

  Future<void> _toggleOnlineStatus(String? id, bool currentStatus) async {
    if (id == null) return;
    try {
      await _supabase.from('profiles').update({'is_online': !currentStatus}).eq('id', id);
    } catch (e) {
      debugPrint('Error updating status: $e');
    }
  }

  Widget _infoTag(bool isDark, IconData icon, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : AppColors.divider.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isDark ? AppColors.neonGreen : AppColors.primary),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMechanicStatTile(BuildContext context, IconData icon, String title, String value, Color color, bool isDark, {Widget? screen}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        leading: Icon(icon, color: isDark ? AppColors.neonGreen : color),
        title: Text(
          title, 
          style: TextStyle(
            fontWeight: FontWeight.w500, 
            fontSize: 12, 
            color: isDark ? AppColors.darkGrey : AppColors.grey,
          ),
        ),
        subtitle: Text(
          value, 
          style: TextStyle(
            fontWeight: FontWeight.w800, 
            fontSize: 15, 
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        trailing: screen != null ? Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkGrey : AppColors.grey) : null,
        onTap: screen != null ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => screen)) : null,
      ),
    );
  }
}
