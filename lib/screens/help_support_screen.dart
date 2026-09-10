import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildSupportTile('Call Support', Icons.phone_in_talk_rounded, () => _launchUrl('tel:+923000000000'), isDark),
            _buildSupportTile('Email Us', Icons.email_outlined, () => _launchUrl('mailto:support@mechanicapp.com'), isDark),
            _buildSupportTile('Live Chat', Icons.chat_bubble_outline_rounded, () {}, isDark),
            _buildSupportTile('FAQs', Icons.help_outline_rounded, () {}, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportTile(String title, IconData icon, VoidCallback onTap, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: isDark ? AppColors.neonGreen : AppColors.primary),
        title: Text(title, style: TextStyle(color: isDark ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w700)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
