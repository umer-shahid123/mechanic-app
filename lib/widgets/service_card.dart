import 'package:flutter/material.dart';
import 'package:mechanic_app/screens/select_vehicle_screen.dart';
import 'package:mechanic_app/theme/app_theme.dart';

class ServiceCard extends StatefulWidget {
  final IconData icon;
  final String label;

  const ServiceCard({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        // Directing to SelectVehicle first as it's the required first step of the booking flow
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SelectVehicleScreen()),
        );
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Column(
          children: [
            Hero(
              tag: 'service_${widget.label}',
              child: Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                  boxShadow: AppColors.softShadow,
                ),
                child: Icon(widget.icon, color: AppColors.secondary, size: 22),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
