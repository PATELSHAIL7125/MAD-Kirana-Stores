import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/core/widgets/custom_card.dart';
import 'package:my_app/core/widgets/primary_button.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/services/firestore_service.dart';
import 'package:my_app/features/billing/screens/payment_screen.dart';
import 'package:my_app/features/khata/screens/khata_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final List<Map<String, dynamic>> _selectedItems = [];
  Map<String, dynamic>? _selectedCustomer;
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  bool _isLoading = false;

  void _showItemPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Select Products",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _firestoreService.getInventoryStream(_authService.currentUserId ?? ""),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return const Center(child: Text("No items in inventory"));
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text("Stock: ${item['stock']}", style: TextStyle(color: (item['stock'] ?? 0) < 10 ? Colors.red : Colors.grey)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "₹${item['price']}",
                                style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 16),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.add_circle_outline, color: AppColors.primary),
                            ],
                          ),
                          onTap: () {
                            _addItemToBill(item);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCustomerPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Select Customer (for Khata)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _firestoreService.getCustomersStream(_authService.currentUserId ?? ""),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    final customers = snapshot.data ?? [];
                    if (customers.isEmpty) {
                      return Center(
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const KhataScreen()));
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("Add New Customer First"),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        return ListTile(
                          title: Text(customer['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(customer['phone']),
                          onTap: () {
                            setState(() => _selectedCustomer = customer);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _addItemToBill(Map<String, dynamic> item) {
    setState(() {
      final existingIndex = _selectedItems.indexWhere((element) => element['id'] == item['id']);
      final int availableStock = item['stock'] ?? 0;

      if (existingIndex != -1) {
        if (_selectedItems[existingIndex]['qty'] < availableStock) {
          _selectedItems[existingIndex]['qty'] += 1;
          _selectedItems[existingIndex]['total'] = _selectedItems[existingIndex]['qty'] * item['price'];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Insufficient stock available!")),
          );
        }
      } else {
        if (availableStock > 0) {
          _selectedItems.add({
            "id": item['id'],
            "name": item['name'],
            "price": item['price'],
            "purchasePrice": item['purchasePrice'] ?? 0.0,
            "gstRate": (item['gstRate'] ?? 0.0).toDouble(),
            "isInclusive": item['isInclusive'] ?? true,
            "qty": 1,
            "total": item['price'],
            "stock": availableStock, // Store max stock for validation
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Item is out of stock!")),
          );
        }
      }
    });
  }

  void _updateQty(int index, int change) {
    setState(() {
      final item = _selectedItems[index];
      int newQty = item['qty'] + change;
      int maxStock = item['stock'] ?? 0;

      if (newQty < 1) {
        _selectedItems.removeAt(index);
      } else if (newQty > maxStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cannot exceed available stock!")),
        );
      } else {
        item['qty'] = newQty;
        item['total'] = newQty * item['price'];
      }
    });
  }

  double get _grandTotal {
    double total = 0;
    for (var item in _selectedItems) {
      final double price = (item['price'] ?? 0.0);
      final int qty = (item['qty'] ?? 1);
      final double rate = (item['gstRate'] ?? 0.0);
      final bool inclusive = item['isInclusive'] ?? true;

      if (inclusive) {
        total += price * qty;
      } else {
        total += (price * (1 + rate / 100)) * qty;
      }
    }
    return total;
  }

  double get _totalTax {
    double tax = 0;
    for (var item in _selectedItems) {
      final double price = (item['price'] ?? 0.0);
      final int qty = (item['qty'] ?? 1);
      final double rate = (item['gstRate'] ?? 0.0);
      final bool inclusive = item['isInclusive'] ?? true;

      if (inclusive) {
        final double base = price / (1 + rate / 100);
        tax += (price - base) * qty;
      } else {
        tax += (price * (rate / 100)) * qty;
      }
    }
    return tax;
  }

  double get _subtotal => _grandTotal - _totalTax;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Point of Sale", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => setState(() => _selectedItems.clear()),
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
          ),
        ],
      ),
      body: Column(
        children: [
          // Customer Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: InkWell(
              onTap: _showCustomerPicker,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _selectedCustomer != null ? AppColors.primary : Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, color: _selectedCustomer != null ? AppColors.primary : Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedCustomer != null ? "Customer: ${_selectedCustomer!['name']}" : "Select Customer (Optional/Khata)",
                        style: TextStyle(
                          color: _selectedCustomer != null ? AppColors.textPrimary : AppColors.textSecondary,
                          fontWeight: _selectedCustomer != null ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (_selectedCustomer != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setState(() => _selectedCustomer = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    else
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _selectedItems.isEmpty
                ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.shopping_basket_outlined, size: 64, color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                        const SizedBox(height: 16),
                        const Text(
                          "Your cart is empty",
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Start adding products to generate bill",
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 32),
                        PrimaryButton(
                          text: "Search Inventory",
                          width: 200,
                          onPressed: _showItemPicker,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _selectedItems.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _selectedItems.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 40),
                          child: OutlinedButton.icon(
                            onPressed: _showItemPicker,
                            icon: const Icon(Icons.add),
                            label: const Text("Add More Items"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              side: const BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        );
                      }
                      final item = _selectedItems[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CustomCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                    ),
                                    Text(
                                      "₹${item['price']} x ${item['qty']}",
                                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildQtyStepper(index),
                              const SizedBox(width: 16),
                              SizedBox(
                                width: 70,
                                child: Text(
                                  "₹${item['total']}",
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Total Bar
          _buildBillSummary(),
        ],
      ),
    );
  }

  Widget _buildQtyStepper(int index) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: () => _updateQty(index, -1),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          Text(
            "${_selectedItems[index]['qty']}",
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
            onPressed: () => _updateQty(index, 1),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildBillSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text("Subtotal: ₹${_subtotal.toStringAsFixed(2)}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                   const SizedBox(height: 2),
                  const Text("Items Total", style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(
                    "₹${_grandTotal.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Taxes", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text("GST: ₹${_totalTax.toStringAsFixed(2)}", style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w900)),
                  Text("(CGST: ₹${(_totalTax / 2).toStringAsFixed(2)} | SGST: ₹${(_totalTax / 2).toStringAsFixed(2)})", 
                    style: TextStyle(color: Colors.grey[600], fontSize: 10, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          PrimaryButton(
            text: "Generate Bill & Pay",
            onPressed: _selectedItems.isEmpty
                ? null
                : () {
                    final String? uid = _authService.currentUserId;
                    if (uid == null) return;

                    final saleData = {
                      "items": List.from(_selectedItems), // Send a copy
                      "totalAmount": _grandTotal,
                      "createdAt": DateTime.now().toIso8601String(),
                      "paymentMethod": "Cash",
                    };

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentScreen(
                          amount: _grandTotal,
                          uid: uid,
                          saleData: {
                            ...saleData,
                            "customerId": _selectedCustomer?['id'],
                            "customerName": _selectedCustomer?['name'],
                            "subtotal": _subtotal,
                            "totalTax": _totalTax,
                            "cgst": _totalTax / 2,
                            "sgst": _totalTax / 2,
                          },
                        ),
                      ),
                    );
                  },
          ),
        ],
      ),
    );
  }
}
