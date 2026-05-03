import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/core/widgets/custom_card.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/services/firestore_service.dart';

class SalesHistoryScreen extends StatelessWidget {
  const SalesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final _firestoreService = FirestoreService();
    final _authService = AuthService();
    final String uid = _authService.currentUserId ?? "";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Daily Sales History", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getSalesStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sales = snapshot.data ?? [];
          final totalSalesAmount = sales.fold(0.0, (sum, sale) => sum + (sale['totalAmount'] ?? 0.0));

          return Column(
            children: [
              // Summary Header
              Container(
                padding: const EdgeInsets.all(20),
                color: Colors.white,
                child: Row(
                  children: [
                    _buildSimpleStat("Total Count", sales.length.toString()),
                    const SizedBox(width: 24),
                    _buildSimpleStat("Total Sales", "₹$totalSalesAmount"),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // History List
              Expanded(
                child: sales.isEmpty
                    ? Center(child: Text("No sales recorded yet.", style: TextStyle(color: AppColors.textSecondary)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: sales.length,
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          final sale = sales[index];
                          final double amount = sale['totalAmount'] ?? 0.0;
                          final bool isOnline = sale['paymentMethod'] == "Online" || sale['paymentMethod'] == "UPI";
                          final String createdAt = sale['createdAt'] ?? "";
                          final DateTime date = DateTime.tryParse(createdAt) ?? DateTime.now();
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: CustomCard(
                              padding: const EdgeInsets.all(12),
                              onTap: () {},
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isOnline ? Colors.blue.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isOnline ? Icons.qr_code_rounded : Icons.payments_rounded,
                                      size: 20,
                                      color: isOnline ? Colors.blue : Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sale['invoiceNumber'] != null
                                              ? "${sale['invoiceNumber']}"
                                              : "Sale #${sale['id'].toString().substring(0, 5).toUpperCase()}",
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                        ),
                                        Text(
                                          "${date.hour}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}",
                                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "₹$amount",
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textPrimary),
                                      ),
                                      Text(
                                        sale['paymentMethod'] ?? "Cash",
                                        style: TextStyle(
                                          fontSize: 11, 
                                          fontWeight: FontWeight.w800, 
                                          color: isOnline ? Colors.blue : Colors.orange
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary)),
      ],
    );
  }
}
