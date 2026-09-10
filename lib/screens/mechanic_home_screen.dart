import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mechanic_app/screens/admin/service_management_screen.dart';
import 'package:mechanic_app/screens/job_completion_screen.dart';
import 'package:mechanic_app/screens/login_screen.dart';
import 'package:mechanic_app/screens/mechanic_availability_screen.dart';
import 'package:mechanic_app/screens/mechanic_document_verification.dart';
import 'package:mechanic_app/screens/mechanic_history_screen.dart';
import 'package:mechanic_app/screens/mechanic_map_screen.dart';
import 'package:mechanic_app/screens/mechanic_profile_screen.dart';
import 'package:mechanic_app/screens/mechanic_wallet_screen.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:mechanic_app/widgets/app_avatar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The main entry point for the mechanic's interface in the application.
/// 
/// This screen provides a bottom navigation bar to switch between different sections
/// like dashboard, history, map, wallet, and profile. It also handles data streams
/// for pending job requests and emergency SOS calls.
class MechanicHomeScreen extends StatefulWidget {
  const MechanicHomeScreen({super.key});

  @override
  State<MechanicHomeScreen> createState() => _MechanicHomeScreenState();
}

/// State for [MechanicHomeScreen] which manages the selected index for navigation
/// and sets up Supabase streams for real-time updates.
class _MechanicHomeScreenState extends State<MechanicHomeScreen> {
  final _supabase = Supabase.instance.client;
  int _selectedIndex = 0;
  bool _isOnline = false;
  StreamSubscription? _profileSubscription;
  StreamSubscription? _locationSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeProfile();
  }

  void _setupRealtimeProfile() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _profileSubscription = _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .listen((data) {
      if (data.isNotEmpty && mounted) {
        final newOnlineStatus = data.first['is_online'] ?? false;
        if (newOnlineStatus != _isOnline) {
          setState(() {
            _isOnline = newOnlineStatus;
          });
          if (_isOnline) {
            _startLocationTracking();
          } else {
            _stopLocationTracking();
          }
        }
      }
    });
  }

  void _startLocationTracking() async {
    _locationSubscription?.cancel();

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      _updateLocationInDatabase(position);
    });
  }

  void _stopLocationTracking() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  Future<void> _updateLocationInDatabase(Position position) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _supabase.from('profiles').update({
        'location_lat': position.latitude,
        'location_lng': position.longitude,
      }).eq('id', user.id);
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleOnlineStatus() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final newStatus = !_isOnline;
    
    try {
      // Optimistic update handled by the stream listener
      await _supabase
          .from('profiles')
          .update({'is_online': newStatus})
          .eq('id', user.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Stream<List<Map<String, dynamic>>> requestsStream = _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending');

    final Stream<List<Map<String, dynamic>>> sosStream = _supabase
        .from('emergency_sos')
        .stream(primaryKey: ['id'])
        .eq('status', 'searching');

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex == 2 ? 0 : _selectedIndex,
        children: [
          MechanicHomeContent(
            requestsStream: requestsStream, 
            sosStream: sosStream,
            isOnline: _isOnline,
            onToggleStatus: _toggleOnlineStatus,
          ),
          const MechanicHistoryScreen(),
          const MechanicMapScreen(),
          const MechanicWalletScreen(),
          const MechanicProfileScreen(),
        ],
      ),
      bottomNavigationBar: _buildCustomMechanicNavBar(isDark),
    );
  }

  /// Builds a custom stylized navigation bar for the mechanic interface.
  /// 
  /// Features a prominent central button for the 'Online' (Map) status.
  Widget _buildCustomMechanicNavBar(bool isDark) {
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
              _buildNavItem(0, Icons.dashboard_rounded, 'Jobs', activeColor),
              _buildNavItem(1, Icons.history_rounded, 'History', activeColor),
              const SizedBox(width: 50),
              _buildNavItem(3, Icons.wallet_rounded, 'Wallet', activeColor),
              _buildNavItem(4, Icons.person_rounded, 'Profile', activeColor),
            ],
          ),
          Positioned(
            top: -28,
            child: GestureDetector(
              onTap: _toggleOnlineStatus,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 58,
                    width: 58,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isOnline 
                          ? [const Color(0xFF00BFA5), const Color(0xFF00E676)]
                          : [Colors.grey.shade700, Colors.grey.shade500],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF0D1B2A), width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: (_isOnline ? const Color(0xFF00E676) : Colors.grey).withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isOnline ? Icons.location_searching_rounded : Icons.location_disabled_rounded, 
                      color: Colors.white, 
                      size: 28
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: _isOnline ? const Color(0xFF00E676) : Colors.white70,
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

  /// Builds an individual navigation item for the bottom bar.
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

/// The primary content widget for the mechanic's dashboard.
/// 
/// Displays the mechanic's profile summary, daily earnings, active services,
/// and lists of emergency SOS and standard job requests.
class MechanicHomeContent extends StatelessWidget {
  final Stream<List<Map<String, dynamic>>> requestsStream;
  final Stream<List<Map<String, dynamic>>> sosStream;
  final bool isOnline;
  final VoidCallback onToggleStatus;

  const MechanicHomeContent({
    super.key, 
    required this.requestsStream, 
    required this.sosStream,
    required this.isOnline,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final user = supabase.auth.currentUser;

    final Stream<List<Map<String, dynamic>>> profileStream = supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user?.id ?? '');

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    
    final Stream<List<Map<String, dynamic>>> earningsStream = supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('profile_id', user?.id ?? '')
        .gte('created_at', startOfDay);

    final Stream<List<Map<String, dynamic>>> servicesStream = supabase
        .from('services')
        .stream(primaryKey: ['id']);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: profileStream,
                builder: (context, snapshot) {
                  final profile = snapshot.data?.firstOrNull;
                  final isVerified = profile?['verification_status'] == 'verified';
                  final verificationStatus = profile?['verification_status'] ?? 'unverified';
                  final rating = (profile?['rating'] ?? 5.0).toDouble();
                  final tier = profile?['tier'] ?? 'Bronze';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good Morning, ${profile?['full_name']?.split(' ')[0] ?? 'Partner'}! 👋',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.textDark,
                                ),
                              ),
                              Text(
                                isOnline ? 'You are online' : 'You are offline',
                                style: TextStyle(
                                  color: isOnline ? Colors.green : Colors.redAccent, 
                                  fontSize: 13, 
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                            ],
                          ),
                          AppAvatar(
                            url: profile?['avatar_url'],
                            fallbackId: profile?['id'],
                            radius: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (!isVerified)
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MechanicDocumentVerification())),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: verificationStatus == 'pending' ? Colors.blue.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: verificationStatus == 'pending' ? Colors.blue.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  verificationStatus == 'pending' ? Icons.access_time_rounded : Icons.info_outline_rounded, 
                                  color: verificationStatus == 'pending' ? Colors.blue : Colors.orange, 
                                  size: 20
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    verificationStatus == 'pending' 
                                      ? 'Verification in progress. We\u0027ll notify you soon!'
                                      : 'Verification Required: Upload documents to start earning.',
                                    style: TextStyle(
                                      color: verificationStatus == 'pending' ? Colors.blue : Colors.orange, 
                                      fontSize: 11, 
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios_rounded, color: verificationStatus == 'pending' ? Colors.blue : Colors.orange, size: 12),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 32),

                      // Earnings Card
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: earningsStream,
                        builder: (context, earnSnapshot) {
                          double total = 0;
                          final trans = earnSnapshot.data ?? [];
                          for (var row in trans) {
                            total += (row['amount'] as num).toDouble();
                          }

                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D1B2A),
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _levelBadge(level: tier, color: _getTierColor(tier)),
                                    GestureDetector(
                                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MechanicAvailabilityScreen())),
                                      child: Icon(Icons.settings_input_antenna_rounded, color: isDark ? AppColors.neonGreen : AppColors.primary, size: 20),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Text('Today\u0027s Payout', style: TextStyle(color: Colors.white60, fontSize: 13)),
                                Text('PKR ${total.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _miniStat('Acceptance', '${profile?['acceptance_rate'] ?? 100}%'),
                                    _miniStat('Rating', '⭐ ${rating.toStringAsFixed(1)}'),
                                    _miniStat('Response', '${profile?['avg_response_time'] ?? 5}m'),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }
                      ),
                    ],
                  );
                }
              ),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Active Services',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ServiceManagementScreen())),
                    child: Text(
                      'Manage',
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
              SizedBox(
                height: 100,
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: servicesStream,
                  builder: (context, snapshot) {
                    final services = snapshot.data ?? [];
                    if (services.isEmpty) {
                      return Text('No services listed', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 12));
                    }
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: services.length,
                      itemBuilder: (context, index) {
                        final service = services[index];
                        return Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_getIconForService(service['icon_name']), color: isDark ? AppColors.neonGreen : AppColors.secondary, size: 24),
                              const SizedBox(height: 8),
                              Text(
                                service['name'] ?? 'Service',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }
                ),
              ),

              const SizedBox(height: 32),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: sosStream,
                builder: (context, snapshot) {
                  final list = snapshot.data ?? [];
                  if (list.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🚨 EMERGENCY SOS NEARBY', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(height: 12),
                      ...list.map((sos) => _buildRequestCard(context, {
                        'id': sos['id'],
                        'service_type': 'EMERGENCY SOS',
                        'problem_description': 'Critical assistance required!',
                        'customer_location_name': 'Nearby Location',
                        'total_price': 'PREMIUM',
                      }, isDark, isSOS: true)),
                      const Divider(height: 40),
                    ],
                  );
                },
              ),
              Text(
                'Incoming Requests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              const SizedBox(height: 16),

              StreamBuilder<List<Map<String, dynamic>>>(
                stream: requestsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final requests = snapshot.data ?? [];
                  if (requests.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text('No pending requests found', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey)),
                      ),
                    );
                  }
                  return Column(
                    children: requests.map((req) => _buildRequestCard(
                      context,
                      req,
                      isDark
                    )).toList(),
                  );
                },
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  /// Returns the color associated with the mechanic's reward tier.
  Color _getTierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'diamond': return Colors.cyanAccent;
      case 'gold': return Colors.amber;
      case 'silver': return Colors.grey;
      default: return Colors.brown;
    }
  }

  /// Returns a small vertical layout for displaying quick stats like rating or response time.
  Widget _miniStat(String l, String v) {
    return Column(
      children: [
        Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        Text(l, style: const TextStyle(color: Colors.white38, fontSize: 9)),
      ],
    );
  }

  /// Maps an icon name string from the database to a Flutter [IconData].
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

  /// Renders a badge indicating the mechanic's current level/tier.
  Widget _levelBadge({required String level, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.5))),
      child: Row(
        children: [
          Icon(Icons.diamond_rounded, color: color, size: 12),
          const SizedBox(width: 4),
          Text(level, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Displays a card representing a job or SOS request with action buttons.
  /// 
  /// The card style changes if [isSOS] is true to indicate urgency.
  Widget _buildRequestCard(BuildContext context, Map<String, dynamic> req, bool isDark, {bool isSOS = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isSOS ? Colors.redAccent : (isDark ? Colors.white10 : Colors.transparent)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isSOS ? Colors.redAccent : (isDark ? AppColors.neonGreen : AppColors.primary)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(isSOS ? Icons.sos_rounded : Icons.engineering_rounded, color: isSOS ? Colors.redAccent : (isDark ? AppColors.neonGreen : AppColors.secondary)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req['service_type'] ?? 'General Repair',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSOS ? Colors.redAccent : (isDark ? Colors.white : AppColors.textDark),
                      ),
                    ),
                    Text(
                      req['problem_description'] ?? 'No description',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: isDark ? Colors.white10 : AppColors.divider),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on_outlined, color: isDark ? AppColors.darkGrey : AppColors.grey, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    req['customer_location_name'] ?? 'Nearby',
                    style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 13),
                  ),
                ],
              ),
              Text(
                'PKR ${req['total_price'] ?? '0'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSOS ? Colors.redAccent : (isDark ? AppColors.neonGreen : AppColors.secondary),
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rejectRequest(req['id'], isSOS: isSOS),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    side: const BorderSide(color: Colors.redAccent),
                    foregroundColor: Colors.redAccent,
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptRequest(context, req['id'], isSOS: isSOS),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: isSOS ? Colors.redAccent : (isDark ? AppColors.neonGreen : AppColors.primary),
                  ),
                  child: Text(
                    'Accept',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSOS ? Colors.white : (isDark ? Colors.black : Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Updates the status of a booking or SOS request to 'accepted' in the database.
  /// 
  /// Navigates to [JobCompletionScreen] upon successful update.
  Future<void> _acceptRequest(BuildContext context, String bookingId, {bool isSOS = false}) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      if (isSOS) {
        await supabase.from('emergency_sos').update({
          'status': 'assigned',
        }).eq('id', bookingId);
      } else {
        await supabase.from('bookings').update({
          'status': 'accepted',
          'mechanic_id': user.id,
        }).eq('id', bookingId);
      }
      
      if (context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => const JobCompletionScreen()));
      }
    } catch (e) {
      debugPrint('Error accepting request: $e');
    }
  }

  /// Rejects a booking request by updating its status to 'cancelled'.
  Future<void> _rejectRequest(String bookingId, {bool isSOS = false}) async {
    final supabase = Supabase.instance.client;
    try {
      if (isSOS) {
        // Just hide locally or ignore
      } else {
        await supabase.from('bookings').update({'status': 'cancelled'}).eq('id', bookingId);
      }
    } catch (e) {
      debugPrint('Error rejecting request: $e');
    }
  }
}
