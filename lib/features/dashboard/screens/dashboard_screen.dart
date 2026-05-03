import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/core/widgets/custom_card.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/services/firestore_service.dart';
import 'package:my_app/features/inventory/screens/item_list_screen.dart';
import 'package:my_app/features/billing/screens/billing_screen.dart';
import 'package:my_app/features/billing/screens/sales_history_screen.dart';
import 'package:my_app/features/reports/screens/reports_screen.dart';
import 'package:my_app/features/auth/screens/login_screen.dart';
import 'package:my_app/features/settings/screens/settings_screen.dart';
import 'package:my_app/features/khata/screens/khata_screen.dart';
import 'package:my_app/features/notifications/screens/notifications_screen.dart';
import 'package:my_app/features/expenses/screens/expense_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final String uid = _authService.currentUserId ?? "";

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              FutureBuilder<Map<String, dynamic>?>(
                future: _firestoreService.getBusinessProfile(uid),
                builder: (context, profileSnapshot) {
                  final shopName = profileSnapshot.data?['shopName'] ?? "Invoiz Store";
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shopName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              "Welcome back!",
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            children: [
                              IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                                  );
                                },
                                icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 26),
                              ),
                              Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () async {
                              await _authService.signOut();
                              if (!mounted) return;
                              
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                                (route) => false,
                              );
                            },
                            icon: const Icon(Icons.logout_rounded, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // Live Stats Summary
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _firestoreService.getSalesStream(uid),
                builder: (context, salesSnapshot) {
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _firestoreService.getInventoryStream(uid),
                    builder: (context, invSnapshot) {
                      final sales = salesSnapshot.data ?? [];
                      final inventory = invSnapshot.data ?? [];
                      
                      // Filter for today's sales
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final todaySalesList = sales.where((sale) {
                        final createdAt = DateTime.tryParse(sale['createdAt'] ?? "");
                        if (createdAt == null) return false;
                        return createdAt.isAfter(today);
                      }).toList();

                      final double todaySales = todaySalesList.fold(0.0, (sum, sale) => sum + (sale['totalAmount'] ?? 0.0));
                      final int billsCount = todaySalesList.length;
                      final int lowStockCount = inventory.where((item) => (item['stock'] ?? 0) <= (item['minStockLevel'] ?? 5)).length;
                      final int totalItems = inventory.length;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (lowStockCount > 0) ...[
                            _buildLowStockAlert(lowStockCount),
                            const SizedBox(height: 16),
                          ],
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.2,
                            children: [
                              _buildStatCard(
                                "Today's Sales",
                                "₹${todaySales.toStringAsFixed(0)}",
                                Icons.trending_up,
                                AppColors.primary,
                              ),
                              _buildStatCard(
                                "Bills Today",
                                billsCount.toString(),
                                Icons.receipt_long,
                                const Color(0xFF3498DB),
                              ),
                              _buildStatCard(
                                "Low Stock",
                                lowStockCount.toString(),
                                Icons.warning_amber_rounded,
                                lowStockCount > 0 ? Colors.orange : const Color(0xFF27AE60),
                              ),
                              _buildStatCard(
                                "Total Items",
                                totalItems.toString(),
                                Icons.inventory_2_outlined,
                                const Color(0xFF9B59B6),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),

              const Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // New Billing
              CustomCard(
                color: Colors.white,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BillingScreen()),
                  );
                },
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 1.5),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_shopping_cart_rounded, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "New Billing",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            "Create and print invoices quickly",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Action Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  _buildActionCard("Inventory", Icons.inventory_2_rounded, AppColors.primary, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ItemListScreen()));
                  }),
                  _buildActionCard("Sales History", Icons.history_rounded, const Color(0xFF27AE60), () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SalesHistoryScreen()));
                  }),
                  _buildActionCard("Business Insights", Icons.insights_rounded, const Color(0xFF16A085), () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen()));
                  }),
                  _buildActionCard("Settings", Icons.settings_rounded, const Color(0xFF2C3E50), () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                  }),
                  _buildActionCard("Khata Book", Icons.book_rounded, Colors.orange, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const KhataScreen()));
                  }),
                  _buildActionCard("Expenses", Icons.account_balance_wallet_rounded, Colors.redAccent, () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ExpenseScreen()));
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return CustomCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLowStockAlert(int count) {
    return CustomCard(
      color: Colors.orange.shade50,
      border: Border.all(color: Colors.orange.shade200),
      padding: const EdgeInsets.all(12),
      onTap: () {
         Navigator.push(context, MaterialPageRoute(builder: (context) => const ItemListScreen()));
      },
      child: Row(
        children: [
          Icon(Icons.notification_important_rounded, color: Colors.orange.shade800, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "$count items are running low on stock!",
              style: TextStyle(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: Colors.orange.shade800, size: 14),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return CustomCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
