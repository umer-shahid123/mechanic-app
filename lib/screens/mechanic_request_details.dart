import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';

class MechanicRequestDetails extends StatelessWidget {
  const MechanicRequestDetails({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Request Details', 
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Badge
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                      boxShadow: isDark ? [] : AppColors.softShadow,
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow('Service Type', 'Engine Repair', Icons.engineering_rounded, Colors.orange, isDark),
                        Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF5F5F5))),
                        _buildDetailRow('Vehicle', 'Honda Civic (LEM-2500)', Icons.directions_car_rounded, Colors.blue, isDark),
                        Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF5F5F5))),
                        _buildDetailRow('Location', 'Johar Town, Lahore', Icons.location_on_rounded, Colors.red, isDark),
                        Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF5F5F5))),
                        _buildDetailRow('Client Issue', 'Car is overheating while driving and engine fan is not working.', Icons.description_rounded, Colors.grey, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    'Customer Profile', 
                    style: TextStyle(
                      fontSize: 18, 
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
                      boxShadow: isDark ? [] : AppColors.softShadow,
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, 
                          border: Border.all(color: isDark ? AppColors.neonGreen : AppColors.primary, width: 2),
                        ),
                        child: const CircleAvatar(radius: 28, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=umer')),
                      ),
                      title: Text(
                        'Umer', 
                        style: TextStyle(
                          fontWeight: FontWeight.w800, 
                          fontSize: 18,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                      subtitle: Text(
                        '5.0 ⭐ (12 previous jobs)', 
                        style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 13),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildActionCircle(Icons.phone_rounded, Colors.blue),
                          const SizedBox(width: 12),
                          _buildActionCircle(Icons.chat_bubble_rounded, Colors.green),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  Text(
                    'Issue Photos', 
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildIssuePhoto('https://img.freepik.com/free-photo/car-engine-parts_23-2148835520.jpg', isDark),
                      const SizedBox(width: 12),
                      _buildIssuePhoto('https://img.freepik.com/free-photo/car-repair-maintenance-theme-mechanic-repair-engine-car-garage_1150-16584.jpg', isDark),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Sticky Bottom Offer Bar
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -5))],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recommended Offer', 
                        style: TextStyle(
                          color: isDark ? AppColors.darkGrey : AppColors.grey, 
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'PKR 1,400', 
                        style: TextStyle(
                          fontSize: 22, 
                          fontWeight: FontWeight.w900, 
                          color: isDark ? AppColors.neonGreen : AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Navigate to mechanic tracking
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.neonGreen : AppColors.primary,
                      shadowColor: (isDark ? AppColors.neonGreen : AppColors.primary).withValues(alpha: 0.3),
                      elevation: 8,
                    ),
                    child: Text(
                      'Accept & Send Offer', 
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color color, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
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
              const SizedBox(height: 4),
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

  Widget _buildActionCircle(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildIssuePhoto(String url, bool isDark) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
        border: Border.all(color: isDark ? Colors.white10 : Colors.white, width: 2),
        boxShadow: isDark ? [] : AppColors.softShadow,
      ),
    );
  }
}
