import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Business Methods ---
  Future<bool> saveBusiness(Map<String, dynamic> businessData) async {
    try {
      final String? uid = businessData['uid'];
      if (uid == null) {
        log("Error: User UID is null in businessData");
        return false;
      }
      await _db.collection('businesses').doc(uid).set(businessData, SetOptions(merge: true));
      log("Successfully saved business to Firestore: $uid");
      return true;
    } catch (e) {
      log("CRITICAL: Error saving business to Firestore: $e");
      return false;
    }
  }

  // Alias for saveBusiness to match Settings screen usage
  Future<bool> saveBusinessProfile(String uid, Map<String, dynamic> profileData) async {
    return saveBusiness({
      ...profileData,
      'uid': uid,
    });
  }

  Future<Map<String, dynamic>?> getBusinessProfile(String uid) async {
    try {
      final doc = await _db.collection('businesses').doc(uid).get();
      return doc.data();
    } catch (e) {
      log("Error getting business profile: $e");
      return null;
    }
  }

  // --- Inventory Methods ---
  Stream<List<Map<String, dynamic>>> getInventoryStream(String uid) {
    return _db
        .collection('businesses')
        .doc(uid)
        .collection('inventory')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
          ...doc.data(),
          'id': doc.id,
        }).toList());
  }

  Future<bool> addInventoryItem(String uid, Map<String, dynamic> item) async {
    try {
      await _db
          .collection('businesses')
          .doc(uid)
          .collection('inventory')
          .add(item);
      return true;
    } catch (e) {
      log("Error adding inventory item: $e");
      return false;
    }
  }

  Future<bool> updateInventoryItem(String uid, String itemId, Map<String, dynamic> data) async {
    try {
      await _db
          .collection('businesses')
          .doc(uid)
          .collection('inventory')
          .doc(itemId)
          .update(data);
      return true;
    } catch (e) {
      log("Error updating inventory item: $e");
      return false;
    }
  }

  Future<bool> deleteInventoryItem(String uid, String itemId) async {
    try {
      await _db
          .collection('businesses')
          .doc(uid)
          .collection('inventory')
          .doc(itemId)
          .delete();
      return true;
    } catch (e) {
      log("Error deleting inventory item: $e");
      return false;
    }
  }

  // --- Sales Methods ---
  Future<bool> saveSale(String uid, Map<String, dynamic> saleData) async {
    try {
      // 1. Generate Invoice Number and Save Sale (Transactional)
      await _db.runTransaction((transaction) async {
        // Read Settings
        final settingsRef = _db.collection('users').doc(uid).collection('settings').doc('invoice_settings');
        final settingsSnapshot = await transaction.get(settingsRef);
        
        String prefix = 'INV-';
        int nextNumber = 1001;
        
        if (settingsSnapshot.exists) {
          final data = settingsSnapshot.data();
          if (data != null) {
            prefix = data['invoicePrefix'] ?? 'INV-';
            nextNumber = data['startingNumber'] ?? 1001;
          }
        }
        
        // Generate Number
        final String invoiceNumber = "$prefix$nextNumber";
        
        // Calculate Total Profit (GST Aware)
        double totalProfit = 0;
        final List items = saleData['items'];
        for (var item in items) {
          final double sellPrice = (item['price'] ?? 0.0).toDouble();
          final double purPrice = (item['purchasePrice'] ?? 0.0).toDouble();
          final double gstRate = (item['gstRate'] ?? 0.0).toDouble();
          final bool inclusive = item['isInclusive'] ?? true;
          final int qty = (item['qty'] ?? 0).toInt();

          double baseSellPrice = inclusive 
              ? sellPrice / (1 + gstRate / 100) 
              : sellPrice;
          
          totalProfit += (baseSellPrice - purPrice) * qty;
        }

        // Prepare Data
        final newSaleData = {
          ...saleData,
          'invoiceNumber': invoiceNumber,
          'totalProfit': totalProfit,
        };
        
        // Handle Khata Payment
        if (saleData['paymentMethod'] == 'Khata' && saleData['customerId'] != null) {
          final customerRef = _db.collection('businesses').doc(uid)
              .collection('customers').doc(saleData['customerId']);
          
          final customerSnap = await transaction.get(customerRef);
          if (customerSnap.exists) {
            final double currentBalance = (customerSnap.data()?['currentBalance'] ?? 0.0).toDouble();
            final double saleAmount = (saleData['totalAmount'] ?? 0.0).toDouble();
            
            transaction.update(customerRef, {
              'currentBalance': currentBalance + saleAmount,
              'lastTransactionAt': DateTime.now().toIso8601String(),
            });

            // Log Khata Transaction
            final khataTxRef = customerRef.collection('transactions').doc();
            transaction.set(khataTxRef, {
              'type': 'Debit (Sale)',
              'amount': saleAmount,
              'invoiceNumber': invoiceNumber,
              'createdAt': DateTime.now().toIso8601String(),
              'note': 'Sale via Khata',
            });
          }
        }
        
        // Write Sale
        final saleRef = _db.collection('businesses').doc(uid).collection('sales').doc();
        transaction.set(saleRef, newSaleData);
        
        // Increment Counter
        transaction.set(settingsRef, {
          'startingNumber': nextNumber + 1
        }, SetOptions(merge: true));
      });
      
      // 2. Update stock for each item in the sale (Existing Logic)
      final List items = saleData['items'];
      for (var item in items) {
        final itemId = item['id'];
        final int qtySold = item['qty'];
        
        if (itemId != null) {
          final itemRef = _db
              .collection('businesses')
              .doc(uid)
              .collection('inventory')
              .doc(itemId);
          
          // Use a separate transaction for stock to avoid complexity/limits in the main one
          // ideally this should be batched but keeping existing behavior
          await _db.runTransaction((transaction) async {
            final snapshot = await transaction.get(itemRef);
            if (snapshot.exists) {
              final int currentStock = snapshot.data()?['stock'] ?? 0;
              transaction.update(itemRef, {'stock': currentStock - qtySold});
            }
          });
        }
      }
      return true;
    } catch (e) {
      log("Error saving sale: $e");
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> getSalesStream(String uid) {
    return _db
        .collection('businesses')
        .doc(uid)
        .collection('sales')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
          ...doc.data(),
          'id': doc.id,
        }).toList());
  }

  Future<List<Map<String, dynamic>>> getAllSales(String uid) async {
    try {
      final snapshot = await _db
          .collection('businesses')
          .doc(uid)
          .collection('sales')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => {
        ...doc.data(),
        'id': doc.id,
      }).toList();
    } catch (e) {
      log("Error fetching all sales: $e");
      return [];
    }
  }

  // --- Customer/Khata Methods ---
  Future<bool> addCustomer(String uid, Map<String, dynamic> customerData) async {
    try {
      await _db
          .collection('businesses')
          .doc(uid)
          .collection('customers')
          .add(customerData);
      return true;
    } catch (e) {
      log("Error adding customer: $e");
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> getCustomersStream(String uid) {
    return _db
        .collection('businesses')
        .doc(uid)
        .collection('customers')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
          ...doc.data(),
          'id': doc.id,
        }).toList());
  }

  Future<bool> recordPayment(String uid, String customerId, double amount, String note) async {
    try {
      await _db.runTransaction((transaction) async {
        final customerRef = _db.collection('businesses').doc(uid).collection('customers').doc(customerId);
        final snapshot = await transaction.get(customerRef);
        
        if (snapshot.exists) {
          final double currentBalance = (snapshot.data()?['currentBalance'] ?? 0.0).toDouble();
          transaction.update(customerRef, {
            'currentBalance': currentBalance - amount,
            'lastTransactionAt': DateTime.now().toIso8601String(),
          });

          final txRef = customerRef.collection('transactions').doc();
          transaction.set(txRef, {
            'type': 'Credit (Payment)',
            'amount': amount,
            'createdAt': DateTime.now().toIso8601String(),
            'note': note,
          });
        }
      });
      return true;
    } catch (e) {
      log("Error recording payment: $e");
      return false;
    }
  }

  // --- Expense Methods ---
  Future<bool> addExpense(String uid, Map<String, dynamic> expenseData) async {
    try {
      await _db
          .collection('businesses')
          .doc(uid)
          .collection('expenses')
          .add(expenseData);
      return true;
    } catch (e) {
      log("Error adding expense: $e");
      return false;
    }
  }

  Stream<List<Map<String, dynamic>>> getExpensesStream(String uid) {
    return _db
        .collection('businesses')
        .doc(uid)
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
          ...doc.data(),
          'id': doc.id,
        }).toList());
  }

  Future<bool> deleteExpense(String uid, String expenseId) async {
    try {
      await _db
          .collection('businesses')
          .doc(uid)
          .collection('expenses')
          .doc(expenseId)
          .delete();
      return true;
    } catch (e) {
      log("Error deleting expense: $e");
      return false;
    }
  }
}

