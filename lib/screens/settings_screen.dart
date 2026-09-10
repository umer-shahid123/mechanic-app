import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:mechanic_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _pushNotifications = true;
  bool _biometricAuth = false;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = _prefs.getBool('push_notifications') ?? true;
      _biometricAuth = _prefs.getBool('biometric_auth') ?? false;
    });
  }

  Future<void> _toggleBiometrics(bool value) async {
    if (value) {
      bool canCheckBiometrics = await _auth.canCheckBiometrics;
      if (canCheckBiometrics) {
        bool authenticated = await _auth.authenticate(
          localizedReason: 'Please authenticate to enable biometric login',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        if (authenticated) {
          setState(() => _biometricAuth = true);
          await _prefs.setBool('biometric_auth', true);
          _showToast('biometrics_activated'.tr());
        }
      } else {
        _showToast('Biometrics not available on this device');
      }
    } else {
      setState(() => _biometricAuth = false);
      await _prefs.setBool('biometric_auth', false);
      _showToast('biometrics_deactivated'.tr());
    }
  }

  Future<void> _handleChangePassword() async {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final TextEditingController controller = TextEditingController();

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('change_password'.tr(), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your new secure password.', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('cancel'.tr())),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: Text('update'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && controller.text.isNotEmpty) {
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: controller.text),
        );
        if (mounted) _showToast('password_updated'.tr(), isGreen: true);
      } catch (e) {
        if (mounted) _showToast('Error: $e', isError: true);
      }
    }
  }

  void _showLanguagePicker() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final List<Map<String, dynamic>> languages = [
      {'name': 'English (US)', 'locale': const Locale('en', 'US')},
      {'name': 'Urdu (اردو)', 'locale': const Locale('ur', 'PK')},
      {'name': 'Arabic (العربية)', 'locale': const Locale('ar', 'SA')},
      {'name': 'Spanish (Español)', 'locale': const Locale('es', 'ES')},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('select_language'.tr(), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : AppColors.textDark)),
            const SizedBox(height: 20),
            ...languages.map((lang) {
              bool isSelected = context.locale == lang['locale'];
              return ListTile(
                title: Text(lang['name'], style: TextStyle(color: isDark ? Colors.white70 : AppColors.textDark, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                trailing: isSelected ? Icon(Icons.check_circle_rounded, color: isDark ? AppColors.neonGreen : AppColors.primary) : null,
                onTap: () {
                  context.setLocale(lang['locale']);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showToast(String msg, {bool isError = false, bool isGreen = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: isError ? Colors.red : (isGreen ? Colors.green : null),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: Text('settings'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('preferences'.tr(), isDark),
            _buildSwitchTile('push_notifications'.tr(), _pushNotifications, (val) async {
              setState(() => _pushNotifications = val);
              await _prefs.setBool('push_notifications', val);
              _showToast(val ? 'notifications_enabled'.tr() : 'notifications_muted'.tr());
            }, isDark),
            _buildSwitchTile('dark_mode'.tr(), isDark, (val) {
              MechanicApp.of(context).toggleTheme();
            }, isDark),
            _buildSwitchTile('biometric_auth'.tr(), _biometricAuth, _toggleBiometrics, isDark),
            const SizedBox(height: 32),
            _buildSectionTitle('account'.tr(), isDark),
            _buildNavigationTile('change_password'.tr(), Icons.lock_outline_rounded, isDark, onTap: _handleChangePassword),
            _buildNavigationTile('language'.tr(), Icons.language_rounded, isDark, subtitle: _getCurrentLanguageName(), onTap: _showLanguagePicker),
            _buildNavigationTile('privacy_settings'.tr(), Icons.privacy_tip_rounded, isDark, onTap: () {
              _showToast('Privacy settings are managed by system security.');
            }),
          ],
        ),
      ),
    );
  }

  String _getCurrentLanguageName() {
    if (context.locale == const Locale('ur', 'PK')) return 'Urdu (اردو)';
    if (context.locale == const Locale('ar', 'SA')) return 'Arabic (العربية)';
    if (context.locale == const Locale('es', 'ES')) return 'Spanish (Español)';
    return 'English (US)';
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white70 : Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
      ),
      child: SwitchListTile.adaptive(
        title: Text(title, style: TextStyle(color: isDark ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 14)),
        value: value,
        onChanged: onChanged,
        activeColor: isDark ? AppColors.neonGreen : AppColors.primary,
      ),
    );
  }

  Widget _buildNavigationTile(String title, IconData icon, bool isDark, {String? subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: (isDark ? AppColors.neonGreen : AppColors.primary).withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: isDark ? AppColors.neonGreen : AppColors.primary, size: 20),
        ),
        title: Text(title, style: TextStyle(color: isDark ? Colors.white : AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 12)) : null,
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
      ),
    );
  }
}
