import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:geolocator/geolocator.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MechanicMapScreen extends StatefulWidget {
  const MechanicMapScreen({super.key});

  @override
  State<MechanicMapScreen> createState() => _MechanicMapScreenState();
}

class _MechanicMapScreenState extends State<MechanicMapScreen> {
  final Completer<gmaps.GoogleMapController> _controller = Completer<gmaps.GoogleMapController>();
  gmaps.LatLng _currentPosition = const gmaps.LatLng(31.4697, 74.2728); // Lahore
  bool _isOnline = true;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    _startTracking();
  }

  void _startTracking() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = gmaps.LatLng(position.latitude, position.longitude);
        });
      }
      _updateDatabaseLocation(position);
    });
  }

  Future<void> _updateDatabaseLocation(Position pos) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && _isOnline) {
      await Supabase.instance.client.from('profiles').update({
        'location_lat': pos.latitude,
        'location_lng': pos.longitude,
      }).eq('id', user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      body: Stack(
        children: [
          gmaps.GoogleMap(
            mapType: gmaps.MapType.normal,
            initialCameraPosition: gmaps.CameraPosition(target: _currentPosition, zoom: 15),
            onMapCreated: (gmaps.GoogleMapController controller) {
              _controller.complete(controller);
            },
            myLocationEnabled: true,
            markers: {
              if (_isOnline)
                gmaps.Marker(
                  markerId: const gmaps.MarkerId('current_mechanic'),
                  position: _currentPosition,
                  icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueGreen),
                ),
            },
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                      boxShadow: isDark ? [] : AppColors.softShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: _isOnline ? Colors.green : Colors.red, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _isOnline ? 'Searching for nearby jobs...' : 'You are currently offline', 
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Info Card
          Positioned(
            bottom: 120,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                boxShadow: isDark ? [] : [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isOnline ? 'You are online' : 'You are offline', 
                          style: TextStyle(
                            color: _isOnline ? (isDark ? AppColors.neonGreen : Colors.green) : Colors.red, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _isOnline ? 'Currently visible to customers' : 'Go online to see job requests', 
                          style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isOnline, 
                    onChanged: (v) {
                      setState(() => _isOnline = v);
                      final user = Supabase.instance.client.auth.currentUser;
                      if (user != null) {
                        Supabase.instance.client.from('profiles').update({'is_online': v}).eq('id', user.id);
                      }
                    },
                    activeTrackColor: isDark ? AppColors.neonGreen : AppColors.primary,
                    activeThumbColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
