import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _supabase.auth.currentUser;

    if (user == null) return const Scaffold(body: Center(child: Text('Login required')));

    final Stream<List<Map<String, dynamic>>> transactionsStream = _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('profile_id', user.id)
        .order('created_at', ascending: false);

    final Stream<List<Map<String, dynamic>>> walletStream = _supabase
        .from('wallets')
        .stream(primaryKey: ['id'])
        .eq('profile_id', user.id);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('Digital Wallet', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : Colors.black)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: walletStream,
            builder: (context, snapshot) {
              final balance = snapshot.data?.isNotEmpty == true ? (snapshot.data!.first['balance'] as num).toDouble() : 0.0;
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: isDark ? AppColors.darkGradient : AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    children: [
                      const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('PKR ${NumberFormat("#,###").format(balance)}', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildAction(Icons.add_rounded, 'Add Cash', () => _showTopUpDialog(context, user.id)),
                          _buildAction(Icons.account_balance_wallet_rounded, 'Withdraw', () {}),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Recent History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: transactionsStream,
                      builder: (context, snapshot) {
                        final txs = snapshot.data ?? [];
                        if (txs.isEmpty) return const Center(child: Text('No activity yet'));
                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: txs.length,
                          itemBuilder: (context, index) {
                            final tx = txs[index];
                            final isPlus = tx['type'] == 'topup' || tx['type'] == 'refund';
                            return _TransactionTile(tx: tx, isPlus: isPlus, isDark: isDark);
                          },
                        );
                      }
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: Icon(icon, color: Colors.white, size: 24)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showTopUpDialog(BuildContext context, String userId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Cash'),
        content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Amount in PKR')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                await _supabase.from('transactions').insert({'profile_id': userId, 'amount': amount, 'type': 'topup'});
                // In real app, trigger a DB function to update wallet balance
                await _supabase.rpc('handle_wallet_topup', params: {'user_id': userId, 'topup_amount': amount});
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> tx;
  final bool isPlus, isDark;
  const _TransactionTile({required this.tx, required this.isPlus, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AppColors.darkSurface : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white10 : AppColors.divider)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(tx['type'].toString().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(DateFormat('dd MMM').format(DateTime.parse(tx['created_at'])), style: TextStyle(fontSize: 10, color: isDark ? AppColors.darkGrey : AppColors.grey)),
          ]),
          Text('${isPlus ? "+" : "-"} PKR ${tx['amount']}', style: TextStyle(fontWeight: FontWeight.w900, color: isPlus ? Colors.green : Colors.red)),
        ],
      ),
    );
  }
}
