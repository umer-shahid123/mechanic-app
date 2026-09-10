import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:mechanic_app/widgets/app_avatar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MechanicManagementScreen extends StatefulWidget {
  const MechanicManagementScreen({super.key});

  @override
  State<MechanicManagementScreen> createState() => _MechanicManagementScreenState();
}

class _MechanicManagementScreenState extends State<MechanicManagementScreen> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Stream<List<Map<String, dynamic>>> mechanicsStream = _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('role', 'mechanic')
        .order('full_name');

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mechanic Management', 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: mechanicsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final mechanics = snapshot.data ?? [];

          if (mechanics.isEmpty) {
            return Center(child: Text('No mechanics found', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey)));
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.all(20),
            itemCount: mechanics.length,
            itemBuilder: (context, index) {
              final mech = mechanics[index];
              return _MechanicCard(
                mechId: mech['id'],
                name: mech['full_name'] ?? 'No Name',
                specialty: mech['shop_name'] ?? 'General Mechanic',
                isVerified: mech['is_verified'] ?? false,
                isOnline: mech['is_online'] ?? false,
                img: mech['avatar_url'],
                onToggle: () => _toggleVerification(mech['id'], mech['is_verified'] ?? false),
                onDelete: () => _deleteMechanic(mech['id']),
                isDark: isDark,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _toggleVerification(String mechId, bool currentVerified) async {
    try {
      await _supabase.from('profiles').update({'is_verified': !currentVerified}).eq('id', mechId);
    } catch (e) {
      debugPrint('Error toggling verification: $e');
    }
  }

  Future<void> _deleteMechanic(String mechId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Mechanic?'),
        content: const Text('This will remove the mechanic from the platform. This action is permanent.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Remove', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase.from('profiles').delete().eq('id', mechId);
      } catch (e) {
        debugPrint('Error deleting mechanic: $e');
      }
    }
  }
}

class _MechanicCard extends StatelessWidget {
  final String mechId, name, specialty;
  final String? img;
  final bool isVerified, isOnline, isDark;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _MechanicCard({required this.mechId, required this.name, required this.specialty, required this.isVerified, required this.isOnline, required this.img, required this.onToggle, required this.onDelete, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
        boxShadow: isDark ? [] : AppColors.softShadow,
      ),
      child: Row(
        children: [
          Stack(
            children: [
              AppAvatar(
                url: img,
                fallbackId: mechId,
                radius: 24,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? AppColors.darkSurface : Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name, 
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 15,
                          color: isDark ? Colors.white : AppColors.textDark,
                        ),
                      ),
                    ),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, color: Colors.blue, size: 14),
                    ],
                  ],
                ),
                Text(
                  specialty, 
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: onToggle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isVerified 
                    ? Colors.red.withValues(alpha: 0.1) 
                    : (isDark ? AppColors.neonGreen : AppColors.primary),
                  foregroundColor: isVerified ? Colors.red : (isDark ? Colors.black : Colors.white),
                  minimumSize: const Size(70, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Text(
                  isVerified ? 'Suspend' : 'Approve', 
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onDelete,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
