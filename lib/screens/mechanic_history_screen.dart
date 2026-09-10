import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';

class MechanicHistoryScreen extends StatelessWidget {
  const MechanicHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Work History', 
          style: TextStyle(
            fontWeight: FontWeight.w800, 
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        itemCount: 8,
        itemBuilder: (context, index) {
          return _HistoryItem(
            service: index % 2 == 0 ? 'Engine Repair' : 'Battery Jumpstart',
            customer: 'Customer ${index + 1}',
            date: '${index + 1} Aug 2024',
            amount: 'PKR ${1200 + (index * 150)}',
            isDark: isDark,
          );
        },
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final String service;
  final String customer;
  final String date;
  final String amount;
  final bool isDark;

  const _HistoryItem({
    required this.service,
    required this.customer,
    required this.date,
    required this.amount,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.neonGreen : AppColors.primary).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded, 
              color: isDark ? AppColors.neonGreen : AppColors.primary, 
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service, 
                  style: TextStyle(
                    fontWeight: FontWeight.w700, 
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
                Text(
                  customer, 
                  style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount, 
                style: TextStyle(
                  fontWeight: FontWeight.w800, 
                  color: isDark ? AppColors.neonGreen : AppColors.secondary, 
                  fontSize: 14,
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
    );
  }
}
