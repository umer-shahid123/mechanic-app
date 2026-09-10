import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';

class AppAvatar extends StatelessWidget {
  final String? url;
  final double radius;
  final String? fallbackId;
  final String? gender;

  const AppAvatar({
    super.key,
    this.url,
    this.radius = 24,
    this.fallbackId,
    this.gender,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Construct safe URL: avoid "u=null"
    String safeUrl = url ?? '';
    if (safeUrl.isEmpty && fallbackId != null) {
      safeUrl = 'https://i.pravatar.cc/150?u=$fallbackId';
    } else if (safeUrl.isEmpty) {
      // Final fallback if everything is null
      return _buildPlaceholder(isDark);
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.grey[200],
      child: ClipOval(
        child: Image.network(
          safeUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder(isDark);
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                width: radius,
                height: radius,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    IconData icon = Icons.person_rounded;
    if (gender == 'female') {
      icon = Icons.woman_rounded;
    } else if (gender == 'male') {
      icon = Icons.man_rounded;
    }

    return Container(
      width: radius * 2,
      height: radius * 2,
      color: isDark ? AppColors.darkSurface : Colors.grey[200],
      child: Icon(
        icon,
        size: radius,
        color: isDark ? Colors.white24 : Colors.grey[400],
      ),
    );
  }
}
