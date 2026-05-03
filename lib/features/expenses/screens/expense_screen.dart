import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/core/widgets/custom_card.dart';
import 'package:my_app/core/services/firestore_service.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/features/expenses/widgets/add_expense_dialog.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Supplier': return Icons.local_shipping_rounded;
      case 'Utilities': return Icons.bolt_rounded;
      case 'Salary': return Icons.people_rounded;
      case 'Rent': return Icons.home_work_rounded;
      default: return Icons.receipt_long_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Supplier': return Colors.orange;
      case 'Utilities': return Colors.blue;
      case 'Salary': return Colors.purple;
      case 'Rent': return Colors.brown;
      default: return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String uid = _authService.currentUserId ?? "";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Expenses', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddExpenseDialog(),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Add Expense", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getExpensesStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final expenses = snapshot.data ?? [];
          
          final double totalExpenses = expenses.fold(0.0, (sum, exp) => sum + (exp['amount'] ?? 0.0));

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: Colors.white,
                child: Column(
                  children: [
                     const Text("Total Expenses", style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                     const SizedBox(height: 8),
                     Text(
                       "₹${totalExpenses.toStringAsFixed(2)}",
                       style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.redAccent),
                     ),
                  ],
                ),
              ),
              Expanded(
                child: expenses.isEmpty 
                    ? const Center(child: Text("No expenses recorded yet."))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          final date = DateTime.parse(expense['date']);
                          final category = expense['category'] ?? 'Other';
                          final color = _getCategoryColor(category);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: CustomCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(_getCategoryIcon(category), color: color, size: 24),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        expense['title'] ?? 'Expense',
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${DateFormat('dd MMM yyyy').format(date)} • $category",
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _firestoreService.deleteExpense(uid, expense['id']);
                                  }, 
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "-₹${(expense['amount'] ?? 0.0).toStringAsFixed(0)}",
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.redAccent),
                                ),
                              ],
                            ),
                          ),
                        );
                        },
                      ),
              )
            ],
          );
        },
      ),
    );
  }
}
