import 'package:flutter/material.dart';
import 'package:mechanic_app/screens/indrive_request_screen.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SelectServiceScreen extends StatefulWidget {
  final String vehicleId;
  final String vehicleName;

  const SelectServiceScreen({super.key, required this.vehicleId, required this.vehicleName});

  @override
  State<SelectServiceScreen> createState() => _SelectServiceScreenState();
}

class _SelectServiceScreenState extends State<SelectServiceScreen> {
  final _supabase = Supabase.instance.client;
  String? _selectedServiceName;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Stream<List<Map<String, dynamic>>> servicesStream = _supabase
        .from('services')
        .stream(primaryKey: ['id'])
        .eq('is_active', true);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Service', 
          style: TextStyle(
            fontWeight: FontWeight.w800, 
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: servicesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final services = snapshot.data ?? [];

                if (services.isEmpty) {
                  return Center(
                    child: Text(
                      'No services available', 
                      style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey),
                    ),
                  );
                }

                // Auto-select first service if none selected
                if (_selectedServiceName == null && services.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() => _selectedServiceName = services[0]['name']);
                  });
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    bool isSelected = _selectedServiceName == service['name'];
                    
                    return GestureDetector(
                      onTap: () => setState(() => _selectedServiceName = service['name']),
                      child: _ServiceItemTile(
                        icon: _getIconForService(service['icon_name']), 
                        label: service['name'] ?? 'Service', 
                        isSelected: isSelected, 
                        isDark: isDark
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBg : Colors.white,
              border: Border(top: BorderSide(color: isDark ? Colors.white10 : AppColors.divider)),
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _selectedServiceName == null ? null : () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => IndriveRequestScreen(
                        vehicleId: widget.vehicleId,
                        vehicleName: widget.vehicleName,
                        serviceType: _selectedServiceName!,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.neonGreen : AppColors.primary,
                  minimumSize: const Size(double.infinity, 52),
                  disabledBackgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                ),
                child: Text(
                  'Next', 
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                    color: _selectedServiceName == null 
                        ? (isDark ? Colors.white24 : Colors.grey) 
                        : (isDark ? Colors.black : Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForService(String? iconName) {
    switch (iconName) {
      case 'settings': return Icons.settings_rounded;
      case 'engineering': return Icons.engineering_rounded;
      case 'battery': return Icons.battery_charging_full_rounded;
      case 'adjust': return Icons.adjust_rounded;
      case 'ac_unit': return Icons.ac_unit_rounded;
      case 'wash': return Icons.wash_rounded;
      case 'opacity': return Icons.opacity_rounded;
      default: return Icons.more_horiz_rounded;
    }
  }
}

class _ServiceItemTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;

  const _ServiceItemTile({required this.icon, required this.label, required this.isSelected, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected 
            ? (isDark ? AppColors.neonGreen : AppColors.primary) 
            : (isDark ? Colors.white10 : Colors.transparent), 
          width: 2,
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: isDark ? AppColors.neonGreen : AppColors.secondary),
          const SizedBox(width: 16),
          Text(
            label, 
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
          ),
          const Spacer(),
          if (isSelected) 
            Icon(
              Icons.check_circle_rounded, 
              color: isDark ? AppColors.neonGreen : AppColors.primary,
            ),
        ],
      ),
    );
  }
}
