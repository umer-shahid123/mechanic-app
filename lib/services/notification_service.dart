import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _supabase = Supabase.instance.client;
  GlobalKey<ScaffoldMessengerState>? _messengerKey;
  StreamSubscription? _notifSubscription;
  StreamSubscription? _bookingSubscription;

  void setMessengerKey(GlobalKey<ScaffoldMessengerState> key) {
    _messengerKey = key;
  }

  Future<void> initialize() async {
    _stopListening();
    _listenToNotifications();
    _listenToNewJobsForMechanics();
  }

  void _stopListening() {
    _notifSubscription?.cancel();
    _bookingSubscription?.cancel();
  }

  void _listenToNotifications() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _notifSubscription = _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .eq('is_read', false)
        .listen((data) {
          if (data.isNotEmpty && data.last != null) {
            final notif = data.last;
            _showInAppNotification(notif);
            _markAsRead(notif['id']);
          }
        });
  }

  void _listenToNewJobsForMechanics() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Check if user is a mechanic
    final profile = await _supabase.from('profiles').select('role').eq('id', user.id).maybeSingle();
    if (profile?['role'] != 'mechanic') return;

    // Listen for new pending bookings
    _bookingSubscription = _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .listen((data) {
          if (data.isNotEmpty) {
            final latestBooking = data.last;
            // Check if it's new (created in the last few seconds) to avoid old alerts
            final createdAt = DateTime.parse(latestBooking['created_at']);
            if (DateTime.now().difference(createdAt).inSeconds < 10) {
              _showInAppNotification({
                'title': 'New Job Request! 🛠️',
                'body': 'A customer needs ${latestBooking['service_type'] ?? 'a repair'}. Tap to view.',
                'id': latestBooking['id'], // Just for logic
              });
            }
          }
        });
  }

  void _showInAppNotification(Map<String, dynamic> notif) {
    if (_messengerKey?.currentState != null) {
      _messengerKey!.currentState!.clearSnackBars(); // Show only one at a time
      _messengerKey!.currentState!.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.notifications_active_rounded, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notif['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                    Text(notif['body'], style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 5),
          backgroundColor: const Color(0xFF0D1B2A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'OPEN', 
            onPressed: () {
              // Navigation logic could be added here
            },
            textColor: Colors.green,
          ),
        ),
      );
    }
  }

  Future<void> _markAsRead(String id) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }
}
