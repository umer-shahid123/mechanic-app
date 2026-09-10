import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';

class MechanicAvailabilityScreen extends StatefulWidget {
  const MechanicAvailabilityScreen({super.key});

  @override
  State<MechanicAvailabilityScreen> createState() => _MechanicAvailabilityScreenState();
}

class _MechanicAvailabilityScreenState extends State<MechanicAvailabilityScreen> {
  bool _isOnline = true;
  double _radius = 5.0;
  final List<String> _selectedAreas = ['Johar Town', 'Model Town'];
  final List<String> _allAreas = ['Johar Town', 'Model Town', 'Wapda Town', 'Garden Town', 'Township', 'DHA Phase 5'];

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: Text('Availability & Area', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusToggle(isDark),
            const SizedBox(height: 32),
            _buildRadiusSelector(isDark),
            const SizedBox(height: 32),
            _buildServiceAreaSelector(isDark),
            const SizedBox(height: 32),
            _buildEquipmentSection(isDark),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Save Availability Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(color: _isOnline ? Colors.green : Colors.grey, shape: BoxShape.circle),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isOnline ? 'Online' : 'Offline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppColors.textDark)),
                Text(_isOnline ? 'Accepting new job requests' : 'Not visible to customers', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 12)),
              ],
            ),
          ),
          Switch.adaptive(
            value: _isOnline,
            onChanged: (v) => setState(() => _isOnline = v),
            activeThumbColor: isDark ? AppColors.neonGreen : AppColors.primary,
            activeTrackColor: (isDark ? AppColors.neonGreen : AppColors.primary).withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Working Radius', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : AppColors.textDark)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Distance Limit', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 13)),
                  Text('${_radius.toInt()} km', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? AppColors.neonGreen : AppColors.primary)),
                ],
              ),
              Slider(
                value: _radius,
                min: 1, max: 20,
                divisions: 19,
                activeColor: isDark ? AppColors.neonGreen : AppColors.primary,
                onChanged: (v) => setState(() => _radius = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceAreaSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Service Areas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : AppColors.textDark)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allAreas.map((area) {
            bool isSelected = _selectedAreas.contains(area);
            return GestureDetector(
              onTap: () {
                setState(() {
                  isSelected ? _selectedAreas.remove(area) : _selectedAreas.add(area);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? (isDark ? AppColors.neonGreen : AppColors.primary) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? Colors.transparent : (isDark ? Colors.white10 : AppColors.divider)),
                ),
                child: Text(
                  area,
                  style: TextStyle(
                    color: isSelected ? Colors.black : (isDark ? Colors.white70 : AppColors.textDark),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEquipmentSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('My Equipment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : AppColors.textDark)),
        const SizedBox(height: 12),
        _equipmentTile('Diagnostic Scanner', true, isDark),
        _equipmentTile('Battery Tester', true, isDark),
        _equipmentTile('Hydraulic Jack', false, isDark),
      ],
    );
  }

  Widget _equipmentTile(String name, bool hasIt, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(hasIt ? Icons.check_circle_rounded : Icons.radio_button_off_rounded, color: hasIt ? Colors.green : Colors.grey, size: 18),
          const SizedBox(width: 12),
          Text(name, style: TextStyle(color: isDark ? Colors.white70 : AppColors.textDark, fontSize: 13)),
        ],
      ),
    );
  }
}
