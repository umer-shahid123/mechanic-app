import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';

class AdminReportsDownloadScreen extends StatelessWidget {
  const AdminReportsDownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Download Reports', 
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
        padding: const EdgeInsets.all(24),
        children: [
          _reportTypeTile('Monthly Revenue Report', 'August 2024', Icons.monetization_on_rounded, isDark),
          _reportTypeTile('Mechanic Performance', 'All active providers', Icons.engineering_rounded, isDark),
          _reportTypeTile('Customer Growth Analytics', 'Q3 Summary', Icons.trending_up_rounded, isDark),
          _reportTypeTile('Emergency SOS Incident Logs', 'Critical safety data', Icons.sos_rounded, isDark),
          _reportTypeTile('Commission & Payout History', 'Financial breakdown', Icons.account_balance_wallet_rounded, isDark),
        ],
      ),
    );
  }

  Widget _reportTypeTile(String title, String subtitle, IconData icon, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: (isDark ? AppColors.neonGreen : AppColors.primary).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: isDark ? AppColors.neonGreen : AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppColors.textDark)),
                Text(subtitle, style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 11)),
              ],
            ),
          ),
          Builder(
            builder: (context) {
              return IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Preparing $title...')));
                },
                icon: Icon(Icons.download_for_offline_rounded, color: isDark ? AppColors.neonGreen : AppColors.primary),
              );
            }
          ),
        ],
      ),
    );
  }
}
