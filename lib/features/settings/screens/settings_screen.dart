import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_theme.dart';
import 'package:my_app/core/services/auth_service.dart';
import 'package:my_app/features/auth/screens/login_screen.dart';
import 'business_profile_settings_screen.dart';
import 'invoice_settings_screen.dart';
import 'printer_settings_screen.dart';
import 'app_preferences_screen.dart';
import 'account_security_screen.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
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
          // Business Profile Section
          _buildSectionHeader('Business Profile', Icons.store_rounded),
          _buildSettingsTile(
            context,
            icon: Icons.business_rounded,
            title: 'Business Details',
            subtitle: 'Shop name, address, GST, logo',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessProfileSettingsScreen())),
          ),
          const SizedBox(height: 24),

          // Invoice & Billing Section
          _buildSectionHeader('Invoice & Billing', Icons.receipt_long_rounded),
          _buildSettingsTile(
            context,
            icon: Icons.receipt_rounded,
            title: 'Invoice Settings',
            subtitle: 'Prefix, numbering, terms & conditions',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvoiceSettingsScreen())),
          ),
          const SizedBox(height: 24),

          // Printer Section
          _buildSectionHeader('Printer', Icons.print_rounded),
          _buildSettingsTile(
            context,
            icon: Icons.print_outlined,
            title: 'Printer Settings',
            subtitle: 'Paper size, auto-print, copies',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrinterSettingsScreen())),
          ),
          const SizedBox(height: 24),

          // App Preferences Section
          _buildSectionHeader('App Preferences', Icons.tune_rounded),
          _buildSettingsTile(
            context,
            icon: Icons.palette_outlined,
            title: 'Appearance & Language',
            subtitle: 'Theme, language, currency, date format',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppPreferencesScreen())),
          ),
          const SizedBox(height: 24),

          // Account & Security Section
          _buildSectionHeader('Account & Security', Icons.security_rounded),
          _buildSettingsTile(
            context,
            icon: Icons.lock_outline_rounded,
            title: 'Account Security',
            subtitle: 'Password, backup, export, delete account',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountSecurityScreen())),
          ),
          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About', Icons.info_outline_rounded),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline_rounded,
            title: 'Help & About',
            subtitle: 'Version, support, privacy, terms',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
          ),
          const SizedBox(height: 32),

          // Logout Button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.red, size: 24),
              ),
              title: const Text(
                'Logout',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
              subtitle: const Text('Sign out of your account'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.red),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Logout', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirm == true && context.mounted) {
                  await authService.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              },
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}
