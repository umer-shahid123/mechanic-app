import 'package:flutter/material.dart';
import 'package:mechanic_app/screens/live_tracking_screen.dart';
import 'package:mechanic_app/screens/service_details_summary.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final _supabase = Supabase.instance.client;
  late final Stream<List<Map<String, dynamic>>> _upcomingStream;
  late final Stream<List<Map<String, dynamic>>> _completedStream;

  @override
  void initState() {
    super.initState();
    final user = _supabase.auth.currentUser;
    _upcomingStream = _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('customer_id', user?.id ?? '')
        .inFilter('status', ['pending', 'accepted', 'on_the_way', 'in_progress'])
        .order('created_at', ascending: false);

    _completedStream = _supabase
        .from('bookings')
        .stream(primaryKey: ['id'])
        .eq('customer_id', user?.id ?? '')
        .eq('status', 'completed')
        .order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.darkBg : Colors.white,
          elevation: 0,
          title: Text(
            'Bookings', 
            style: TextStyle(
              fontWeight: FontWeight.w800, 
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
            ],
            indicatorColor: isDark ? AppColors.neonGreen : AppColors.primary,
            labelColor: isDark ? AppColors.neonGreen : AppColors.primary,
            unselectedLabelColor: isDark ? AppColors.darkGrey : AppColors.grey,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          automaticallyImplyLeading: false,
        ),
        body: TabBarView(
          children: [
            _buildDynamicList(_upcomingStream, isDark, true),
            _buildDynamicList(_completedStream, isDark, false),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicList(Stream<List<Map<String, dynamic>>> stream, bool isDark, bool isUpcoming) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final bookings = snapshot.data ?? [];
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today_rounded, size: 64, color: isDark ? Colors.white10 : Colors.black12),
                const SizedBox(height: 16),
                Text(
                  isUpcoming ? 'No active bookings' : 'No history yet', 
                  style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _BookingListItem(
              title: booking['service_type'] ?? 'Repair',
              status: booking['status']?.toUpperCase() ?? 'PENDING',
              price: 'PKR ${booking['total_price'] ?? '0'}',
              date: 'Today',
              isDark: isDark,
              onTap: () {
                if (isUpcoming) {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => LiveTrackingScreen(
                    bookingId: booking['id'],
                    mechanicId: booking['mechanic_id'] ?? '',
                    mechanicName: 'Assigned Expert',
                  )));
                } else {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ServiceDetailsSummary()));
                }
              },
            );
          },
        );
      },
    );
  }
}

class _BookingListItem extends StatelessWidget {
  final String title, status, price, date;
  final bool isDark;
  final VoidCallback onTap;

  const _BookingListItem({required this.title, required this.status, required this.price, required this.date, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color statusColor = status == 'COMPLETED' ? Colors.green : Colors.orange;
    if (status == 'CANCELLED') statusColor = Colors.red;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : AppColors.textDark)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Text(date, style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
            Text(price, style: TextStyle(fontWeight: FontWeight.w900, color: isDark ? AppColors.neonGreen : AppColors.secondary, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
