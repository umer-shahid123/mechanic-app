import 'package:flutter/material.dart';
import 'package:mechanic_app/screens/service_completed_screen.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  final double amount;
  const PaymentScreen({super.key, required this.bookingId, required this.amount});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _supabase = Supabase.instance.client;
  String _selectedMethod = 'Wallet';
  double _walletBalance = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    final data = await _supabase.from('wallets').select('balance').eq('profile_id', user.id).maybeSingle();
    if (data != null && mounted) {
      setState(() => _walletBalance = (data['balance'] as num).toDouble());
    }
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == 'Wallet' && _walletBalance < widget.amount) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient wallet balance'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      if (_selectedMethod == 'Wallet') {
        // Deduct from wallet
        await _supabase.rpc('handle_wallet_topup', params: {
          'user_id': user.id,
          'topup_amount': -widget.amount,
        });
        
        // Record transaction
        await _supabase.from('transactions').insert({
          'profile_id': user.id,
          'booking_id': widget.bookingId,
          'amount': widget.amount,
          'type': 'withdrawal',
        });
      }

      // Update booking status
      await _supabase.from('bookings').update({'status': 'completed'}).eq('id', widget.bookingId);

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ServiceCompletedScreen()));
      }
    } catch (e) {
      debugPrint('Payment Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        elevation: 0,
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
                  const SizedBox(height: 20),
                  _buildMethodCard('Wallet', Icons.account_balance_wallet_rounded, 'Balance: PKR ${NumberFormat("#,###").format(_walletBalance)}', isDark),
                  _buildMethodCard('Cash', Icons.money_rounded, 'Pay after service', isDark),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: isDark ? AppColors.darkSurface : Colors.white, border: Border(top: BorderSide(color: isDark ? Colors.white10 : AppColors.divider))),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Total Payable', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('PKR ${NumberFormat("#,###").format(widget.amount)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? AppColors.neonGreen : AppColors.primary)),
                  ]),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _processPayment,
                    style: ElevatedButton.styleFrom(backgroundColor: isDark ? AppColors.neonGreen : AppColors.primary, minimumSize: const Size(double.infinity, 56)),
                    child: _isLoading ? const CircularProgressIndicator() : const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(String title, IconData icon, String subtitle, bool isDark) {
    bool isSelected = _selectedMethod == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? (isDark ? AppColors.neonGreen : AppColors.primary) : (isDark ? Colors.white10 : AppColors.divider), width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? (isDark ? AppColors.neonGreen : AppColors.primary) : Colors.grey),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ])),
            if (isSelected) Icon(Icons.check_circle_rounded, color: isDark ? AppColors.neonGreen : AppColors.primary),
          ],
        ),
      ),
    );
  }
}
