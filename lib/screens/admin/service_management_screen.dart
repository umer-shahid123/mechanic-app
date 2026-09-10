import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ServiceManagementScreen extends StatefulWidget {
  const ServiceManagementScreen({super.key});

  @override
  State<ServiceManagementScreen> createState() => _ServiceManagementScreenState();
}

class _ServiceManagementScreenState extends State<ServiceManagementScreen> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Stream<List<Map<String, dynamic>>> servicesStream = _supabase
        .from('services')
        .stream(primaryKey: ['id'])
        .order('name');

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Manage Services', 
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
            onPressed: () => _showAddServiceDialog(context, isDark),
            icon: Icon(Icons.add_box_rounded, color: isDark ? AppColors.neonGreen : AppColors.primary),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: servicesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final services = snapshot.data ?? [];

          if (services.isEmpty) {
            return Center(child: Text('No services found', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              final bool isActive = service['is_active'] ?? true;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.neonGreen : AppColors.primary).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getIconForService(service['icon_name']), color: isDark ? AppColors.neonGreen : AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service['name'] ?? 'Unknown Service',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : AppColors.textDark,
                            ),
                          ),
                          Text(
                            'Base Price: PKR ${service['base_price'] ?? '0'}',
                            style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Switch.adaptive(
                          value: isActive, 
                          onChanged: (v) => _toggleServiceActive(service['id'], v),
                          activeThumbColor: isDark ? AppColors.neonGreen : AppColors.primary,
                activeTrackColor: (isDark ? AppColors.neonGreen : AppColors.primary).withValues(alpha: 0.5),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                          onPressed: () => _deleteService(service['id']),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
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

  Future<void> _toggleServiceActive(String id, bool active) async {
    try {
      await _supabase.from('services').update({'is_active': active}).eq('id', id);
    } catch (e) {
      debugPrint('Error toggling service: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deleteService(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service?'),
        content: const Text('This will remove the service from all users.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase.from('services').delete().eq('id', id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service deleted successfully')));
        }
      } catch (e) {
        debugPrint('Error deleting service: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _showAddServiceDialog(BuildContext context, bool isDark) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String selectedIcon = 'settings';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Add New Service', style: TextStyle(color: isDark ? Colors.white : AppColors.textDark, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: const InputDecoration(hintText: 'Service Name (e.g. Filter Change)'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: const InputDecoration(hintText: 'Base Price (e.g. 1000)'),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Select Icon', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey)),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedIcon,
                      isExpanded: true,
                      dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      items: ['settings', 'engineering', 'battery', 'adjust', 'ac_unit', 'wash', 'opacity']
                          .map((e) => DropdownMenuItem(
                            value: e, 
                            child: Row(
                              children: [
                                Icon(_getIconForService(e), size: 18, color: isDark ? AppColors.neonGreen : AppColors.primary),
                                const SizedBox(width: 12),
                                Text(e),
                              ],
                            )
                          )).toList(),
                      onChanged: (v) => setModalState(() => selectedIcon = v!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (nameController.text.trim().isEmpty) return;
                setModalState(() => isSaving = true);
                try {
                  await _supabase.from('services').insert({
                    'name': nameController.text.trim(),
                    'base_price': double.tryParse(priceController.text) ?? 0,
                    'icon_name': selectedIcon,
                    'is_active': true,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Service added successfully!')));
                  }
                } catch (e) {
                  debugPrint('Error adding service: $e');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                  }
                } finally {
                  if (context.mounted) setModalState(() => isSaving = false);
                }
              },
              child: isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
