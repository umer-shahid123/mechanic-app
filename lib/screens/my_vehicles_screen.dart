import 'package:flutter/material.dart';
import 'package:mechanic_app/screens/add_vehicle_screen.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVehicles();
  }

  Future<void> _fetchVehicles() async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final List<Map<String, dynamic>> data = await _supabase
          .from('vehicles')
          .select()
          .eq('owner_id', user.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _vehicles = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Garage', 
          style: TextStyle(
            fontWeight: FontWeight.w800, 
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actions: [
          IconButton(
            onPressed: () async {
              final added = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddVehicleScreen()));
              if (added == true) _fetchVehics();
            },
            icon: Icon(Icons.add_circle_outline_rounded, color: isDark ? AppColors.neonGreen : AppColors.primary),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchVehicles,
            child: _vehicles.isEmpty
              ? _buildEmptyGarage(isDark)
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  itemCount: _vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = _vehicles[index];
                    return _VehicleCard(
                      make: vehicle['make'] ?? '',
                      model: vehicle['model'] ?? '',
                      plate: vehicle['plate_number'] ?? '',
                      year: vehicle['year'] ?? '',
                      mileage: vehicle['mileage']?.toString() ?? '0',
                      isDark: isDark,
                    );
                  },
                ),
          ),
    );
  }

  Widget _buildEmptyGarage(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_rounded, size: 64, color: isDark ? Colors.white10 : Colors.black12),
          const SizedBox(height: 16),
          Text('Your garage is empty', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey)),
        ],
      ),
    );
  }
  
  // Quick hack to fix typo in button call
  void _fetchVehics() => _fetchVehicles();
}

class _VehicleCard extends StatelessWidget {
  final String make, model, plate, year, mileage;
  final bool isDark;

  const _VehicleCard({required this.make, required this.model, required this.plate, required this.year, required this.mileage, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.neonGreen : AppColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.directions_car_filled_rounded, color: isDark ? AppColors.neonGreen : AppColors.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$make $model', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : AppColors.textDark)),
                    Text('Plate: $plate | Year: $year', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.edit_note_rounded, color: Colors.grey, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _vehicleStat(label: 'Mileage', value: '$mileage km', isDark: isDark),
              _vehicleStat(label: 'Last Service', value: 'Recent', isDark: isDark),
              _vehicleStat(label: 'Next Due', value: 'Analyzing', isDark: isDark, isWarning: true),
            ],
          ),
          const Divider(height: 32),
          Row(
            children: [
              _docIcon(Icons.description_outlined, 'Insurance', isDark),
              const SizedBox(width: 16),
              _docIcon(Icons.receipt_long_outlined, 'Registration', isDark),
              const Spacer(),
              Text('View Details', style: TextStyle(color: isDark ? AppColors.neonGreen : AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vehicleStat({required String label, required String value, required bool isDark, bool isWarning = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 9, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
          value, 
          style: TextStyle(
            color: isWarning ? Colors.orange : (isDark ? Colors.white : AppColors.textDark),
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _docIcon(IconData icon, String label, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 14, color: isDark ? Colors.white38 : Colors.black38),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 9)),
      ],
    );
  }
}
