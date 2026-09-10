import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';

class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
          'Invoice', 
          style: TextStyle(
            fontWeight: FontWeight.bold, 
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: isDark ? Colors.white10 : Colors.transparent),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)],
          ),
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_rounded, 
                size: 60, 
                color: isDark ? AppColors.neonGreen : AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Invoice #M-12345', 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 18,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
              const Text('12 May 2024, 11:30 AM', style: TextStyle(color: AppColors.grey)),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32), 
                child: Divider(color: isDark ? Colors.white10 : AppColors.divider),
              ),
              _buildRow('Customer', 'Umer', isDark),
              const SizedBox(height: 16),
              _buildRow('Vehicle', 'Honda Civic', isDark),
              const SizedBox(height: 16),
              _buildRow('Service', 'Engine Repair', isDark),
              const SizedBox(height: 16),
              _buildRow('Mechanic', 'All Auto Expert', isDark),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32), 
                child: Divider(color: isDark ? Colors.white10 : AppColors.divider),
              ),
              _buildRow('Subtotal', 'PKR 1,500', isDark),
              const SizedBox(height: 16),
              _buildRow('Platform Fee', 'PKR 50', isDark),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24), 
                child: Divider(color: isDark ? Colors.white10 : AppColors.divider),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Amount', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 18,
                      color: isDark ? Colors.white : AppColors.textDark,
                    ),
                  ),
                  Text(
                    'PKR 1,550', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 24, 
                      color: isDark ? AppColors.neonGreen : AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 60),
              ElevatedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.download_rounded, color: isDark ? Colors.black : Colors.white),
                label: Text(
                  'Download PDF', 
                  style: TextStyle(color: isDark ? Colors.black : Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.neonGreen : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label, 
          style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey),
        ),
        Text(
          value, 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
