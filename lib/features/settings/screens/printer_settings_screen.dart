import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/core/widgets/primary_button.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/services/settings_service.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final _authService = AuthService();
  final _settingsService = SettingsService();

  String _paperSize = 'A4';
  bool _autoPrint = false;
  int _numberOfCopies = 1;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final uid = _authService.currentUserId;
    if (uid == null) return;

    final settings = await _settingsService.getPrinterSettings(uid);
    if (mounted) {
      setState(() {
        _paperSize = settings['paperSize'] ?? 'A4';
        _autoPrint = settings['autoPrint'] ?? false;
        _numberOfCopies = settings['numberOfCopies'] ?? 1;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final uid = _authService.currentUserId;
    if (uid == null) return;

    setState(() => _isSaving = true);

    final settings = {
      'paperSize': _paperSize,
      'autoPrint': _autoPrint,
      'numberOfCopies': _numberOfCopies,
    };

    final success = await _settingsService.savePrinterSettings(uid, settings);

    if (mounted) {
      setState(() => _isSaving = false);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Printer settings saved!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save settings'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Printer Settings', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Paper Size
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.print_rounded, color: AppColors.primary),
                          const SizedBox(width: 12),
                          const Text('Paper Size', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...['A4', 'Thermal 80mm', 'Thermal 58mm'].map((size) {
                        return RadioListTile<String>(
                          title: Text(size),
                          value: size,
                          groupValue: _paperSize,
                          onChanged: (value) => setState(() => _paperSize = value!),
                          activeColor: AppColors.primary,
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Auto Print
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.print_outlined, color: AppColors.primary),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Auto-Print After Billing', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                            Text('Automatically print bill after payment', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _autoPrint,
                        onChanged: (value) => setState(() => _autoPrint = value),
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Number of Copies
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.copy_rounded, color: AppColors.primary),
                          const SizedBox(width: 12),
                          const Text('Number of Copies', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _numberOfCopies > 1 ? () => setState(() => _numberOfCopies--) : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            color: AppColors.primary,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$_numberOfCopies',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary),
                            ),
                          ),
                          IconButton(
                            onPressed: _numberOfCopies < 5 ? () => setState(() => _numberOfCopies++) : null,
                            icon: const Icon(Icons.add_circle_outline),
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                PrimaryButton(
                  text: _isSaving ? 'Saving...' : 'Save Settings',
                  onPressed: _isSaving ? null : _saveSettings,
                ),
              ],
            ),
    );
  }
}
