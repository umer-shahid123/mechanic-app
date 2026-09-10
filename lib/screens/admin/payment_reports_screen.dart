import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PaymentReportsScreen extends StatefulWidget {
  const PaymentReportsScreen({super.key});

  @override
  State<PaymentReportsScreen> createState() => _PaymentReportsScreenState();
}

class _PaymentReportsScreenState extends State<PaymentReportsScreen> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Stream<List<Map<String, dynamic>>> transactionsStream = _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

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
          'Financial Oversight', 
          style: TextStyle(
            fontWeight: FontWeight.w800, 
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: transactionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data ?? [];
          double totalRevenue = 0;
          for (var tx in transactions) {
            if (tx['type'] == 'payout') {
              totalRevenue += (tx['amount'] as num).toDouble();
            }
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: isDark ? AppColors.darkGradient : AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Total Processed Revenue', 
                        style: TextStyle(
                          color: isDark ? Colors.black54 : Colors.white70, 
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'PKR ${NumberFormat("#,###").format(totalRevenue)}', 
                        style: TextStyle(
                          color: isDark ? Colors.black : Colors.white, 
                          fontSize: 32, 
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Global Transaction Log', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16, 
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    Icon(Icons.filter_list_rounded, color: isDark ? AppColors.neonGreen : AppColors.primary, size: 20),
                  ],
                ),
                const SizedBox(height: 16),
                transactions.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.only(top: 40), child: Text('No platform transactions found', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey))))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        final DateTime date = DateTime.parse(tx['created_at']);
                        final bool isPayout = tx['type'] == 'payout';

                        return _PaymentTile(
                          id: tx['id'].toString().substring(0, 8).toUpperCase(),
                          amount: 'PKR ${NumberFormat("#,###").format(tx['amount'])}',
                          date: DateFormat('dd MMM yyyy').format(date),
                          type: tx['type']?.toString().toUpperCase() ?? 'UNKNOWN',
                          isPayout: isPayout,
                          isDark: isDark,
                        );
                      },
                    ),
                const SizedBox(height: 40),
              ],
            ),
          );
        }
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final String id, amount, date, type;
  final bool isPayout, isDark;

  const _PaymentTile({required this.id, required this.amount, required this.date, required this.type, required this.isPayout, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isPayout ? Colors.green : Colors.orange).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPayout ? Icons.add_rounded : Icons.remove_rounded, 
                  color: isPayout ? Colors.green : Colors.orange, 
                  size: 18
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TXN-$id', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 13,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  Text(
                    date, 
                    style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount, 
                style: TextStyle(
                  fontWeight: FontWeight.w900, 
                  color: isPayout ? (isDark ? AppColors.neonGreen : Colors.green) : Colors.orange, 
                  fontSize: 14,
                ),
              ),
              Text(
                type, 
                style: TextStyle(
                  color: isDark ? AppColors.darkGrey : AppColors.grey, 
                  fontSize: 10, 
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
