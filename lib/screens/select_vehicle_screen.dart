import 'package:flutter/material.dart';
import 'package:mechanic_app/screens/select_service_screen.dart';
import 'package:mechanic_app/screens/add_vehicle_screen.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SelectVehicleScreen extends StatefulWidget {
  const SelectVehicleScreen({super.key});

  @override
  State<SelectVehicleScreen> createState() => _SelectVehicleScreenState();
}

class _SelectVehicleScreenState extends State<SelectVehicleScreen> {
  final _supabase = Supabase.instance.client;
  String? _selectedVehicleId;
  String? _selectedVehicleName;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _supabase.auth.currentUser;

    if (user == null) return const Scaffold(body: Center(child: Text('Please login')));

    final Stream<List<Map<String, dynamic>>> vehiclesStream = _supabase
        .from('vehicles')
        .stream(primaryKey: ['id'])
        .eq('owner_id', user.id)
        .order('created_at', ascending: false);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black, size: 20), 
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Select Vehicle', 
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black, 
            fontSize: 16, 
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: vehiclesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildErrorView(isDark, snapshot.error.toString());
                }

                final List<Map<String, dynamic>> vehicles = snapshot.data ?? [];

                if (vehicles.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                // Set default selection if none
                if (_selectedVehicleId == null && vehicles.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _selectedVehicleId = vehicles[0]['id'];
                      _selectedVehicleName = '${vehicles[0]['make']} ${vehicles[0]['model']}';
                    });
                  });
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    final v = vehicles[index];
                    bool isSelected = _selectedVehicleId == v['id'];
                    
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedVehicleId = v['id'];
                        _selectedVehicleName = '${v['make']} ${v['model']}';
                      }),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _VehicleCard(
                          name: '${v['make']} ${v['model']}', 
                          plate: v['plate_number'] ?? '', 
                          isSelected: isSelected, 
                          img: 'https://img.freepik.com/free-vector/blue-sedan-car-isolated-white-vector_53876-67357.jpg',
                          isDark: isDark,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(top: BorderSide(color: isDark ? Colors.white10 : AppColors.divider)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
                      );
                    },
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add new Vehicle'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      side: BorderSide(color: isDark ? Colors.white10 : AppColors.divider),
                      foregroundColor: isDark ? Colors.white : AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _selectedVehicleId == null ? null : () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (context) => SelectServiceScreen(
                            vehicleId: _selectedVehicleId!,
                            vehicleName: _selectedVehicleName!,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: isDark ? AppColors.neonGreen : AppColors.primary,
                      disabledBackgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                    ),
                    child: Text(
                      'Next', 
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: _selectedVehicleId == null 
                            ? (isDark ? Colors.white24 : Colors.grey) 
                            : (isDark ? Colors.black : Colors.white),
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

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_rounded, size: 64, color: isDark ? Colors.white10 : Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            'No vehicles added yet', 
            style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(bool isDark, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 20),
            Text(
              'Failed to load garage', 
              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark),
            ),
            const SizedBox(height: 10),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final String name;
  final String plate;
  final bool isSelected;
  final String img;
  final bool isDark;

  const _VehicleCard({required this.name, required this.plate, required this.isSelected, required this.img, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected 
            ? (isDark ? AppColors.neonGreen : AppColors.primary) 
            : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)), 
          width: 1.5,
        ),
        boxShadow: isDark ? [] : AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 70,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                img, 
                fit: BoxFit.contain, 
                errorBuilder: (c, e, s) => Icon(
                  Icons.directions_car_rounded, 
                  color: isDark ? AppColors.darkGrey : AppColors.grey, 
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name, 
                  style: TextStyle(
                    fontWeight: FontWeight.w700, 
                    fontSize: 16,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  plate, 
                  style: TextStyle(
                    color: isDark ? AppColors.darkGrey : AppColors.grey, 
                    fontSize: 13, 
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? (isDark ? AppColors.neonGreen : AppColors.primary) : Colors.transparent,
              border: Border.all(
                color: isSelected 
                  ? (isDark ? AppColors.neonGreen : AppColors.primary) 
                  : (isDark ? Colors.white24 : const Color(0xFFE0E0E0)), 
                width: 2,
              ),
            ),
            child: Icon(
              Icons.check_rounded, 
              size: 14, 
              color: isSelected ? (isDark ? Colors.black : Colors.white) : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
