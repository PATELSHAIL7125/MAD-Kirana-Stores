import 'package:flutter/material.dart';
import 'package:my_app/core/widgets/primary_button.dart';
import 'package:my_app/core/widgets/custom_textfield.dart';
import 'package:my_app/core/services/firestore_service.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:convert';
import 'dart:typed_data';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _nameController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _minStockController = TextEditingController(text: '5');
  final _categoryController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  bool _isLoading = false;
  double _gstRate = 0;
  bool _isInclusive = true;

  double _parseNumber(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    String str = val.toString().replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(str) ?? 0.0;
  }

  Future<void> _importCSV() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) throw Exception("Could not read file data");

      // Normalize EOL characters to \n to support Mac/Linux CSVs as well as Windows
      final csvString = utf8.decode(bytes).replaceAll('\r\n', '\n');
      final List<List<dynamic>> rows = const CsvToListConverter(eol: '\n').convert(csvString);

      if (rows.isEmpty) throw Exception("CSV file is empty");

      // Dynamic Column Detection
      int nameIdx = -1, catIdx = -1, purIdx = -1, sellIdx = -1, stockIdx = -1, gstIdx = -1;
      
      final header = rows[0].map((e) => e.toString().toLowerCase().trim()).toList();
      for (int i = 0; i < header.length; i++) {
        final h = header[i];
        if (nameIdx == -1 && (h.contains('name') || h.contains('product') || h.contains('item'))) nameIdx = i;
        else if (catIdx == -1 && h.contains('cat')) catIdx = i;
        else if (purIdx == -1 && (h.contains('purchase') || h.contains('buy') || h.contains('cost'))) purIdx = i;
        else if (sellIdx == -1 && (h.contains('sell') || h.contains('price') || h.contains('mrp') || h.contains('rate'))) sellIdx = i;
        else if (stockIdx == -1 && (h.contains('stock') || h.contains('qty') || h.contains('quantity'))) stockIdx = i;
        else if (gstIdx == -1 && (h.contains('gst') || h.contains('tax'))) gstIdx = i;
      }

      // If no name index found, maybe there's no header. Default to 0, 1, 2, 3, 4
      int startIndex = 1;
      if (nameIdx == -1) {
        startIndex = 0;
        nameIdx = 0; catIdx = 1; purIdx = 2; sellIdx = 3; stockIdx = 4;
      }

      final String? uid = _authService.currentUserId;
      if (uid == null) throw Exception("User not logged in");

      int successCount = 0;
      int errorCount = 0;

      for (int i = startIndex; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty) continue;

        try {
          final itemData = {
            "name": nameIdx != -1 && row.length > nameIdx ? row[nameIdx].toString().trim() : "Unnamed Item",
            "category": catIdx != -1 && row.length > catIdx ? row[catIdx].toString().trim() : "General",
            "purchasePrice": purIdx != -1 && row.length > purIdx ? _parseNumber(row[purIdx]) : 0.0,
            "price": sellIdx != -1 && row.length > sellIdx ? _parseNumber(row[sellIdx]) : 0.0,
            "stock": stockIdx != -1 && row.length > stockIdx ? _parseNumber(row[stockIdx]).toInt() : 0,
            "minStockLevel": 5, // Default for CSV imports
            "gstRate": gstIdx != -1 && row.length > gstIdx ? _parseNumber(row[gstIdx]) : 0.0,
            "isInclusive": true, // Defaulting to true for simplicity in CSV imports
            "createdAt": DateTime.now().toIso8601String(),
          };

          if (itemData["name"] == "Unnamed Item" && itemData["price"] == 0.0) {
            errorCount++;
            continue;
          }

          final success = await _firestoreService.addInventoryItem(uid, itemData);
          if (success) successCount++;
          else errorCount++;
        } catch (e) {
          errorCount++;
        }
      }

      if (mounted) {
        String message = "Import complete: $successCount items added.";
        if (errorCount > 0) message += " ($errorCount failed/skipped)";
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: errorCount > 0 ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error importing CSV: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCSVGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("CSV Import Guide"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Your CSV file should have these columns (order doesn't matter if headers exist):", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text("• Product Name (required)"),
            Text("• Selling Price (e.g. 100)"),
            Text("• Cost Price (Optional)"),
            Text("• Category (Optional)"),
            Text("• Stock Qty (Optional)"),
            Text("• GST % (Optional, e.g. 18)"),
            SizedBox(height: 12),
            Text("Note: Our system is smart and will try to detect columns based on names like 'Product', 'Qty', 'MRP', etc.", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Got it!")),
        ],
      ),
    );
  }

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final String? uid = _authService.currentUserId;
      if (uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: User not logged in")),
        );
        return;
      }

      final itemData = {
        "name": _nameController.text.trim(),
        "price": double.tryParse(_sellingPriceController.text.trim()) ?? 0.0,
        "purchasePrice": double.tryParse(_purchasePriceController.text.trim()) ?? 0.0,
        "stock": int.tryParse(_stockController.text.trim()) ?? 0,
        "minStockLevel": int.tryParse(_minStockController.text.trim()) ?? 5,
        "category": _categoryController.text.trim().isEmpty ? "General" : _categoryController.text.trim(),
        "gstRate": _gstRate,
        "isInclusive": _isInclusive,
        "createdAt": DateTime.now().toIso8601String(),
      };

      final success = await _firestoreService.addInventoryItem(uid, itemData);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Item Added Successfully!")),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to add item. Please try again.")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Item"),
        actions: [
          IconButton(
            onPressed: _showCSVGuide,
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: "CSV Format Guide",
          ),
          IconButton(
            onPressed: _isLoading ? null : _importCSV,
            icon: const Icon(Icons.file_upload_rounded),
            tooltip: "Bulk Import CSV",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _nameController,
                hintText: "Item Name",
                prefixIcon: const Icon(Icons.label),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _categoryController,
                hintText: "Category (e.g. Drinks, Snacks)",
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _purchasePriceController,
                      hintText: "Pur. Price (₹)",
                      prefixIcon: const Icon(Icons.shopping_bag_outlined),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _sellingPriceController,
                      hintText: "Sell. Price (₹)",
                      prefixIcon: const Icon(Icons.currency_rupee),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _stockController,
                hintText: "Stock Qty",
                prefixIcon: const Icon(Icons.inventory),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _minStockController,
                hintText: "Low Stock Alert Level (e.g. 5)",
                prefixIcon: const Icon(Icons.warning_amber_rounded),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // GST Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    DropdownButtonFormField<double>(
                      value: _gstRate,
                      decoration: const InputDecoration(
                        labelText: "GST Rate (%)",
                        prefixIcon: Icon(Icons.percent, size: 20),
                        border: InputBorder.none,
                      ),
                      items: [0.0, 5.0, 12.0, 18.0, 28.0].map((rate) {
                        return DropdownMenuItem(
                          value: rate,
                          child: Text("${rate.toInt()}%"),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _gstRate = val ?? 0),
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text("Price Includes GST", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: const Text("Keep this ON for standard retail prices", style: TextStyle(fontSize: 12)),
                      value: _isInclusive,
                      activeColor: Colors.green,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _isInclusive = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: "Save Item",
                onPressed: _saveItem,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sellingPriceController.dispose();
    _purchasePriceController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}
