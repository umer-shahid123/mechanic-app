import 'package:flutter/material.dart';
import 'package:mechanic_app/screens/service_completed_screen.dart';
import 'package:mechanic_app/theme/app_theme.dart';

class JobCompletionScreen extends StatefulWidget {
  const JobCompletionScreen({super.key});

  @override
  State<JobCompletionScreen> createState() => _JobCompletionScreenState();
}

class _JobCompletionScreenState extends State<JobCompletionScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _pinVerified = false;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: Text('Finish Service', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: isDark ? Colors.white : Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_pinVerified) _buildPinEntry(isDark) else _buildItemizedInvoicing(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPinEntry(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Verify Completion PIN', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
        const SizedBox(height: 8),
        Text('Ask the customer for the 4-digit security PIN to unlock the invoice.', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 13)),
        const SizedBox(height: 48),
        Center(
          child: SizedBox(
            width: 200,
            child: TextField(
              controller: _pinController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 20),
              decoration: const InputDecoration(counterText: ""),
            ),
          ),
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: () {
            if (_pinController.text == "5824") {
              setState(() => _pinVerified = true);
            }
          },
          child: const Text('Verify PIN'),
        ),
      ],
    );
  }

  Widget _buildItemizedInvoicing(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Text('PIN Verified', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textDark)),
          ],
        ),
        const SizedBox(height: 32),
        Text('Service Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : AppColors.textDark)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
          ),
          child: Column(
            children: [
              _invoiceRow('Coolant Replacement', 'PKR 800', isDark),
              _invoiceRow('System Testing', 'PKR 500', isDark),
              _invoiceRow('Labor Charges', 'PKR 1,000', isDark),
              const Divider(height: 32),
              _invoiceRow('Total Amount', 'PKR 2,300', isDark, isTotal: true),
            ],
          ),
        ),
        const SizedBox(height: 48),
        ElevatedButton(
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ServiceCompletedScreen())),
          style: ElevatedButton.styleFrom(backgroundColor: isDark ? AppColors.neonGreen : AppColors.primary),
          child: Text('Generate Invoice & Complete', style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _invoiceRow(String label, String value, bool isDark, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isTotal ? 16 : 14, color: isDark ? Colors.white : AppColors.textDark)),
        ],
      ),
    );
  }
}
