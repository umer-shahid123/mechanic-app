import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import 'package:mechanic_app/screens/mechanic_details_screen.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:mechanic_app/widgets/app_avatar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' show cos, sqrt, asin;

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final _supabase = Supabase.instance.client;
  Position? _currentPosition;
  bool _isLocating = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLocating = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLocating = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) setState(() => _isLocating = false);
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = position;
        _isLocating = false;
      });
    }
  }

  double _calculateDistance(double lat2, double lon2) {
    if (_currentPosition == null) return 0.0;
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - _currentPosition!.latitude) * p) / 2 +
        c(_currentPosition!.latitude * p) * c(lat2 * p) *
            (1 - c((lon2 - _currentPosition!.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nearby Experts (5km)', 
          style: TextStyle(
            fontWeight: FontWeight.w800, 
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLocating 
        ? const Center(child: CircularProgressIndicator())
        : StreamBuilder<List<Map<String, dynamic>>>(
            stream: _supabase
                .from('profiles')
                .stream(primaryKey: ['id'])
                .eq('role', 'mechanic')
                .eq('is_online', true),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final allMechanics = snapshot.data ?? [];
              
              // Filter by 5km radius
              final nearbyMechanics = allMechanics.where((m) {
                if (m['location_lat'] == null || m['location_lng'] == null) return false;
                double dist = _calculateDistance(
                  (m['location_lat'] as num).toDouble(), 
                  (m['location_lng'] as num).toDouble()
                );
                return dist <= 5.0;
              }).toList();

              if (nearbyMechanics.isEmpty) {
                return _buildEmptyState(isDark);
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                itemCount: nearbyMechanics.length,
                itemBuilder: (context, index) {
                  final mech = nearbyMechanics[index];
                  double dist = _calculateDistance(
                    (mech['location_lat'] as num).toDouble(), 
                    (mech['location_lng'] as num).toDouble()
                  );

                  return _OfferItem(
                    id: mech['id'],
                    name: mech['full_name'] ?? 'Expert Mechanic', 
                    rating: (mech['rating'] ?? 5.0).toStringAsFixed(1), 
                    price: 'PKR ${mech['base_fee'] ?? '1,500'}', 
                    distance: '${dist.toStringAsFixed(1)} km away', 
                    img: mech['avatar_url'],
                    isDark: isDark,
                  );
                },
              );
            },
          ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network(
            'https://lottie.host/81a54b9d-4357-4b72-a160-58826c796530/w9K8eF3T1y.json',
            height: 180,
            errorBuilder: (c, e, s) => const Icon(Icons.search_rounded, size: 80, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Searching for live mechanics...', 
            style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Currently, no experts are online within 5km of your location.',
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white24 : Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferItem extends StatelessWidget {
  final String name, rating, price, distance, id;
  final String? img;
  final bool isDark;
  
  const _OfferItem({
    required this.id,
    required this.name, 
    required this.rating, 
    required this.price, 
    required this.distance, 
    this.img,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          AppAvatar(url: img, fallbackId: id, radius: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name, 
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$rating • $distance', 
                      style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  price, 
                  style: TextStyle(
                    color: isDark ? AppColors.neonGreen : AppColors.primary, 
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(
                builder: (context) => MechanicDetailsScreen(
                  mechanicId: id,
                  name: name, 
                  rating: rating, 
                  price: price, 
                  img: img ?? 'https://i.pravatar.cc/150?u=$id',
                ),
              ),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(90, 40),
              backgroundColor: isDark ? AppColors.neonGreen : const Color(0xFF2ECC71),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'Accept', 
              style: TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
