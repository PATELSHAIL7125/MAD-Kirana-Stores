import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_theme.dart';
import '../../../core/services/auth_service.dart';
import '../../business/widgets/business_type_picker.dart';
import '../../../core/services/firestore_service.dart';
import '../../dashboard/screens/dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  // Controllers
  final _shopNameController = TextEditingController();
  final _typeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstController = TextEditingController();
  final _upiController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _passwordController = TextEditingController();

  void _showTypePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BusinessTypePicker(
        onSelected: (type) {
          setState(() {
            _typeController.text = type;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userCredential = await _authService.signUp(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        
        // Save full business profile to Firestore
        final businessData = {
          "uid": userCredential?.uid,
          "shopName": _shopNameController.text.trim(),
          "businessType": _typeController.text,
          "description": _descriptionController.text.trim(),
          "address": {
            "street": _streetController.text.trim(),
            "city": _cityController.text.trim(),
            "state": _stateController.text.trim(),
            "postalCode": _postalController.text.trim(),
          },
          "contact": {
            "phone": _phoneController.text.trim(),
            "email": _emailController.text.trim(),
          },
          "details": {
            "gst": _gstController.text.trim(),
            "upi": _upiController.text.trim(),
          },
          "ownerName": _ownerNameController.text.trim(),
          "createdAt": DateTime.now().toIso8601String(),
        };

        final success = await _firestoreService.saveBusiness(businessData);

        if (mounted) {
          if (success) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const DashboardScreen(),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Account created, but failed to save business data. Please check Firestore permissions."),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Create Business Account",
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1F2937), size: 16),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Business Details",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Setup your shop profile to get started",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 32),

                _buildSectionTitle("Business Information"),
                
                _buildLabel("Shop Name"),
                _buildTextField(
                  controller: _shopNameController,
                  hintText: "e.g. Balaji Kirana Store",
                  icon: Icons.store_outlined,
                ),

                // Notched Business Type Field
                _buildTypePickerField(),

                _buildLabel("Business Description (Optional)"),
                _buildTextField(
                  controller: _descriptionController,
                  hintText: "Enter a brief description",
                  icon: Icons.description_outlined,
                  maxLines: 2,
                ),

                _buildSectionTitle("Business Address"),
                
                _buildLabel("Street Address"),
                _buildTextField(
                  controller: _streetController,
                  hintText: "Enter street address",
                  icon: Icons.location_on_outlined,
                ),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("City"),
                          _buildTextField(
                            controller: _cityController,
                            hintText: "Enter city",
                            icon: Icons.location_city_outlined,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("State"),
                          _buildTextField(
                            controller: _stateController,
                            hintText: "Enter state",
                            icon: Icons.map_outlined,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                _buildLabel("Postal Code"),
                _buildTextField(
                  controller: _postalController,
                  hintText: "Enter postal code",
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.number,
                ),

                _buildSectionTitle("Contact Information"),
                
                _buildLabel("Business Phone"),
                _buildTextField(
                  controller: _phoneController,
                  hintText: "Enter phone number",
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),

                _buildLabel("Business Email"),
                _buildTextField(
                  controller: _emailController,
                  hintText: "Enter email address",
                  icon: Icons.mail_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),

                _buildSectionTitle("Business Details"),
                
                _buildLabel("GST Number (Optional)"),
                _buildTextField(
                  controller: _gstController,
                  hintText: "Enter GST number",
                  icon: Icons.assignment_outlined,
                ),

                _buildLabel("UPI ID (Optional)"),
                _buildTextField(
                  controller: _upiController,
                  hintText: "Enter UPI ID",
                  icon: Icons.credit_card_outlined,
                ),

                _buildSectionTitle("Account Credentials"),

                _buildLabel("Owner Name"),
                _buildTextField(
                  controller: _ownerNameController,
                  hintText: "Enter owner name",
                  icon: Icons.person_outline,
                ),

                _buildLabel("Password"),
                _buildTextField(
                  controller: _passwordController,
                  hintText: "At least 6 characters",
                  icon: Icons.lock_outline,
                  obscureText: true,
                ),

                const SizedBox(height: 40),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Register Business",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                  ),
                ),
                
                const SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: RichText(
                      text: const TextSpan(
                        text: "Already have an account? ",
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                        children: [
                          TextSpan(
                            text: "Login",
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 24),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Color(0xFF4CAF50),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: Color(0xFF1F2937),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      children: [
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
          validator: validator,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
            prefixIcon: Icon(icon, color: const Color(0xFF1F2937), size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTypePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        InkWell(
          onTap: _showTypePicker,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Business Type',
              labelStyle: const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              prefixIcon: const Icon(Icons.business_center_outlined, color: Color(0xFF1F2937), size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.0),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _typeController.text.isEmpty
                        ? 'Select your business type'
                        : _typeController.text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _typeController.text.isEmpty ? Colors.grey[400] : Colors.black,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _typeController.dispose();
    _descriptionController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstController.dispose();
    _upiController.dispose();
    _ownerNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
