import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_theme.dart';

class BusinessTypePicker extends StatelessWidget {
  final Function(String) onSelected;

  const BusinessTypePicker({super.key, required this.onSelected});

  static const List<String> businessTypes = [
    'Grocery',
    'Electronics',
    'Pharmacy',
    'Restaurant',
    'Clothing',
    'Hardware',
    'Stationery',
    'Mobile Shop',
    'Medical Store',
    'General Store',
    'Automobile',
    'Beauty & Cosmetics',
    'Books & Media',
    'Furniture',
    'Jewelry',
    'Sports & Fitness',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9FBFA), // Matching background from screenshot
      ),
      child: Column(
        children: [
          // AppBar-like Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF4CAF50),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Select Business Type',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Placeholder to balance close button
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: businessTypes.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Colors.grey.withValues(alpha: 0.1),
              ),
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  title: Text(
                    businessTypes[index],
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  onTap: () => onSelected(businessTypes[index]),
                );
              },
            ),
          ),
          // Footer item like "Postal Code" seen in screenshot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)))),
            child: const Row(
              children: [
                Text(
                  "Postal Code",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
