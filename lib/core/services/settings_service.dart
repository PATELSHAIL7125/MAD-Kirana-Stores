import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get app settings for a user
  Future<Map<String, dynamic>> getSettings(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).collection('settings').doc('app_settings').get();
      if (doc.exists) {
        return doc.data() ?? _getDefaultSettings();
      }
      return _getDefaultSettings();
    } catch (e) {
      print('Error loading settings: $e');
      return _getDefaultSettings();
    }
  }

  /// Save app settings
  Future<bool> saveSettings(String uid, Map<String, dynamic> settings) async {
    try {
      await _firestore.collection('users').doc(uid).collection('settings').doc('app_settings').set(settings, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error saving settings: $e');
      return false;
    }
  }

  /// Get invoice settings
  Future<Map<String, dynamic>> getInvoiceSettings(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).collection('settings').doc('invoice_settings').get();
      if (doc.exists) {
        return doc.data() ?? _getDefaultInvoiceSettings();
      }
      return _getDefaultInvoiceSettings();
    } catch (e) {
      print('Error loading invoice settings: $e');
      return _getDefaultInvoiceSettings();
    }
  }

  /// Save invoice settings
  Future<bool> saveInvoiceSettings(String uid, Map<String, dynamic> settings) async {
    try {
      await _firestore.collection('users').doc(uid).collection('settings').doc('invoice_settings').set(settings, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error saving invoice settings: $e');
      return false;
    }
  }

  /// Get printer settings
  Future<Map<String, dynamic>> getPrinterSettings(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).collection('settings').doc('printer_settings').get();
      if (doc.exists) {
        return doc.data() ?? _getDefaultPrinterSettings();
      }
      return _getDefaultPrinterSettings();
    } catch (e) {
      print('Error loading printer settings: $e');
      return _getDefaultPrinterSettings();
    }
  }

  /// Save printer settings
  Future<bool> savePrinterSettings(String uid, Map<String, dynamic> settings) async {
    try {
      await _firestore.collection('users').doc(uid).collection('settings').doc('printer_settings').set(settings, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error saving printer settings: $e');
      return false;
    }
  }

  /// Default app settings
  Map<String, dynamic> _getDefaultSettings() {
    return {
      'theme': 'light', // light, dark, system
      'language': 'en',
      'currency': '₹',
      'dateFormat': 'dd/MM/yyyy',
    };
  }

  /// Default invoice settings
  Map<String, dynamic> _getDefaultInvoiceSettings() {
    return {
      'invoicePrefix': 'INV-',
      'startingNumber': 1001,
      'termsAndConditions': 'Thank you for your business!',
      'paymentInstructions': 'Payment due on receipt.',
      'showGST': false,
      'defaultTaxRate': 0.0,
    };
  }

  /// Default printer settings
  Map<String, dynamic> _getDefaultPrinterSettings() {
    return {
      'paperSize': 'A4', // A4, Thermal80mm, Thermal58mm
      'autoPrint': false,
      'numberOfCopies': 1,
    };
  }
}
