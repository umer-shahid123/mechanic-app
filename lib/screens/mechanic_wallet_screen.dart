import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MechanicWalletScreen extends StatefulWidget {
  const MechanicWalletScreen({super.key});

  @override
  State<MechanicWalletScreen> createState() => _MechanicWalletScreenState();
}

class _MechanicWalletScreenState extends State<MechanicWalletScreen> {
  final _supabase = Supabase.instance.client;
  String _selectedMethod = 'Bank Transfer';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _supabase.auth.currentUser;

    final Stream<List<Map<String, dynamic>>> transactionsStream = _supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('profile_id', user?.id ?? '')
        .order('created_at', ascending: false);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Earnings & Wallet', 
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
        stream: transactionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final transactions = snapshot.data ?? [];
          double totalEarned = 0;
          double totalWithdrawn = 0;

          for (var tx in transactions) {
            final amount = (tx['amount'] as num).toDouble();
            if (tx['type'] == 'payout') {
              totalEarned += amount;
            } else if (tx['type'] == 'withdrawal') {
              totalWithdrawn += amount;
            }
          }

          double availableBalance = totalEarned - totalWithdrawn;
          double commission = totalEarned * 0.1; // Demo 10% commission logic

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
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: isDark ? AppColors.glowShadow : [],
                  ),
                  child: Column(
                    children: [
                      const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text('PKR ${NumberFormat("#,###").format(availableBalance)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _BalanceStat(label: 'Total Earned', value: '${(totalEarned / 1000).toStringAsFixed(1)}k', isDark: isDark),
                          Container(width: 1, height: 30, color: Colors.white24),
                          _BalanceStat(label: 'Commission', value: '${(commission / 1000).toStringAsFixed(1)}k', isDark: isDark),
                          Container(width: 1, height: 30, color: Colors.white24),
                          _BalanceStat(label: 'Withdrawn', value: '${(totalWithdrawn / 1000).toStringAsFixed(1)}k', isDark: isDark),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: availableBalance > 0 ? () => _showWithdrawDialog(context, isDark, availableBalance) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? AppColors.neonGreen : AppColors.primary,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          disabledBackgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                        ),
                        child: const Text('Withdraw Money', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Transactions', 
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 16, 
                        color: isDark ? Colors.white : AppColors.textDark,
                      ),
                    ),
                    Text('View all', style: TextStyle(color: isDark ? AppColors.neonGreen : AppColors.primary, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 16),
                transactions.isEmpty
                    ? Center(child: Padding(padding: const EdgeInsets.only(top: 40), child: Text('No transactions yet', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey))))
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final tx = transactions[index];
                          final bool isCredit = tx['type'] == 'payout';
                          final DateTime date = DateTime.parse(tx['created_at']);
                          
                          return _TransactionItem(
                            title: isCredit ? 'Job Payout' : 'Withdrawal',
                            date: DateFormat('dd MMM yyyy').format(date),
                            amount: '${isCredit ? "+" : "-"} PKR ${NumberFormat("#,###").format(tx['amount'])}',
                            isCredit: isCredit,
                            isDark: isDark,
                          );
                        },
                      ),
              ],
            ),
          );
        }
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, bool isDark, double balance) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Withdraw Funds',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark),
                ),
                const SizedBox(height: 8),
                Text('Select your preferred withdrawal method', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 13)),
                const SizedBox(height: 24),
                _MethodTile(
                  icon: Icons.account_balance_rounded, 
                  label: 'Bank Transfer', 
                  isDark: isDark, 
                  isSelected: _selectedMethod == 'Bank Transfer',
                  onTap: () => setModalState(() => _selectedMethod = 'Bank Transfer'),
                ),
                _MethodTile(
                  icon: Icons.phone_android_rounded, 
                  label: 'Easypaisa / JazzCash', 
                  isDark: isDark, 
                  isSelected: _selectedMethod == 'Easypaisa / JazzCash',
                  onTap: () => setModalState(() => _selectedMethod = 'Easypaisa / JazzCash'),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _isProcessing ? null : () => _confirmWithdrawal(context, balance),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
                  child: _isProcessing 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirm Withdrawal'),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }
      ),
    );
  }

  Future<void> _confirmWithdrawal(BuildContext context, double balance) async {
    setState(() => _isProcessing = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Create withdrawal transaction
        await _supabase.from('transactions').insert({
          'profile_id': user.id,
          'amount': balance, // For demo, we withdraw full balance
          'type': 'withdrawal',
        });

        if (!context.mounted) return;

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Withdrawal request submitted!')),
        );
      }
    } catch (e) {
      debugPrint('Withdrawal error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

class _BalanceStat extends StatelessWidget {
  final String label, value;
  final bool isDark;
  const _BalanceStat({required this.label, required this.value, required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final String title, date, amount;
  final bool isCredit, isDark;
  const _TransactionItem({required this.title, required this.date, required this.amount, required this.isCredit, required this.isDark});
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
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isCredit ? Colors.green : Colors.red).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(isCredit ? Icons.add_rounded : Icons.remove_rounded, color: isCredit ? Colors.green : Colors.red, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark, fontSize: 14)),
                Text(date, style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 11)),
              ],
            ),
          ),
          Text(
            amount, 
            style: TextStyle(
              fontWeight: FontWeight.w800, 
              color: isCredit ? (isDark ? AppColors.neonGreen : Colors.green) : Colors.red, 
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark, isSelected;
  final VoidCallback onTap;

  const _MethodTile({required this.icon, required this.label, required this.isDark, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? (isDark ? AppColors.neonGreen : AppColors.primary) : (isDark ? Colors.white10 : AppColors.divider), width: 2),
          color: isSelected ? (isDark ? AppColors.neonGreen.withValues(alpha: 0.05) : AppColors.primary.withValues(alpha: 0.05)) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? (isDark ? AppColors.neonGreen : AppColors.primary) : (isDark ? AppColors.darkGrey : AppColors.grey), size: 20),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textDark)),
            const Spacer(),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, 
              size: 20, 
              color: isSelected ? (isDark ? AppColors.neonGreen : AppColors.primary) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
