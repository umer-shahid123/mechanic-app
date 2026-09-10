import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SafetyHubScreen extends StatelessWidget {
  const SafetyHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Safety & Protection', 
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
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildHeroCard(isDark),
          const SizedBox(height: 32),
          Text(
            'Emergency Assistance', 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold, 
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            'SOS Emergency Alert', 
            'Direct line to our 24/7 security team.', 
            Icons.sos_rounded, 
            Colors.red, 
            isDark,
            onTap: () => _triggerSOS(context),
          ),
          _buildActionTile(
            'Local Authorities', 
            'Quick dial for Police or Ambulance (15/1122).', 
            Icons.local_police_rounded, 
            Colors.blue, 
            isDark,
            onTap: () {}, // Would use url_launcher
          ),
          const SizedBox(height: 32),
          Text(
            'Repair Safety Tips', 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold, 
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          _buildTipCard('Verify Identity', 'Always check the mechanic\'s digital ID in the app before allowing them to touch your vehicle.', isDark),
          _buildTipCard('Stay in Public', 'If possible, request repairs in well-lit, public areas or shared spaces.', isDark),
          _buildTipCard('Share Progress', 'Use the "Share Live Trip" feature so friends can track the service timing.', isDark),
        ],
      ),
    );
  }

  void _triggerSOS(BuildContext context) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('emergency_sos').insert({
        'customer_id': user.id,
        'location_lat': 31.4697, // Lahore Demo
        'location_lng': 74.2728,
        'status': 'searching',
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SOS ACTIVE: Our team has been alerted!'), 
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('SOS Error: $e');
    }
  }

  Widget _buildHeroCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.darkGradient : AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          const Icon(Icons.shield_rounded, color: Colors.white, size: 64),
          const SizedBox(height: 16),
          const Text(
            'Your Safety is Our Priority',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            'Every mechanic is verified and every trip is monitored in real-time.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, String desc, IconData icon, Color color, bool isDark, {required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppColors.textDark)),
        subtitle: Text(desc, style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkGrey : AppColors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      ),
    );
  }

  Widget _buildTipCard(String title, String tip, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? AppColors.neonGreen : AppColors.primary)),
          const SizedBox(height: 4),
          Text(tip, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, height: 1.4)),
        ],
      ),
    );
  }
}
