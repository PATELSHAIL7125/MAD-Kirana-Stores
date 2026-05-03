import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/core/widgets/custom_textfield.dart';
import 'package:my_app/core/widgets/primary_button.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/core/services/firestore_service.dart';

class BusinessProfileSettingsScreen extends StatefulWidget {
  const BusinessProfileSettingsScreen({super.key});

  @override
  State<BusinessProfileSettingsScreen> createState() => _BusinessProfileSettingsScreenState();
}

class _BusinessProfileSettingsScreenState extends State<BusinessProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();
  final _upiController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBusinessProfile();
  }

  Future<void> _loadBusinessProfile() async {
    final uid = _authService.currentUserId;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final profile = await _firestoreService.getBusinessProfile(uid);
      if (profile != null && mounted) {
        setState(() {
          _shopNameController.text = profile['shopName'] ?? '';
          _ownerNameController.text = profile['ownerName'] ?? '';
          _phoneController.text = profile['phone'] ?? '';
          _emailController.text = profile['email'] ?? '';
          _addressController.text = profile['address'] ?? '';
          _gstController.text = profile['gstNumber'] ?? '';
          _upiController.text = profile['upiId'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = _authService.currentUserId;
    if (uid == null) return;

    setState(() => _isSaving = true);

    final profileData = {
      'shopName': _shopNameController.text.trim(),
      'ownerName': _ownerNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'address': _addressController.text.trim(),
      'gstNumber': _gstController.text.trim(),
      'upiId': _upiController.text.trim(),
    };

    final success = await _firestoreService.saveBusinessProfile(uid, profileData);

    if (mounted) {
      setState(() => _isSaving = false);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Business Profile', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
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
                  // Shop Logo Section
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.store_rounded, size: 50, color: AppColors.primary),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () {
                            // TODO: Implement logo upload
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logo upload coming soon!')),
                            );
                          },
                          icon: const Icon(Icons.camera_alt_rounded, size: 18),
                          label: const Text('Change Logo'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Shop Name
                  CustomTextField(
                    controller: _shopNameController,
                    label: 'Shop Name',
                    hintText: 'Enter shop name',
                    prefixIcon: const Icon(Icons.store_rounded),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Shop name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Owner Name
                  CustomTextField(
                    controller: _ownerNameController,
                    label: 'Owner Name',
                    hintText: 'Enter owner name',
                    prefixIcon: const Icon(Icons.person_rounded),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Owner name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hintText: 'Enter phone number',
                    prefixIcon: const Icon(Icons.phone_rounded),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      if (value.trim().length < 10) {
                        return 'Enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    hintText: 'Enter email address',
                    prefixIcon: const Icon(Icons.email_rounded),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        if (!value.contains('@')) {
                          return 'Enter a valid email';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Address
                  CustomTextField(
                    controller: _addressController,
                    label: 'Address',
                    hintText: 'Enter shop address',
                    prefixIcon: const Icon(Icons.location_on_rounded),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Address is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // GST Number (Optional)
                  CustomTextField(
                    controller: _gstController,
                    label: 'GST Number (Optional)',
                    hintText: 'Enter GST number',
                    prefixIcon: const Icon(Icons.receipt_long_rounded),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),

                  // UPI ID
                  CustomTextField(
                    controller: _upiController,
                    label: 'UPI ID for QR Payments',
                    hintText: 'e.g. yourname@okaxis',
                    prefixIcon: const Icon(Icons.account_balance_wallet_rounded),
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        if (!value.contains('@')) {
                          return 'Enter a valid UPI ID';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  PrimaryButton(
                    text: _isSaving ? 'Saving...' : 'Save Changes',
                    onPressed: _isSaving ? null : _saveProfile,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}
