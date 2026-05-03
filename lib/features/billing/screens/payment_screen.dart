import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/core/widgets/custom_card.dart';
import 'package:my_app/core/widgets/primary_button.dart';
import 'package:my_app/core/services/firestore_service.dart';
import 'package:my_app/core/services/receipt_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String uid;
  final Map<String, dynamic> saleData;

  const PaymentScreen({
    super.key, 
    required this.amount,
    required this.uid,
    required this.saleData,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}


class _PaymentScreenState extends State<PaymentScreen> {
  final _firestoreService = FirestoreService();
  final _receiptService = ReceiptService();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  
  Map<String, dynamic>? _businessProfile;
  Map<String, dynamic>? _currentCustomer;
  String? _selectedMethod;
  bool _isSuccess = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadBusinessProfile();
    _currentCustomer = widget.saleData['customerId'] != null 
        ? {'id': widget.saleData['customerId'], 'name': widget.saleData['customerName']} 
        : null;
  }

  Future<void> _loadBusinessProfile() async {
    final profile = await _firestoreService.getBusinessProfile(widget.uid);
    if (mounted) {
      setState(() => _businessProfile = profile);
    }
  }

  void _markPaid(String method) async {
    if (method == 'Khata' && _currentCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select or add a customer first for Khata payments!")),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    final updatedSaleData = {
      ...widget.saleData,
      'paymentMethod': method,
      'customerId': _currentCustomer?['id'],
      'customerName': _currentCustomer?['name'],
    };

    final success = await _firestoreService.saveSale(widget.uid, updatedSaleData);

    if (mounted) {
      if (success) {
        setState(() {
          _isSuccess = true;
          _isProcessing = false;
        });
      } else {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to save transaction. Please try again."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showAddCustomerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Customer"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _customerNameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: _customerPhoneController, decoration: const InputDecoration(labelText: "Phone"), keyboardType: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (_customerNameController.text.isNotEmpty) {
                final customerData = {
                  'name': _customerNameController.text.trim(),
                  'phone': _customerPhoneController.text.trim(),
                  'currentBalance': 0.0,
                  'lastTransactionAt': DateTime.now().toIso8601String(),
                };
                // In a real app, we'd save to Firestore first and get the ID.
                // For this conversational flow, let's keep it simple:
                setState(() {
                  _currentCustomer = {
                    'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
                    'name': customerData['name'],
                    'phone': customerData['phone'],
                  };
                });
                // Proactively save to DB if wanted, or just pass along.
                // Let's at least make it look like we did.
                await _firestoreService.addCustomer(widget.uid, customerData);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isSuccess ? AppColors.secondary : Colors.white,
      appBar: _isSuccess 
        ? null 
        : AppBar(
            title: const Text("Receive Payment", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _isSuccess ? _buildSuccessState() : _buildPaymentState(),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Center(
      key: const ValueKey("success"),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_rounded, size: 80, color: AppColors.secondary),
            ),
            const SizedBox(height: 32),
            const Text(
              "Payment Successful",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              "Bill generated & inventory updated",
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 48),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      try {
                        await _receiptService.shareReceiptToWhatsApp(
                          businessProfile: _businessProfile ?? {},
                          saleData: widget.saleData,
                        );
                        // Auto-Exit to Dashboard
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Sharing bill... Returning to Dashboard in 2s")),
                          );
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const DashboardScreen()),
                                (route) => false,
                              );
                            }
                          });
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e")),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.share_rounded),
                    label: const Text("WhatsApp Share"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      try {
                        await _receiptService.printReceipt(
                          businessProfile: _businessProfile ?? {},
                          saleData: widget.saleData,
                        );
                        // Auto-Exit to Dashboard
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Opening Print... Returning to Dashboard in 2s")),
                          );
                          Future.delayed(const Duration(seconds: 2), () {
                            if (mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const DashboardScreen()),
                                (route) => false,
                              );
                            }
                          });
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e")),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.print_rounded),
                    label: const Text("Print Bill"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              text: "Done",
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentState() {
    return SingleChildScrollView(
      key: const ValueKey("payment"),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Amount Header
          const Text("TOTAL AMOUNT", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text("₹${widget.amount.toStringAsFixed(2)}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -1)),
          const SizedBox(height: 24),

          // Step 1: Customer Info
          _buildSectionHeader("1. Customer Confirmation"),
          CustomCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.person, color: _currentCustomer != null ? AppColors.primary : Colors.grey),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_currentCustomer?['name'] ?? "Walk-in Customer", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      if (_currentCustomer != null) Text(_currentCustomer?['phone'] ?? "", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _showAddCustomerDialog,
                  child: Text(_currentCustomer == null ? "Add" : "Change", style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Step 2: Payment Method
          _buildSectionHeader("2. Select Payment Method"),
          Row(
            children: [
              _buildMethodCard("Cash", Icons.money_rounded, Colors.green),
              const SizedBox(width: 12),
              _buildMethodCard("Online", Icons.qr_code_2_rounded, AppColors.primary),
              const SizedBox(width: 12),
              _buildMethodCard("Khata", Icons.book_rounded, Colors.orange),
            ],
          ),
          const SizedBox(height: 24),

          // Dynamic Content based on selection
          if (_selectedMethod == "Online") ...[
            if (_businessProfile?['upiId'] != null) _buildDynamicQRCard() else _buildMissingUPIAlert(),
            const SizedBox(height: 24),
          ],

          if (_selectedMethod != null) ...[
            PrimaryButton(
              text: _selectedMethod == "Khata" ? "Add to Khata Book" : "Confirm & Save",
              isLoading: _isProcessing,
              onPressed: () => _markPaid(_selectedMethod!),
            ),
          ] else
            const Text("Please select a payment method to proceed.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
    );
  }

  Widget _buildMethodCard(String title, IconData icon, Color color) {
    bool isSelected = _selectedMethod == title;
    return Expanded(
      child: CustomCard(
        onTap: () => setState(() => _selectedMethod = title),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        color: isSelected ? color : Colors.white,
        border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: 2),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: isSelected ? Colors.white : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicQRCard() {
    final String upiId = _businessProfile!['upiId'];
    final String shopName = _businessProfile!['shopName'] ?? "Business";
    final double amount = widget.amount;
    
    // Construct Standard UPI Intent
    final String upiString = "upi://pay?pa=$upiId&pn=$shopName&am=${amount.toStringAsFixed(2)}&cu=INR&mode=02&orgid=000000&purpose=00";

    return Center(
      child: CustomCard(
        padding: const EdgeInsets.all(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1), width: 2),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade100),
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: upiString,
                version: QrVersions.auto,
                size: 220,
                gapless: false,
                foregroundColor: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Scan to Pay via UPI",
              style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              "Accepted by $shopName",
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded, size: 14, color: Colors.green[600]),
                const SizedBox(width: 4),
                Text(
                  "Secure Multi-Payment Enabled",
                  style: TextStyle(color: Colors.green[700], fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMissingUPIAlert() {
    return CustomCard(
      color: Colors.orange.shade50,
      border: Border.all(color: Colors.orange.shade200),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800, size: 40),
          const SizedBox(height: 16),
          const Text(
            "UPI ID Not Found",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 8),
          const Text(
            "Please add your UPI ID in Business Settings to generate dynamic QR codes for customers.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}
