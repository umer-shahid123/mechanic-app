import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.neonGreen : Colors.blue).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_active_rounded, color: isDark ? AppColors.neonGreen : Colors.blue, size: 20),
              ),
              title: Text(
                index == 0 ? 'Booking Confirmed' : 'Platform Update',
                style: TextStyle(color: isDark ? Colors.white : AppColors.textDark, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'Your mechanic is on the way to your location.',
                style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 12),
              ),
              trailing: const Text('2h ago', style: TextStyle(color: Colors.grey, fontSize: 10)),
            ),
          );
        },
      ),
    );
  }
}
