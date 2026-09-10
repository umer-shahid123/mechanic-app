import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Stream<List<Map<String, dynamic>>>? _vehicleStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      _vehicleStream = _supabase
          .from('vehicles')
          .stream(primaryKey: ['id'])
          .eq('owner_id', user.id)
          .order('created_at', ascending: false);
    }
  }

  Future<void> _openAddVehicle({Map<String, dynamic>? vehicle}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddVehicleScreen(vehicle: vehicle),
      ),
    );
  }

  Future<void> _deleteVehicle(String vehicleId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase
          .from('vehicles')
          .delete()
          .eq('id', vehicleId)
          .eq('owner_id', user.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle removed successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showDeleteDialog(String vehicleId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: const Text('Are you sure you want to remove this vehicle from your profile?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteVehicle(vehicleId);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: const Text('My Vehicles', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddVehicle(),
        backgroundColor: isDark ? AppColors.neonGreen : AppColors.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: _vehicleStream == null
          ? _buildMessage('Please sign in to view vehicles', Icons.lock_outline, isDark)
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _vehicleStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildMessage('Unable to load vehicles', Icons.cloud_off_rounded, isDark);
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildSkeletonList(isDark);
                }

                final vehicles = snapshot.data ?? [];

                if (vehicles.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  physics: const BouncingScrollPhysics(),
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) => _buildVehicleCard(vehicles[index], isDark),
                );
              },
            ),
    );
  }

  Widget _buildMessage(String text, IconData icon, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 60, color: Colors.red.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(text, style: TextStyle(color: isDark ? Colors.white70 : AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSkeletonList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) => Container(
        height: 100,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
        ),
        child: const Opacity(opacity: 0.3),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car_outlined, size: 80, color: isDark ? AppColors.darkGrey : AppColors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 24),
          Text('No vehicles added yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
          const SizedBox(height: 10),
          Text('Add your car details for faster booking.', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey)),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => _openAddVehicle(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add My First Vehicle'),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> vehicle, bool isDark) {
    final String make = vehicle['make']?.toString() ?? 'Unknown';
    final String model = vehicle['model']?.toString() ?? '';
    final String plate = vehicle['plate_number']?.toString() ?? '';
    final String year = vehicle['year']?.toString() ?? '';
    final String mileage = vehicle['mileage']?.toString() ?? '0';
    final String id = vehicle['id']?.toString() ?? '';

    return GestureDetector(
      onTap: () => _openAddVehicle(vehicle: vehicle),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
          boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: (isDark ? AppColors.neonGreen : AppColors.primary).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(Icons.directions_car_rounded, size: 30, color: isDark ? AppColors.neonGreen : AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$make $model', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(plate, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.neonGreen.withValues(alpha: 0.7) : AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(
                    '${year.isNotEmpty ? "$year • " : ""}$mileage km',
                    style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkGrey : AppColors.grey),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: isDark ? AppColors.darkGrey : AppColors.grey),
              onSelected: (value) {
                if (value == 'delete') _showDeleteDialog(id);
                if (value == 'edit') _openAddVehicle(vehicle: vehicle);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Remove', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AddVehicleScreen extends StatefulWidget {
  final Map<String, dynamic>? vehicle;
  const AddVehicleScreen({super.key, this.vehicle});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _plateController;
  late TextEditingController _yearController;
  late TextEditingController _mileageController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _makeController = TextEditingController(text: widget.vehicle?['make']?.toString() ?? '');
    _modelController = TextEditingController(text: widget.vehicle?['model']?.toString() ?? '');
    _plateController = TextEditingController(text: widget.vehicle?['plate_number']?.toString() ?? '');
    _yearController = TextEditingController(text: widget.vehicle?['year']?.toString() ?? '');
    _mileageController = TextEditingController(text: widget.vehicle?['mileage']?.toString() ?? '');
  }

  Future<void> _saveVehicle() async {
    final make = _makeController.text.trim();
    final model = _modelController.text.trim();
    final plate = _plateController.text.trim();
    final year = _yearController.text.trim();
    final mileage = int.tryParse(_mileageController.text.trim()) ?? 0;

    if (make.isEmpty || model.isEmpty || plate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in required fields (Make, Model, Plate)')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Session expired. Please login again.');

      final data = {
        'owner_id': user.id,
        'make': make,
        'model': model,
        'plate_number': plate,
        'year': year,
        'mileage': mileage,
      };

      if (widget.vehicle != null) {
        // Update existing vehicle
        await _supabase.from('vehicles').update(data).eq('id', widget.vehicle!['id']);
      } else {
        // Insert new vehicle
        await _supabase.from('vehicles').insert(data);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving vehicle: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: Text(widget.vehicle != null ? 'Edit Vehicle' : 'Add Vehicle Details', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildField('Vehicle Make (e.g. Honda)', _makeController, isDark, Icons.directions_car_outlined),
            const SizedBox(height: 16),
            _buildField('Model (e.g. Civic)', _modelController, isDark, Icons.model_training_rounded),
            const SizedBox(height: 16),
            _buildField('Plate Number', _plateController, isDark, Icons.pin_rounded),
            const SizedBox(height: 16),
            _buildField('Year (Optional)', _yearController, isDark, Icons.calendar_today_rounded, keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            _buildField('Mileage (Optional)', _mileageController, isDark, Icons.speed_rounded, keyboardType: TextInputType.number),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveVehicle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.neonGreen : AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) 
                    : Text(widget.vehicle != null ? 'Update Vehicle' : 'Save and Continue', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String hint, TextEditingController controller, bool isDark, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: isDark ? AppColors.neonGreen : AppColors.primary),
        filled: true,
        fillColor: isDark ? AppColors.darkSurface : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.divider)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isDark ? AppColors.neonGreen : AppColors.primary, width: 1.5)),
      ),
    );
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _plateController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    super.dispose();
  }
}
