import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DisputeManagementScreen extends StatefulWidget {
  const DisputeManagementScreen({super.key});

  @override
  State<DisputeManagementScreen> createState() => _DisputeManagementScreenState();
}

class _DisputeManagementScreenState extends State<DisputeManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Complaints & Disputes', 
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
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              indicatorColor: isDark ? AppColors.neonGreen : AppColors.primary,
              labelColor: isDark ? AppColors.neonGreen : AppColors.primary,
              unselectedLabelColor: isDark ? AppColors.darkGrey : AppColors.grey,
              tabs: const [
                Tab(text: 'Pending'),
                Tab(text: 'Resolved'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _DisputeList(status: 'pending', isDark: isDark),
                  _DisputeList(status: 'resolved', isDark: isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DisputeList extends StatelessWidget {
  final String status;
  final bool isDark;

  const _DisputeList({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('disputes')
          .stream(primaryKey: ['id'])
          .eq('status', status)
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final disputes = snapshot.data ?? [];
        
        if (disputes.isEmpty) {
          return Center(
            child: Text(
              'No ${status == 'pending' ? 'pending' : 'resolved'} disputes found.',
              style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 13),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          itemCount: disputes.length,
          itemBuilder: (context, index) {
            final dispute = disputes[index];
            return _DisputeCard(
              disputeId: dispute['id'],
              title: dispute['title'] ?? 'Payment Issue',
              description: dispute['description'] ?? 'No description provided.',
              status: dispute['status'],
              customerId: dispute['customer_id'],
              mechanicId: dispute['mechanic_id'],
              isDark: isDark,
            );
          },
        );
      },
    );
  }
}

class _DisputeCard extends StatefulWidget {
  final String disputeId, title, description, status;
  final String? customerId, mechanicId;
  final bool isDark;

  const _DisputeCard({
    required this.disputeId,
    required this.title,
    required this.description,
    required this.status,
    this.customerId,
    this.mechanicId,
    required this.isDark,
  });

  @override
  State<_DisputeCard> createState() => _DisputeCardState();
}

class _DisputeCardState extends State<_DisputeCard> {
  String _customerName = 'Loading...';
  String _mechanicName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    final supabase = Supabase.instance.client;
    try {
      if (widget.customerId != null) {
        final cust = await supabase.from('profiles').select('full_name').eq('id', widget.customerId!).single();
        if (mounted) setState(() => _customerName = cust['full_name'] ?? 'Unknown');
      }
      if (widget.mechanicId != null) {
        final mech = await supabase.from('profiles').select('full_name').eq('id', widget.mechanicId!).single();
        if (mounted) setState(() => _mechanicName = mech['full_name'] ?? 'Unknown');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _customerName = 'Error';
          _mechanicName = 'Error';
        });
      }
    }
  }

  Future<void> _resolveDispute() async {
    final supabase = Supabase.instance.client;
    try {
      await supabase.from('disputes').update({'status': 'resolved'}).eq('id', widget.disputeId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispute marked as resolved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to resolve dispute.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: widget.isDark ? Colors.white10 : AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.title,
                  style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '#ID-${widget.disputeId.substring(0, 5).toUpperCase()}',
                style: TextStyle(color: widget.isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.description,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: widget.isDark ? Colors.white : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const CircleAvatar(radius: 12, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=cust')),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$_customerName (Cust)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: widget.isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 11),
                ),
              ),
              const SizedBox(width: 8),
              const CircleAvatar(radius: 12, backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=mech')),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$_mechanicName (Mech)',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: widget.isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (widget.status == 'pending')
                Expanded(
                  child: ElevatedButton(
                    onPressed: _resolveDispute,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isDark ? AppColors.neonGreen : AppColors.primary,
                      minimumSize: const Size(0, 40),
                    ),
                    child: Text(
                      'Resolve',
                      style: TextStyle(color: widget.isDark ? Colors.black : Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              if (widget.status == 'pending') const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 40),
                  ),
                  child: const Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
