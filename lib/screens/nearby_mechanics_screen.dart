import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mechanic_app/screens/mechanic_details_screen.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:mechanic_app/widgets/app_avatar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NearbyMechanicsScreen extends StatefulWidget {
  const NearbyMechanicsScreen({super.key});

  @override
  State<NearbyMechanicsScreen> createState() => _NearbyMechanicsScreenState();
}

class _NearbyMechanicsScreenState extends State<NearbyMechanicsScreen> {
  final _supabase = Supabase.instance.client;
  String _selectedFilter = 'Nearest';
  
  // Current coordinates
  double? _userLat;
  double? _userLng;
  bool _isLocating = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() {
          _userLat = position.latitude;
          _userLng = position.longitude;
          _isLocating = false;
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        setState(() {
          // Fallback to Lahore if GPS fails
          _userLat = 31.4697;
          _userLng = 74.2728;
          _isLocating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLocating) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final Stream<List<Map<String, dynamic>>> mechanicsStream = _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('role', 'mechanic')
        .eq('is_online', true)
        .eq('is_verified', true)
        .eq('is_blocked', false);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Nearby Experts', 
          style: TextStyle(
            fontWeight: FontWeight.w800, 
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: Column(
        children: [
          _buildFilterBar(isDark),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: mechanicsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final List<Map<String, dynamic>> mechanics = snapshot.data ?? [];
                
                // Filter by distance locally
                final nearbyMechanics = mechanics.where((mech) {
                  if (mech['location_lat'] == null || mech['location_lng'] == null) return false;
                  
                  double distance = _calculateDistance(
                    _userLat!, _userLng!, 
                    (mech['location_lat'] as num).toDouble(), 
                    (mech['location_lng'] as num).toDouble()
                  );
                  return distance <= 15.0; // Show within 15km
                }).toList();

                if (nearbyMechanics.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: nearbyMechanics.length,
                  itemBuilder: (context, index) {
                    final mech = nearbyMechanics[index];
                    return _MechanicCard(
                      name: mech['full_name'] ?? 'Unknown Mechanic',
                      rating: (mech['rating'] ?? 0.0).toDouble(),
                      jobs: mech['jobs_completed'] ?? 0,
                      distance: 'Nearby', 
                      price: 'PKR ${mech['base_fee'] ?? '1500'}',
                      time: '15 min',
                      img: mech['avatar_url'],
                      id: mech['id'],
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

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Simple Euclidean distance for local filtering (approximation)
    // For more accuracy, use geolocator's distanceBetween or haversine formula
    return (lat1 - lat2).abs() + (lon1 - lon2).abs() * 111.0;
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_rounded, size: 60, color: isDark ? Colors.white10 : Colors.black12),
          const SizedBox(height: 16),
          Text(
            'No verified mechanics within 5km.',
            style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Try refreshing or changing your location.',
            style: TextStyle(color: isDark ? Colors.white24 : Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    final filters = ['Nearest', 'Top Rated', 'Best Price', 'Experienced'];
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedFilter == filters[index];
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filters[index]),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? (isDark ? AppColors.neonGreen : AppColors.primary) : (isDark ? AppColors.darkSurface : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? Colors.transparent : (isDark ? Colors.white10 : AppColors.divider)),
              ),
              child: Center(
                child: Text(
                  filters[index],
                  style: TextStyle(
                    color: isSelected ? Colors.black : (isDark ? Colors.white70 : AppColors.textDark),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MechanicCard extends StatelessWidget {
  final String name, distance, price, time, id;
  final String? img;
  final double rating;
  final int jobs;
  final bool isDark;

  const _MechanicCard({required this.name, required this.rating, required this.jobs, required this.distance, required this.price, required this.time, this.img, required this.id, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              AppAvatar(url: img, fallbackId: id, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                        Text(' $rating | $jobs Jobs', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(price, style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? AppColors.neonGreen : AppColors.secondary, fontSize: 14)),
                  Text('Estimated', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 9)),
                ],
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _info(Icons.location_on_outlined, distance, isDark),
              _info(Icons.access_time_rounded, time, isDark),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => MechanicDetailsScreen(
                        mechanicId: id,
                        name: name, 
                        rating: rating.toString(), 
                        price: price, 
                        img: img ?? 'https://i.pravatar.cc/150?u=$id',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(100, 36), 
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  backgroundColor: isDark ? AppColors.neonGreen : AppColors.primary,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Request', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(IconData icon, String text, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 14, color: isDark ? AppColors.darkGrey : AppColors.grey),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 11)),
      ],
    );
  }
}
