import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlatformBroadcastScreen extends StatefulWidget {
  const PlatformBroadcastScreen({super.key});

  @override
  State<PlatformBroadcastScreen> createState() => _PlatformBroadcastScreenState();
}

class _PlatformBroadcastScreenState extends State<PlatformBroadcastScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _targetRole = 'all';
  bool _isSending = false;

  Future<void> _sendBroadcast() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final supabase = Supabase.instance.client;
      
      // Fetch target users
      var query = supabase.from('profiles').select('id');
      if (_targetRole != 'all') {
        query = query.eq('role', _targetRole);
      }
      
      final users = await query;
      
      // Batch insert notifications
      final notifications = users.map((u) => {
        'user_id': u['id'],
        'title': title,
        'body': body,
        'type': 'broadcast',
        'is_read': false,
      }).toList();

      if (notifications.isNotEmpty) {
        await supabase.from('notifications').insert(notifications);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Broadcast sent to ${notifications.length} users!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: const Text('Platform Broadcast', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Target Audience', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.blueGrey)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildRoleChip('all', 'Everyone', isDark),
                const SizedBox(width: 8),
                _buildRoleChip('customer', 'Customers', isDark),
                const SizedBox(width: 8),
                _buildRoleChip('mechanic', 'Mechanics', isDark),
              ],
            ),
            const SizedBox(height: 32),
            Text('Message Details', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.blueGrey)),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Notification Title (e.g. Weekend Promo)',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Detailed message content...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 80),
                  child: Icon(Icons.message_rounded),
                ),
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _isSending ? null : _sendBroadcast,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.neonGreen : AppColors.primary,
                minimumSize: const Size(double.infinity, 56),
              ),
              child: _isSending 
                ? const CircularProgressIndicator(color: Colors.black)
                : Text('Send Global Alert 📢', style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.black : Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(String role, String label, bool isDark) {
    bool isSelected = _targetRole == role;
    return GestureDetector(
      onTap: () => setState(() => _targetRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
            ? (isDark ? AppColors.neonGreen : AppColors.primary)
            : (isDark ? AppColors.darkSurface : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.transparent : (isDark ? Colors.white10 : AppColors.divider)),
        ),
        child: Text(
          label, 
          style: TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.bold, 
            color: isSelected ? (isDark ? Colors.black : Colors.white) : (isDark ? Colors.white70 : Colors.grey),
          ),
        ),
      ),
    );
  }
}
