import 'package:flutter/material.dart';
import 'package:mechanic_app/screens/admin_dashboard_screen.dart';
import 'package:mechanic_app/screens/corporate_management_screen.dart';
import 'package:mechanic_app/screens/help_support_screen.dart';
import 'package:mechanic_app/screens/login_screen.dart';
import 'package:mechanic_app/screens/my_vehicles_screen.dart';
import 'package:mechanic_app/screens/notifications_screen.dart';
import 'package:mechanic_app/screens/safety_hub_screen.dart';
import 'package:mechanic_app/screens/saved_addresses_screen.dart';
import 'package:mechanic_app/screens/settings_screen.dart';
import 'package:mechanic_app/screens/wallet_screen.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:mechanic_app/widgets/app_avatar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final data = await _supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .single();
        setState(() {
          _profile = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final name = _profile?['full_name'] ?? 'Loading...';
    final phone = _profile?['phone'] ?? '...';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      body: SingleChildScrollView(
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
                            'My Profile', 
                            style: TextStyle(
                              color: isDark ? Colors.black : Colors.white, 
                              fontSize: 22, 
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.edit_rounded, color: isDark ? Colors.black : Colors.white, size: 20),
                            onPressed: () {},
                            style: IconButton.styleFrom(
                              backgroundColor: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.1),
                            ),
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
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white, 
                            shape: BoxShape.circle, 
                            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black12, blurRadius: 15)],
                          ),
                          child: AppAvatar(
                            url: _profile?['avatar_url'],
                            fallbackId: _profile?['id'],
                            gender: _profile?['gender'],
                            radius: 50,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.neonGreen : AppColors.primary, 
                              shape: BoxShape.circle,
                              boxShadow: isDark ? AppColors.glowShadow : [const BoxShadow(color: Colors.black12, blurRadius: 5)],
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded, 
                              color: isDark ? Colors.black : AppColors.secondary, 
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 64),
            if (_isLoading)
              const CircularProgressIndicator()
            else ...[
              Text(
                name, 
                style: TextStyle(
                  fontSize: 22, 
                  fontWeight: FontWeight.w900, 
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              Text(
                phone, 
                style: TextStyle(
                  color: isDark ? AppColors.darkGrey : AppColors.grey, 
                  fontSize: 13, 
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      _infoTag(isDark, Icons.person_pin_rounded, (_profile?['gender'] ?? 'N/A').toString().toUpperCase()),
                      const SizedBox(width: 12),
                      _infoTag(isDark, Icons.cake_rounded, '${_profile?['age'] ?? 'N/A'} Years'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildProfileTile(context, Icons.person_rounded, 'Personal Info', Colors.blue, isDark),
                  _buildProfileTile(context, Icons.directions_car_rounded, 'My Vehicles', Colors.orange, isDark, screen: const MyVehiclesScreen()),
                  _buildProfileTile(context, Icons.payment_rounded, 'Payment Methods', Colors.green, isDark, screen: const WalletScreen()),
                  _buildProfileTile(context, Icons.location_on_rounded, 'Saved Addresses', Colors.red, isDark, screen: const SavedAddressesScreen()),
                  _buildProfileTile(context, Icons.notifications_rounded, 'Notifications', Colors.purple, isDark, screen: const NotificationsScreen()),
                  _buildProfileTile(context, Icons.headset_mic_rounded, 'Help & Support', Colors.teal, isDark, screen: const HelpSupportScreen()),
                  _buildProfileTile(context, Icons.settings_rounded, 'Settings', Colors.grey, isDark, screen: const SettingsScreen()),
                  _buildProfileTile(context, Icons.security_rounded, 'Safety Hub', Colors.red, isDark, screen: const SafetyHubScreen()),
                  _buildProfileTile(context, Icons.business_rounded, 'Corporate Fleet', Colors.blueGrey, isDark, screen: const CorporateManagementScreen()),
                  if (_profile?['role'] == 'admin')
                    _buildProfileTile(context, Icons.dashboard_rounded, 'Admin Dashboard', isDark ? AppColors.neonGreen : AppColors.primary, isDark, screen: const AdminDashboardScreen()),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(color: isDark ? Colors.white10 : AppColors.divider),
                  ),
                  _buildProfileTile(context, Icons.logout_rounded, 'Logout', Colors.red, isDark, isLogout: true),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
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

  Widget _buildProfileTile(BuildContext context, IconData icon, String title, Color color, bool isDark, {bool isLogout = false, Widget? screen}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDark ? AppColors.neonGreen : color).withValues(alpha: 0.08), 
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: isDark ? AppColors.neonGreen : color, size: 18),
        ),
        title: Text(
          title, 
          style: TextStyle(
            fontWeight: FontWeight.w700, 
            fontSize: 13, 
            color: isLogout ? Colors.red : (isDark ? Colors.white : AppColors.textDark),
          ),
        ),
        trailing: isLogout ? null : Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkGrey : AppColors.grey, size: 18),
        onTap: () {
          if (isLogout) {
            _showLogoutDialog(context, isDark);
          } else if (screen != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
          }
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Logout', 
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel', 
              style: TextStyle(
                color: isDark ? AppColors.darkGrey : AppColors.grey, 
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 40),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
