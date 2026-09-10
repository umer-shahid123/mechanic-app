import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:mechanic_app/screens/chat_screen.dart';
import 'package:mechanic_app/screens/payment_screen.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String bookingId;
  final String mechanicId;
  final String mechanicName;

  const LiveTrackingScreen({
    super.key,
    required this.bookingId,
    required this.mechanicId,
    required this.mechanicName,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final Completer<gmaps.GoogleMapController> _controller = Completer<gmaps.GoogleMapController>();
  final _supabase = Supabase.instance.client;
  
  gmaps.LatLng _mechanicLocation = const gmaps.LatLng(31.4697, 74.2728); // Default: Lahore
  gmaps.LatLng? _userLocation;
  StreamSubscription? _locationSubscription;
  bool _isLoading = true;

  // Polyline variables
  List<gmaps.LatLng> polylineCoordinates = [];
  Map<gmaps.PolylineId, gmaps.Polyline> polylines = {};
  late PolylinePoints polylinePoints;

  @override
  void initState() {
    super.initState();
    polylinePoints = PolylinePoints(apiKey: dotenv.env['LOCATION_API_KEY'] ?? '');
    _initTracking();
  }

  Future<void> _initTracking() async {
    // 1. Listen to user's real-time location
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _userLocation = gmaps.LatLng(position.latitude, position.longitude);
        });
        _getPolyline();
        // Update user location in DB so mechanic can see it
        _updateMyPositionInDB(position);
      }
    });

    // 2. Listen to mechanic location from Supabase
    _locationSubscription = _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', widget.mechanicId)
        .listen((data) {
          if (data.isNotEmpty) {
            final profile = data.first;
            if (profile['location_lat'] != null && profile['location_lng'] != null) {
              final newLoc = gmaps.LatLng(
                (profile['location_lat'] as num).toDouble(),
                (profile['location_lng'] as num).toDouble(),
              );
              
              if (mounted) {
                setState(() {
                  _mechanicLocation = newLoc;
                  _isLoading = false;
                });
                _getPolyline();
                _updateCamera();
              }
            }
          }
        }, onError: (error) {
          debugPrint('Supabase Stream Error: $error');
          if (mounted) setState(() => _isLoading = false);
        });
  }

  Future<void> _updateMyPositionInDB(Position pos) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    try {
      await _supabase.from('profiles').update({
        'location_lat': pos.latitude,
        'location_lng': pos.longitude,
      }).eq('id', user.id);
    } catch (_) {}
  }

  void _getPolyline() async {
    if (_userLocation == null) return;
    
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(_mechanicLocation.latitude, _mechanicLocation.longitude),
        destination: PointLatLng(_userLocation!.latitude, _userLocation!.longitude),
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      polylineCoordinates.clear();
      for (var point in result.points) {
        polylineCoordinates.add(gmaps.LatLng(point.latitude, point.longitude));
      }
      _addPolyline();
    }
  }

  void _addPolyline() {
    gmaps.PolylineId id = const gmaps.PolylineId("poly");
    gmaps.Polyline polyline = gmaps.Polyline(
      polylineId: id,
      color: AppColors.primary,
      points: polylineCoordinates,
      width: 5,
    );
    setState(() {
      polylines[id] = polyline;
    });
  }

  Future<void> _updateCamera() async {
    if (_userLocation == null) return;
    final gmaps.GoogleMapController controller = await _controller.future;
    
    // Bounds to show both mechanic and user
    gmaps.LatLngBounds bounds;
    if (_mechanicLocation.latitude > _userLocation!.latitude) {
      bounds = gmaps.LatLngBounds(
        southwest: gmaps.LatLng(_userLocation!.latitude, _userLocation!.longitude < _mechanicLocation.longitude ? _userLocation!.longitude : _mechanicLocation.longitude),
        northeast: gmaps.LatLng(_mechanicLocation.latitude, _userLocation!.longitude > _mechanicLocation.longitude ? _userLocation!.longitude : _mechanicLocation.longitude),
      );
    } else {
      bounds = gmaps.LatLngBounds(
        southwest: gmaps.LatLng(_mechanicLocation.latitude, _mechanicLocation.longitude < _userLocation!.longitude ? _mechanicLocation.longitude : _userLocation!.longitude),
        northeast: gmaps.LatLng(_userLocation!.latitude, _mechanicLocation.longitude > _userLocation!.longitude ? _userLocation!.longitude : _userLocation!.longitude),
      );
    }
    
    controller.animateCamera(gmaps.CameraUpdate.newLatLngBounds(bounds, 100));
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      body: Stack(
        children: [
          gmaps.GoogleMap(
            mapType: gmaps.MapType.normal,
            initialCameraPosition: gmaps.CameraPosition(target: _mechanicLocation, zoom: 15),
            onMapCreated: (gmaps.GoogleMapController controller) {
              _controller.complete(controller);
            },
            polylines: Set<gmaps.Polyline>.of(polylines.values),
            markers: {
              gmaps.Marker(
                markerId: const gmaps.MarkerId('mechanic'),
                position: _mechanicLocation,
                infoWindow: gmaps.InfoWindow(title: widget.mechanicName),
                icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueAzure),
              ),
              if (_userLocation != null)
                gmaps.Marker(
                  markerId: const gmaps.MarkerId('user'),
                  position: _userLocation!,
                  infoWindow: const gmaps.InfoWindow(title: 'My Location'),
                  icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
                ),
            },
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),
          
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: isDark ? [] : [const BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      child: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black, size: 24),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isDark ? [] : [const BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: Text('Live Tracking', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black)),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // Bottom Info Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                boxShadow: isDark ? [] : [const BoxShadow(color: Colors.black12, blurRadius: 30, spreadRadius: 5)],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                    ),
                    Row(
                      children: [
                        CircleAvatar(radius: 30, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${widget.mechanicId}')),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.mechanicName, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : AppColors.textDark)),
                              const Text('Arriving in few minutes', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                        ),
                        _ActionBtn(
                          icon: Icons.chat_bubble_rounded, 
                          color: Colors.blue, 
                          isDark: isDark,
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(
                              bookingId: widget.bookingId,
                              receiverId: widget.mechanicId,
                              receiverName: widget.mechanicName,
                            )));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => PaymentScreen(
                              bookingId: widget.bookingId,
                              amount: 1500,
                            )),
                          );
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: isDark ? AppColors.neonGreen : AppColors.primary),
                        child: Text('Complete Service', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.black : Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;
  const _ActionBtn({required this.icon, required this.color, required this.onTap, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}
