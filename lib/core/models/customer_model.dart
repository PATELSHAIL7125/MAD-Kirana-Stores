class Customer {
  final String id;
  final String name;
  final String phone;
  final double currentBalance;
  final DateTime lastTransactionAt;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.currentBalance,
    required this.lastTransactionAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'currentBalance': currentBalance,
      'lastTransactionAt': lastTransactionAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(String id, Map<String, dynamic> map) {
    return Customer(
      id: id,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      currentBalance: (map['currentBalance'] ?? 0.0).toDouble(),
      lastTransactionAt: DateTime.tryParse(map['lastTransactionAt'] ?? "") ?? DateTime.now(),
    );
  }
}
