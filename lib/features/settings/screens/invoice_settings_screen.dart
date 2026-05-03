import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/core/widgets/custom_textfield.dart';
import 'package:my_app/core/widgets/primary_button.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/services/settings_service.dart';

class InvoiceSettingsScreen extends StatefulWidget {
  const InvoiceSettingsScreen({super.key});

  @override
  State<InvoiceSettingsScreen> createState() => _InvoiceSettingsScreenState();
}

class _InvoiceSettingsScreenState extends State<InvoiceSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _settingsService = SettingsService();

  final _prefixController = TextEditingController();
  final _startingNumberController = TextEditingController();
  final _termsController = TextEditingController();
  final _paymentInstructionsController = TextEditingController();
  final _taxRateController = TextEditingController();

  bool _showGST = false;
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

    final settings = await _settingsService.getInvoiceSettings(uid);
    if (mounted) {
      setState(() {
        _prefixController.text = settings['invoicePrefix'] ?? 'INV-';
        _startingNumberController.text = settings['startingNumber'].toString();
        _termsController.text = settings['termsAndConditions'] ?? '';
        _paymentInstructionsController.text = settings['paymentInstructions'] ?? '';
        _showGST = settings['showGST'] ?? false;
        _taxRateController.text = settings['defaultTaxRate'].toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = _authService.currentUserId;
    if (uid == null) return;

    setState(() => _isSaving = true);

    final settings = {
      'invoicePrefix': _prefixController.text.trim(),
      'startingNumber': int.tryParse(_startingNumberController.text) ?? 1001,
      'termsAndConditions': _termsController.text.trim(),
      'paymentInstructions': _paymentInstructionsController.text.trim(),
      'showGST': _showGST,
      'defaultTaxRate': double.tryParse(_taxRateController.text) ?? 0.0,
    };

    final success = await _settingsService.saveInvoiceSettings(uid, settings);

    if (mounted) {
      setState(() => _isSaving = false);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice settings saved!'), backgroundColor: Colors.green),
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
  void dispose() {
    _prefixController.dispose();
    _startingNumberController.dispose();
    _termsController.dispose();
    _paymentInstructionsController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Invoice Settings', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  CustomTextField(
                    controller: _prefixController,
                    label: 'Invoice Prefix',
                    prefixIcon: const Icon(Icons.tag_rounded),
                    hintText: 'e.g., INV-, BILL-',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Prefix is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _startingNumberController,
                    label: 'Starting Invoice Number',
                    prefixIcon: const Icon(Icons.numbers_rounded),
                    hintText: 'e.g. 1001',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Starting number is required';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _termsController,
                    label: 'Terms & Conditions',
                    prefixIcon: const Icon(Icons.description_rounded),
                    maxLines: 3,
                    hintText: 'e.g., Thank you for your business!',
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    controller: _paymentInstructionsController,
                    label: 'Payment Instructions',
                    prefixIcon: const Icon(Icons.payment_rounded),
                    maxLines: 2,
                    hintText: 'e.g., Payment due on receipt',
                  ),
                  const SizedBox(height: 24),

                  // GST Toggle
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Show GST on Bills', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                              Text('Display GST details on invoices', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _showGST,
                          onChanged: (value) => setState(() => _showGST = value),
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                    CustomTextField(
                      controller: _taxRateController,
                      label: 'Default Tax Rate (%)',
                      prefixIcon: const Icon(Icons.percent_rounded),
                      keyboardType: TextInputType.number,
                      hintText: 'e.g., 18',
                    ),
                  const SizedBox(height: 32),

                  PrimaryButton(
                    text: _isSaving ? 'Saving...' : 'Save Settings',
                    onPressed: _isSaving ? null : _saveSettings,
                  ),
                ],
              ),
            ),
    );
  }
}
