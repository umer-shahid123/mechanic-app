import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mechanic_app/theme/app_theme.dart';

class ServiceCompletedScreen extends StatelessWidget {
  const ServiceCompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Lottie.network(
                'https://lottie.host/81a54b9d-4357-4b72-a160-58826c796530/w9K8eF3T1y.json', // Success Celebration
                height: 250,
                repeat: false,
                errorBuilder: (c, e, s) => const Icon(Icons.check_circle_rounded, size: 80, color: Colors.green),
              ),
              Text(
                'Job Well Done!', 
                style: TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              Text(
                'Umer, your car is now road-ready.', 
                style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                ),
                child: Column(
                  children: [
                    _Row('Service', 'Engine Repair', isDark),
                    _Row('Amount', 'PKR 1,500', isDark),
                    _Row('Payment', 'Wallet', isDark),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.neonGreen : AppColors.primary,
                ),
                child: Text(
                  'Back to Home', 
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Report a problem with this service',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String l, v;
  final bool isDark;
  const _Row(this.l, this.v, this.isDark);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            l, 
            style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey),
          ), 
          Text(
            v, 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
