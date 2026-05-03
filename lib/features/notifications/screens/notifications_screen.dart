import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/core/widgets/custom_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> dummyNotifications = [
      {
        'title': 'Low Stock Alert',
        'body': 'You have 5 items running low on stock. Please restock soon.',
        'time': '10 mins ago',
        'icon': Icons.warning_amber_rounded,
        'color': Colors.orange,
        'isRead': false,
      },
      {
        'title': 'New Feature Available',
        'body': 'Push notifications have been successfully enabled for your app!',
        'time': '2 hours ago',
        'icon': Icons.bolt_rounded,
        'color': AppColors.primary,
        'isRead': false,
      },
      {
        'title': 'Monthly Report Generated',
        'body': 'Your sales report for the last month is ready. Tap to view.',
        'time': '1 day ago',
        'icon': Icons.insights_rounded,
        'color': const Color(0xFF16A085),
        'isRead': true,
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: dummyNotifications.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final notif = dummyNotifications[index];
          final bool isRead = notif['isRead'];

          return CustomCard(
            padding: const EdgeInsets.all(16),
            color: isRead ? Colors.white : notif['color'].withValues(alpha: 0.05),
            border: Border.all(
              color: isRead 
                  ? Colors.grey.shade200 
                  : notif['color'].withValues(alpha: 0.3),
              width: 1.5,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: notif['color'].withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(notif['icon'], color: notif['color'], size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif['title'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            notif['time'],
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notif['body'],
                        style: TextStyle(
                          fontSize: 13,
                          color: isRead ? AppColors.textSecondary : AppColors.textPrimary.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isRead) ...[
                  const SizedBox(width: 12),
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
