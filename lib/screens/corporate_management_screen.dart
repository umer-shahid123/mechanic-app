import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CorporateManagementScreen extends StatefulWidget {
  const CorporateManagementScreen({super.key});

  @override
  State<CorporateManagementScreen> createState() => _CorporateManagementScreenState();
}

class _CorporateManagementScreenState extends State<CorporateManagementScreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = true;
  Map<String, dynamic>? _myFleet;

  @override
  void initState() {
    super.initState();
    _loadFleetData();
  }

  Future<void> _loadFleetData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final fleet = await _supabase
          .from('fleets')
          .select()
          .eq('manager_id', user.id)
          .maybeSingle();
      
      setState(() {
        _myFleet = fleet;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading fleet: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: const Text('Fleet Command'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _myFleet == null 
              ? _buildEmptyState(isDark)
              : _buildFleetView(isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_rounded, size: 80, color: isDark ? AppColors.neonGreen : AppColors.primary),
            const SizedBox(height: 24),
            Text('Register Your Fleet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
            const SizedBox(height: 8),
            Text('Centralize repair management for all your company vehicles.', textAlign: TextAlign.center, style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _createFleet,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52), backgroundColor: isDark ? AppColors.neonGreen : AppColors.primary),
              child: const Text('Initialize Fleet', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFleetView(bool isDark) {
    final Stream<List<Map<String, dynamic>>> fleetVehiclesStream = _supabase
        .from('vehicles')
        .stream(primaryKey: ['id'])
        .eq('fleet_id', _myFleet!['id']);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: isDark ? AppColors.darkGradient : AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_city_rounded, color: Colors.white, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_myFleet!['name'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text('Enterprise Account Active', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: fleetVehiclesStream,
            builder: (context, snapshot) {
              final vehicles = snapshot.data ?? [];
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: vehicles.length,
                itemBuilder: (context, index) {
                  final v = vehicles[index];
                  return Card(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: ListTile(
                      leading: const Icon(Icons.local_shipping_rounded),
                      title: Text('${v['make']} ${v['model']}', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
                      subtitle: Text(v['plate_number'], style: const TextStyle(fontSize: 12)),
                    ),
                  );
                },
              );
            }
          ),
        ),
      ],
    );
  }

  Future<void> _createFleet() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    
    await _supabase.from('fleets').insert({
      'manager_id': user.id,
      'name': 'My Enterprise Fleet',
    });
    _loadFleetData();
  }
}
