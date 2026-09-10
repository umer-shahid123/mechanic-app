import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:mechanic_app/screens/offers_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IndriveRequestScreen extends StatefulWidget {
  final String vehicleId;
  final String vehicleName;
  final String serviceType;
  final String? problemDescription;

  const IndriveRequestScreen({
    super.key, 
    required this.vehicleId, 
    required this.vehicleName, 
    required this.serviceType,
    this.problemDescription,
  });

  @override
  State<IndriveRequestScreen> createState() => _IndriveRequestScreenState();
}

class _IndriveRequestScreenState extends State<IndriveRequestScreen> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _priceController = TextEditingController(text: "1500");
  late final TextEditingController _descController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController(text: widget.problemDescription ?? "");
  }

  @override
  void dispose() {
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _createBooking() async {
    final description = _descController.text.trim();
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the issue briefly.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('bookings').insert({
          'customer_id': user.id,
          'vehicle_id': widget.vehicleId,
          'service_type': widget.serviceType,
          'problem_description': description,
          'total_price': double.tryParse(_priceController.text) ?? 1500,
          'customer_location_name': 'Johar Town, Lahore', // Demo location
          'status': 'pending',
        });

        if (mounted) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const OffersScreen()));
        }
      }
    } catch (e) {
      debugPrint('Error creating booking: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to request mechanic: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Set Offer', 
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
                    ),
                    child: Column(
                      children: [
                        _LocationRow(icon: Icons.circle, color: Colors.green, label: 'Current', value: 'Johar Town, Lahore', isDark: isDark),
                        Padding(
                          padding: const EdgeInsets.only(left: 9),
                          child: SizedBox(height: 12, child: VerticalDivider(thickness: 1.5, width: 2, color: isDark ? Colors.white10 : AppColors.divider)),
                        ),
                        _LocationRow(icon: Icons.location_on, color: Colors.red, label: 'Point', value: 'Service Location Set', isDark: isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    'Describe the problem', 
                    style: TextStyle(
                      fontWeight: FontWeight.w700, 
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descController,
                    maxLines: 2,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'e.g., Engine is making noise...',
                      hintStyle: TextStyle(color: isDark ? AppColors.darkGrey : Colors.grey, fontSize: 13),
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white10 : AppColors.divider),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 28),
                  Text(
                    'What\'s your offer? (PKR)', 
                    style: TextStyle(
                      fontWeight: FontWeight.w700, 
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: isDark ? AppColors.neonGreen : AppColors.primary, width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: () {
                            int val = int.tryParse(_priceController.text) ?? 1500;
                            if(val > 500) setState(() => _priceController.text = (val - 100).toString());
                          },
                          icon: Icon(Icons.remove_circle_outline_rounded, size: 26, color: isDark ? Colors.white : AppColors.secondary),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _priceController,
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              fontSize: 26, 
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: const InputDecoration(border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            int val = int.tryParse(_priceController.text) ?? 1500;
                            setState(() => _priceController.text = (val + 100).toString());
                          },
                          icon: Icon(Icons.add_circle_outline_rounded, size: 26, color: isDark ? Colors.white : AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Average price PKR 1,400', 
                      style: TextStyle(color: isDark ? AppColors.darkGrey : Colors.grey, fontSize: 11),
                    ),
                  ),
                  
                  const SizedBox(height: 28),
                  Text(
                    'Summary', 
                    style: TextStyle(
                      fontWeight: FontWeight.w700, 
                      fontSize: 14,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ServiceTile(icon: Icons.directions_car_rounded, text: widget.vehicleName, isDark: isDark),
                  _ServiceTile(icon: Icons.engineering_rounded, text: widget.serviceType, isDark: isDark),
                ],
              ),
            ),
          ),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              border: Border(top: BorderSide(color: isDark ? Colors.white10 : AppColors.divider)),
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.neonGreen : AppColors.primary,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : Text(
                    'Find Mechanic', 
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                  ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool isDark;

  const _LocationRow({required this.icon, required this.color, required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
            Text(value, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isDark ? Colors.white : AppColors.textDark)),
          ],
        ),
      ],
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const _ServiceTile({required this.icon, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? AppColors.neonGreen : AppColors.secondary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : AppColors.textDark))),
        ],
      ),
    );
  }
}
