import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mechanic_app/screens/smart_diagnosis_screen.dart';
import 'package:mechanic_app/screens/bookings_screen.dart';
import 'package:mechanic_app/screens/nearby_mechanics_screen.dart';
import 'package:mechanic_app/screens/profile_screen.dart';
import 'package:mechanic_app/screens/select_vehicle_screen.dart';
import 'package:mechanic_app/screens/set_location_screen.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:mechanic_app/widgets/app_avatar.dart';
import 'package:mechanic_app/widgets/service_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:ui';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    HomeContent(),
    NearbyMechanicsScreen(),
    SetLocationScreen(),
    BookingsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex == 2 ? 0 : _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildCustomNavBar(isDark),
    );
  }

  Widget _buildCustomNavBar(bool isDark) {
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
              _buildNavItem(0, Icons.home_rounded, 'Home', activeColor),
              _buildNavItem(1, Icons.engineering_rounded, 'Mechanics', activeColor),
              const SizedBox(width: 50),
              _buildNavItem(3, Icons.calendar_month_rounded, 'Bookings', activeColor),
              _buildNavItem(4, Icons.person_rounded, 'Profile', activeColor),
            ],
          ),
          Positioned(
            top: -28,
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SelectVehicleScreen()));
              },
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
                    child: const Icon(Icons.build_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Book Service',
                    style: TextStyle(color: Color(0xFF00E676), fontSize: 10, fontWeight: FontWeight.w700),
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

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final _supabase = Supabase.instance.client;
  late final Stream<List<Map<String, dynamic>>> _profileStream;
  late final Stream<List<Map<String, dynamic>>> _servicesStream;
  String _currentLocationName = "Fetching location...";

  @override
  void initState() {
    super.initState();
    final user = _supabase.auth.currentUser;
    _profileStream = _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user?.id ?? '');

    _servicesStream = _supabase
        .from('services')
        .stream(primaryKey: ['id']);
    
    _updateLocation();
  }

  Future<void> _updateLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      // For real address we'd use geocoding, here we update with a pretty string
      if (mounted) {
        setState(() {
          _currentLocationName = "Johar Town, Lahore"; // In real app, reverse geocode position
        });
      }
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('profiles').update({
          'location_lat': position.latitude,
          'location_lng': position.longitude,
          'last_location_name': _currentLocationName,
        }).eq('id', user.id);
      }
    } catch (e) {
      if (mounted) setState(() => _currentLocationName = "Location not found");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _profileStream,
                builder: (context, snapshot) {
                  final profile = snapshot.data?.firstOrNull;
                  final userName = profile?['full_name'] ?? 'User';
                  final userAvatar = profile?['avatar_url'];
                  final userLevel = profile?['tier'] ?? 'GOLD';
                  final location = profile?['last_location_name'] ?? _currentLocationName;

                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: isDark ? AppColors.neonGreen : AppColors.primary, width: 2),
                        ),
                        child: AppAvatar(
                          url: userAvatar,
                          fallbackId: profile?['id'],
                          gender: profile?['gender'],
                          radius: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  userName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800, 
                                    fontSize: 18, 
                                    color: isDark ? Colors.white : AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.neonGreen : AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    userLevel, 
                                    style: const TextStyle(
                                      color: Colors.black, 
                                      fontSize: 8, 
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded, size: 10, color: isDark ? AppColors.neonGreen : AppColors.primary),
                                const SizedBox(width: 4),
                                Text(
                                  location, 
                                  style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkGrey : AppColors.grey, fontWeight: FontWeight.w600),
                                ),
                                Icon(Icons.keyboard_arrow_down_rounded, size: 12, color: isDark ? AppColors.darkGrey : AppColors.grey),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _triggerSOS(context),
                        icon: const Icon(Icons.sos_rounded, color: AppColors.sosRed, size: 28),
                      ),
                    ],
                  );
                }
              ),
              const SizedBox(height: 24),

              // Glassmorphic Search Bar
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NearbyMechanicsScreen())),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.darkSurface : Colors.white).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search_rounded, color: isDark ? AppColors.darkGrey : AppColors.grey),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Search expert mechanics...', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey))),
                          Icon(Icons.tune_rounded, color: isDark ? AppColors.neonGreen : AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              // Interactive Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isDark ? AppColors.darkGradient : AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: isDark ? AppColors.glowShadow : [],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Need a mechanic now?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    const Text('Get instant help at your location.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SelectVehicleScreen())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.secondary,
                        minimumSize: const Size(120, 36),
                      ),
                      child: const Text('Request Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Top Services', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16, 
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NearbyMechanicsScreen())),
                    child: Text(
                      'View all', 
                      style: TextStyle(
                        color: isDark ? AppColors.neonGreen : AppColors.primary, 
                        fontSize: 12, 
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _servicesStream,
                builder: (context, snapshot) {
                  final services = snapshot.data ?? [];
                  if (services.isEmpty) {
                    return Center(child: Text('No services available', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey)));
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: services.length > 8 ? 8 : services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return ServiceCard(
                        icon: _getIconForService(service['icon_name']),
                        label: service['name'] ?? 'Service',
                      );
                    },
                  );
                }
              ),
              const SizedBox(height: 24),

              // Emergency Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Emergency roadside help?',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.red),
                          ),
                          Text(
                            'Immediate response within 15 mins.',
                            style: TextStyle(color: Colors.red.withValues(alpha: 0.7), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Call 🚨', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // AI Assistant Card
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SmartDiagnosisScreen()));
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isDark ? AppColors.neonGreen : Colors.blue).withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.psychology_rounded, color: isDark ? AppColors.neonGreen : Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Smart AI Diagnosis',
                              style: TextStyle(
                                fontWeight: FontWeight.w700, 
                                fontSize: 13, 
                                color: isDark ? Colors.white : AppColors.textDark,
                              ),
                            ),
                            Text(
                              'Let AI analyze your car problems.',
                              style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkGrey : AppColors.grey),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 12, color: isDark ? AppColors.darkGrey : AppColors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _triggerSOS(BuildContext context) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('emergency_sos').insert({
        'customer_id': user.id,
        'location_lat': 31.4697, // Demo Lahor
        'location_lng': 74.2728,
        'status': 'searching',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SOS signal broadcasted! Help is on the way.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('SOS Error: $e');
    }
  }

  IconData _getIconForService(String? iconName) {
    switch (iconName) {
      case 'settings': return Icons.settings_rounded;
      case 'engineering': return Icons.engineering_rounded;
      case 'battery': return Icons.battery_charging_full_rounded;
      case 'adjust': return Icons.adjust_rounded;
      case 'ac_unit': return Icons.ac_unit_rounded;
      case 'wash': return Icons.wash_rounded;
      case 'opacity': return Icons.opacity_rounded;
      default: return Icons.more_horiz_rounded;
    }
  }
}
