import 'package:flutter/material.dart';
import 'package:mechanic_app/theme/app_theme.dart';
import 'package:mechanic_app/widgets/app_avatar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MechanicReviewsScreen extends StatefulWidget {
  const MechanicReviewsScreen({super.key});

  @override
  State<MechanicReviewsScreen> createState() => _MechanicReviewsScreenState();
}

class _MechanicReviewsScreenState extends State<MechanicReviewsScreen> {
  final _supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final user = _supabase.auth.currentUser;

    final Stream<List<Map<String, dynamic>>> reviewsStream = _supabase
        .from('reviews')
        .stream(primaryKey: ['id'])
        .eq('mechanic_id', user?.id ?? '')
        .order('created_at', ascending: false);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Reviews', 
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
        stream: reviewsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final reviews = snapshot.data ?? [];

          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_outline_rounded, size: 64, color: isDark ? Colors.white10 : Colors.black12),
                  const SizedBox(height: 16),
                  Text('No reviews yet', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              final double rating = (review['rating'] as num).toDouble();
              final DateTime date = DateTime.parse(review['created_at']);
              
              return FutureBuilder<Map<String, dynamic>?>(
                future: _supabase.from('profiles').select('full_name, avatar_url').eq('id', review['customer_id']).maybeSingle(),
                builder: (context, profSnapshot) {
                  final customer = profSnapshot.data;
                  final String custName = customer?['full_name'] ?? 'Customer';
                  final String? custAvatar = customer?['avatar_url'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppAvatar(url: custAvatar, fallbackId: review['customer_id'], radius: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    custName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark ? Colors.white : AppColors.textDark,
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(5, (star) => Icon(
                                      Icons.star_rounded, 
                                      color: star < rating ? Colors.amber : Colors.grey[300], 
                                      size: 14,
                                    )),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              DateFormat('dd MMM').format(date),
                              style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontSize: 10),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          review['comment'] ?? 'No comment provided.',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                }
              );
            },
          );
        },
      ),
    );
  }
}
