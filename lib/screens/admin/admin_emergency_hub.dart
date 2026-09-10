import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminEmergencyHub extends StatefulWidget {
  const AdminEmergencyHub({super.key});

  @override
  State<AdminEmergencyHub> createState() => _AdminEmergencyHubState();
}

class _AdminEmergencyHubState extends State<AdminEmergencyHub> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: Text(
          '🚨 Emergency Hub', 
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
        stream: _supabase.from('emergency_sos').stream(primaryKey: ['id']).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final emergencies = snapshot.data ?? [];

          if (emergencies.isEmpty) {
            return Center(child: Text('No emergency requests.', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: emergencies.length,
            itemBuilder: (context, index) {
              final em = emergencies[index];
              return _EmergencyCard(em: em, isDark: isDark);
            },
          );
        },
      ),
    );
  }
}

class _EmergencyCard extends StatefulWidget {
  final Map<String, dynamic> em;
  final bool isDark;
  const _EmergencyCard({required this.em, required this.isDark});

  @override
  State<_EmergencyCard> createState() => _EmergencyCardState();
}

class _EmergencyCardState extends State<_EmergencyCard> {
  String _customerName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final res = await Supabase.instance.client.from('profiles').select('full_name').eq('id', widget.em['customer_id']).single();
      if (mounted) setState(() => _customerName = res['full_name'] ?? 'Unknown');
    } catch (e) {
      if (mounted) setState(() => _customerName = 'Error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.em['status'] ?? 'searching';
    Color statusColor = status == 'searching' ? Colors.orange : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.sosRed.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Emergency #ID-${widget.em['id'].toString().substring(0, 5).toUpperCase()}', 
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.sosRed),
              ),
              _statusBadge(status.toUpperCase(), statusColor),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(Icons.person_rounded, 'Customer', _customerName, widget.isDark),
          _infoRow(Icons.location_on_rounded, 'Location', widget.em['location_lat'] != null ? 'View on Map' : 'Unknown', widget.isDark),
          _infoRow(Icons.report_problem_rounded, 'Problem', 'Urgent Assistance Required', widget.isDark),
          _infoRow(Icons.engineering_rounded, 'Mechanic', status == 'searching' ? 'Searching for nearby...' : 'Assigned', widget.isDark),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showAssignDialog(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.sosRed),
                  child: const Text('Direct Assign', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _markAsResolved(widget.em['id']),
                  child: const Text('Resolve SOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Mechanic'),
        content: const Text('Searching for the closest available verified mechanic...'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await Supabase.instance.client.from('emergency_sos').update({'status': 'assigned'}).eq('id', widget.em['id']);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Assign Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsResolved(String id) async {
    await Supabase.instance.client.from('emergency_sos').update({'status': 'resolved'}).eq('id', id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('SOS case resolved.')));
    }
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: isDark ? AppColors.darkGrey : AppColors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 12)),
          Text(value, style: TextStyle(color: isDark ? Colors.white : AppColors.textDark, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
