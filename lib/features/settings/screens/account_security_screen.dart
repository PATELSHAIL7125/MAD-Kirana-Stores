import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/core/widgets/custom_textfield.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/services/firestore_service.dart';
import 'package:my_app/core/services/pdf_web_stub.dart' if (dart.library.html) 'package:my_app/core/services/pdf_web.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';


class AccountSecurityScreen extends StatefulWidget {
  const AccountSecurityScreen({super.key});

  @override
  State<AccountSecurityScreen> createState() => _AccountSecurityScreenState();
}

class _AccountSecurityScreenState extends State<AccountSecurityScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  Future<void> _exportData(BuildContext context) async {
    final uid = _authService.currentUserId;
    if (uid == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preparing CSV export...')),
    );

    try {
      final sales = await _firestoreService.getAllSales(uid);
      
      // Build CSV String
      const header = "Sale ID,Date,Amount,Payment Method,Invoice No";
      final rows = sales.map((sale) {
        final id = sale['id'] ?? '';
        final date = sale['createdAt'] ?? '';
        final amount = sale['totalAmount'] ?? 0;
        final method = sale['paymentMethod'] ?? 'Cash';
        final invoiceNo = sale['invoiceNumber'] ?? '';
        return "$id,$date,$amount,$method,$invoiceNo";
      }).join('\n');
      
      final csvContent = "$header\n$rows";
      final List<int> bytes = csvContent.codeUnits;
      
      if (kIsWeb) {
         downloadPdfWeb(Uint8List.fromList(bytes), "sales_export_${DateTime.now().second}.csv");
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Download started!'), backgroundColor: Colors.green),
         );
      } else {
        // Mobile share - requiring path_provider and share_plus, but for now just showing snackbar as platform dependency might be missing in imports for mobile specific logic
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Export is currently Web-only. feature coming strictly for mobile soon.'), backgroundColor: Colors.orange),
         );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Account & Security', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Change Password
          _buildActionCard(
            icon: Icons.lock_reset_rounded,
            title: 'Change Password',
            subtitle: 'Update your account password',
            color: AppColors.primary,
            onTap: () => _showChangePasswordDialog(context),
          ),
          const SizedBox(height: 16),

          // Backup Data
          _buildActionCard(
            icon: Icons.cloud_upload_rounded,
            title: 'Backup Data',
            subtitle: 'Backup your data to cloud',
            color: Colors.blue,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup feature coming soon!')),
              );
            },
          ),
          const SizedBox(height: 16),

          // Export Data
          _buildActionCard(
            icon: Icons.download_rounded,
            title: 'Export Data',
            subtitle: 'Download your data as CSV',
            color: Colors.green,
            onTap: () => _exportData(context),
          ),
          const SizedBox(height: 16),

          // Delete Account
          _buildActionCard(
            icon: Icons.delete_forever_rounded,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account',
            color: Colors.red,
            onTap: () => _showDeleteAccountDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }

  Future<void> _changePassword(BuildContext context, String current, String newPass) async {
    try {
      await _authService.reauthenticate(current);
      await _authService.updatePassword(newPass);
      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close dialog to show error clearly or keep open? Better close and show snackbar for now
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      controller: currentPasswordController,
                      label: 'Current Password',
                      hintText: 'Enter current password',
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline),
                      validator: (v) => v?.isEmpty == true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: newPasswordController,
                      label: 'New Password',
                      hintText: 'Enter new password',
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_rounded),
                      validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 chars' : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: confirmPasswordController,
                      label: 'Confirm New Password',
                      hintText: 'Confirm new password',
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_rounded),
                      validator: (v) => v != newPasswordController.text ? 'Mismatch' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() => isSubmitting = true);
                      await _changePassword(
                        context, 
                        currentPasswordController.text, 
                        newPasswordController.text
                      );
                      // Dialog is closed by _changePassword on success
                    }
                  },
                  child: isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Text('Update'),
                ),
              ],
            );
          }
        );
      },
    );
  }


  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement account deletion
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion coming soon!'), backgroundColor: Colors.red),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
