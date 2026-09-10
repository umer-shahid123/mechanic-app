import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlatformHeatmapScreen extends StatefulWidget {
  const PlatformHeatmapScreen({super.key});

  @override
  State<PlatformHeatmapScreen> createState() => _PlatformHeatmapScreenState();
}

class _PlatformHeatmapScreenState extends State<PlatformHeatmapScreen> {
  final _supabase = Supabase.instance.client;
  Set<gmaps.Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadLiveOperations();
  }

  void _loadLiveOperations() {
    _supabase.from('profiles').stream(primaryKey: ['id']).listen((data) {
      final Set<gmaps.Marker> newMarkers = {};
      for (var user in data) {
        if (user['location_lat'] != null && user['location_lng'] != null) {
          final isMech = user['role'] == 'mechanic';
          final isOnline = user['is_online'] ?? false;
          
          newMarkers.add(
            gmaps.Marker(
              markerId: gmaps.MarkerId(user['id']),
              position: gmaps.LatLng((user['location_lat'] as num).toDouble(), (user['location_lng'] as num).toDouble()),
              icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(
                isMech ? (isOnline ? gmaps.BitmapDescriptor.hueGreen : gmaps.BitmapDescriptor.hueYellow) : gmaps.BitmapDescriptor.hueBlue
              ),
              infoWindow: gmaps.InfoWindow(
                title: user['full_name'] ?? 'User',
                snippet: isMech ? (isOnline ? 'Online Mechanic' : 'Offline Mechanic') : 'Customer',
              ),
            ),
          );
        }
      }
      if (mounted) setState(() => _markers = newMarkers);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operations Map', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          gmaps.GoogleMap(
            initialCameraPosition: const gmaps.CameraPosition(target: gmaps.LatLng(31.4697, 74.2728), zoom: 13),
            markers: _markers,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
          ),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppColors.softShadow,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MapLegend(color: Colors.blue, label: 'Customers'),
                  _MapLegend(color: Colors.green, label: 'Active Mechs'),
                  _MapLegend(color: Colors.yellow, label: 'Offline'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _MapLegend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
