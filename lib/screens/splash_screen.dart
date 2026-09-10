import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mechanic_app/screens/admin_dashboard_screen.dart';
import 'package:mechanic_app/screens/home_screen.dart';
import 'package:mechanic_app/screens/mechanic_home_screen.dart';
import 'package:mechanic_app/screens/onboarding_screen.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final session = _supabase.auth.currentSession;
    if (session != null) {
      try {
        final profile = await _supabase
            .from('profiles')
            .select('role')
            .eq('id', session.user.id)
            .maybeSingle();
        
        final role = profile?['role'] ?? 'customer';

        if (mounted) {
          Widget nextScreen;
          if (role == 'admin') {
            nextScreen = const AdminDashboardScreen();
          } else if (role == 'mechanic') {
            nextScreen = const MechanicHomeScreen();
          } else {
            nextScreen = const HomeScreen();
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => nextScreen),
          );
        }
      } catch (e) {
        if (mounted) _goToOnboarding();
      }
    } else {
      _goToOnboarding();
    }
  }

  void _goToOnboarding() {
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => const OnboardingScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.network(
              'https://lottie.host/81a54b9d-4357-4b72-a160-58826c796530/w9K8eF3T1y.json', // Mechanic Tool
              height: 200,
              errorBuilder: (c, e, s) => const Icon(Icons.build_rounded, size: 80, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'MECHANIC APP',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4),
            ),
            const Text('The Future of Car Repair', style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
