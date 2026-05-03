import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/core/widgets/custom_card.dart';
import 'package:my_app/core/widgets/primary_button.dart';
import 'package:my_app/core/widgets/custom_textfield.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/services/firestore_service.dart';
import 'package:url_launcher/url_launcher.dart';

class KhataScreen extends StatefulWidget {
  const KhataScreen({super.key});

  @override
  State<KhataScreen> createState() => _KhataScreenState();
}

class _KhataScreenState extends State<KhataScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  void _addCustomer() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Customer"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(controller: _nameController, hintText: "Customer Name", prefixIcon: const Icon(Icons.person)),
            const SizedBox(height: 12),
            CustomTextField(controller: _phoneController, hintText: "Phone Number", prefixIcon: const Icon(Icons.phone), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          PrimaryButton(
            text: "Add Customer",
            width: 120,
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                final uid = _authService.currentUserId;
                if (uid != null) {
                  await _firestoreService.addCustomer(uid, {
                    'name': _nameController.text.trim(),
                    'phone': _phoneController.text.trim(),
                    'currentBalance': 0.0,
                    'lastTransactionAt': DateTime.now().toIso8601String(),
                  });
                  _nameController.clear();
                  _phoneController.clear();
                  if (mounted) Navigator.pop(context);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _sendWhatsAppReminder(String phone, double balance) async {
    if (phone.isEmpty) return;
    final message = "Hello! This is a reminder from our shop regarding your pending balance of Rs. ${balance.toStringAsFixed(2)}. Please settle it at your earliest convenience. Thank you!";
    final url = "https://wa.me/91${phone.replaceAll(' ', '')}?text=${Uri.encodeComponent(message)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _authService.currentUserId ?? "";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Khata Book (Credit)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustomer,
        label: const Text("New Customer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        backgroundColor: AppColors.primary,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getCustomersStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final customers = snapshot.data ?? [];

          if (customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.book_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text("No customers in Khata Book", style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              final double balance = (customer['currentBalance'] ?? 0.0).toDouble();

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CustomCard(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(customer['name'][0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(customer['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(customer['phone'], style: const TextStyle(fontSize: 12)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("₹${balance.toStringAsFixed(2)}", style: TextStyle(color: balance > 0 ? Colors.red : Colors.green, fontWeight: FontWeight.w900, fontSize: 16)),
                        if (balance > 0)
                          GestureDetector(
                            onTap: () => _sendWhatsAppReminder(customer['phone'], balance),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.send_rounded, size: 10, color: Colors.green),
                                SizedBox(width: 4),
                                Text("WhatsApp", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
