import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mechanic_app/screens/live_tracking_screen.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A screen that displays detailed information about a specific mechanic.
class MechanicDetailsScreen extends StatefulWidget {
  final String mechanicId;
  final String name;
  final String rating;
  final String price;
  final String img;

  const MechanicDetailsScreen({
    super.key,
    required this.mechanicId,
    required this.name,
    required this.rating,
    required this.price,
    required this.img,
  });

  @override
  State<MechanicDetailsScreen> createState() => _MechanicDetailsScreenState();
}

class _MechanicDetailsScreenState extends State<MechanicDetailsScreen> {
  bool _isBooking = false;
  bool _isMechanicOnline = false;
  StreamSubscription? _statusSubscription;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _listenToMechanicStatus();
  }

  void _listenToMechanicStatus() {
    _statusSubscription = _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', widget.mechanicId)
        .listen((data) {
      if (data.isNotEmpty && mounted) {
        setState(() {
          _isMechanicOnline = data.first['is_online'] ?? false;
        });
      }
    });
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleBooking() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book a mechanic')),
      );
      return;
    }

    if (!_isMechanicOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This mechanic is currently offline.')),
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      // Create a real booking record in Supabase
      final booking = await _supabase.from('bookings').insert({
        'customer_id': user.id,
        'mechanic_id': widget.mechanicId,
        'service_type': 'General Repair',
        'status': 'pending',
        'total_price': double.tryParse(widget.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0,
      }).select().single();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LiveTrackingScreen(
              bookingId: booking['id'],
              mechanicId: widget.mechanicId,
              mechanicName: widget.name,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mechanic Profile',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? AppColors.neonGreen : AppColors.primary, width: 2),
                          ),
                          child: CircleAvatar(radius: 60, backgroundImage: NetworkImage(widget.img)),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : AppColors.textDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _isMechanicOnline ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              widget.rating,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : AppColors.textDark,
                              ),
                            ),
                            Text(
                              ' (120 reviews)',
                              style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Professional mechanic with over 10 years of experience in engine repair, general maintenance and electrical issues. Certified by leading auto manufacturers.',
                    style: TextStyle(color: Colors.grey, height: 1.5, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(top: BorderSide(color: isDark ? Colors.white10 : AppColors.divider)),
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: (_isBooking || !_isMechanicOnline) ? null : _handleBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isMechanicOnline 
                      ? (isDark ? AppColors.neonGreen : AppColors.primary)
                      : Colors.grey,
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isBooking
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        _isMechanicOnline ? 'Confirm & Book' : 'Mechanic Offline', 
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
