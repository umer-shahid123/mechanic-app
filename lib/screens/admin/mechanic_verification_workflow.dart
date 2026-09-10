import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:mechanic_app/widgets/full_screen_image_viewer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MechanicVerificationWorkflow extends StatefulWidget {
  const MechanicVerificationWorkflow({super.key});

  @override
  State<MechanicVerificationWorkflow> createState() => _MechanicVerificationWorkflowState();
}

class _MechanicVerificationWorkflowState extends State<MechanicVerificationWorkflow> {
  final _supabase = Supabase.instance.client;

  Future<void> _updateStatus(String id, String status) async {
    try {
      await _supabase.from('profiles').update({'verification_status': status}).eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mechanic $status successfully.')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error updating status.'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Mechanic Approvals', 
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
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _supabase.from('profiles').stream(primaryKey: ['id']).eq('role', 'mechanic').eq('verification_status', 'unverified'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final mechanics = snapshot.data ?? [];

          if (mechanics.isEmpty) {
            return Center(child: Text('No pending approvals.', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: mechanics.length,
            itemBuilder: (context, index) {
              final mech = mechanics[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24, 
                          backgroundImage: NetworkImage(mech['avatar_url'] ?? 'https://i.pravatar.cc/150?u=${mech['id']}'),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(mech['full_name'] ?? 'Unnamed Mechanic', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppColors.textDark)),
                              Text('Specialist: ${mech['specialization'] ?? 'General Repair'}', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        _statusBadge('Pending', Colors.orange),
                      ],
                    ),
                    const Divider(height: 32),
                    Text('Uploaded Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : AppColors.textDark)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _docThumbnail(context, 'CNIC Front', mech['cnic_front_url'], isDark),
                        const SizedBox(width: 8),
                        _docThumbnail(context, 'License', mech['license_url'], isDark),
                        const SizedBox(width: 8),
                        _docThumbnail(context, 'Workshop', mech['workshop_url'], isDark),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateStatus(mech['id'], 'verified'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2ECC71)),
                            child: const Text('Approve ✅', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _updateStatus(mech['id'], 'rejected'),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Reject ❌', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
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

  Widget _docThumbnail(BuildContext context, String label, String? url, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: url != null ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => FullScreenImageViewer(imageUrl: url, tag: url))) : null,
        child: Column(
          children: [
            Hero(
              tag: url ?? label,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
                  image: url != null ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
                ),
                child: url == null ? const Center(child: Icon(Icons.image_rounded, color: Colors.grey, size: 20)) : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
