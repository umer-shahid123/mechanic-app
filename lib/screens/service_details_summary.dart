import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';

class ServiceDetailsSummary extends StatelessWidget {
  const ServiceDetailsSummary({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Booking Details', 
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: (isDark ? AppColors.neonGreen : AppColors.success).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded, 
                    color: isDark ? AppColors.neonGreen : AppColors.success, 
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Completed', 
                    style: TextStyle(
                      color: isDark ? AppColors.neonGreen : AppColors.success, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Details Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                boxShadow: isDark ? [] : AppColors.softShadow,
              ),
              child: Column(
                children: [
                  _buildItem('Booking ID', '#BK-12048', Icons.tag_rounded, isDark),
                  Divider(height: 40, color: isDark ? Colors.white10 : AppColors.divider),
                  _buildItem('Date & Time', '30 May 2024, 11:30 AM', Icons.calendar_month_rounded, isDark),
                  Divider(height: 40, color: isDark ? Colors.white10 : AppColors.divider),
                  _buildItem('Service', 'Engine Repair', Icons.engineering_rounded, isDark),
                  Divider(height: 40, color: isDark ? Colors.white10 : AppColors.divider),
                  _buildItem('Mechanic', 'All Auto Expert', Icons.person_rounded, isDark),
                  Divider(height: 40, color: isDark ? Colors.white10 : AppColors.divider),
                  _buildItem('Vehicle', 'Honda Civic (LEM-2500)', Icons.directions_car_rounded, isDark),
                  Divider(height: 40, color: isDark ? Colors.white10 : AppColors.divider),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount', 
                        style: TextStyle(
                          color: isDark ? AppColors.darkGrey : AppColors.grey, 
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'PKR 1,500', 
                        style: TextStyle(
                          fontSize: 20, 
                          fontWeight: FontWeight.w900, 
                          color: isDark ? AppColors.neonGreen : AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {},
              icon: Icon(Icons.download_rounded, color: isDark ? Colors.black : Colors.white),
              label: Text(
                'Download Invoice', 
                style: TextStyle(color: isDark ? Colors.black : Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.neonGreen : AppColors.secondary,
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: BorderSide(color: isDark ? Colors.white10 : AppColors.divider),
              ),
              child: Text(
                'Back to Home', 
                style: TextStyle(color: isDark ? Colors.white70 : AppColors.textDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(String label, String value, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F5), 
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon, 
            color: isDark ? AppColors.neonGreen : AppColors.secondary, 
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label, 
                style: TextStyle(
                  color: isDark ? AppColors.darkGrey : AppColors.grey, 
                  fontSize: 12, 
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value, 
                style: TextStyle(
                  fontWeight: FontWeight.w700, 
                  fontSize: 15,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
