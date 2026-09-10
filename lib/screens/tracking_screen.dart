import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class TrackingScreen extends StatefulWidget {
  final String bookingId;
  final String mechanicId;

  const TrackingScreen({super.key, required this.bookingId, required this.mechanicId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final _supabase = Supabase.instance.client;
  gmaps.GoogleMapController? _mapController;
  
  // Default Johar Town location
  gmaps.LatLng _mechanicLoc = const gmaps.LatLng(31.4697, 74.2728);
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  void _startTracking() {
    _sub = _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', widget.mechanicId)
        .listen((data) {
          if (data.isNotEmpty) {
            final mech = data.first;
            if (mech['location_lat'] != null && mech['location_lng'] != null) {
              setState(() {
                _mechanicLoc = gmaps.LatLng(
                  (mech['location_lat'] as num).toDouble(),
                  (mech['location_lng'] as num).toDouble(),
                );
              });
              _mapController?.animateCamera(gmaps.CameraUpdate.newLatLng(_mechanicLoc));
            }
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: const Text('Track Expert'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: Stack(
        children: [
          gmaps.GoogleMap(
            initialCameraPosition: gmaps.CameraPosition(target: _mechanicLoc, zoom: 15),
            onMapCreated: (c) => _mapController = c,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            markers: {
              gmaps.Marker(
                markerId: const gmaps.MarkerId('mechanic'),
                position: _mechanicLoc,
                icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueAzure),
                infoWindow: const gmaps.InfoWindow(title: 'Mechanic is here'),
              ),
            },
          ),
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: _buildInfoCard(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=mech'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expert is on the way',
                      style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark),
                    ),
                    Text(
                      'Estimated arrival: 8 mins',
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkGrey : AppColors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.phone_rounded, color: Colors.green, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const LinearProgressIndicator(value: 0.6, backgroundColor: Colors.black12, color: Colors.green),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
