class InventoryModel {
  final String id;
  final String pharmacyId;
  final String medicineId;
  final Map<String, dynamic>? medicine;
  final Map<String, dynamic>? pharmacy;
  final int price;
  final int quantity;
  final bool inStock;
  final DateTime? expiryDate;

  const InventoryModel({
    required this.id,
    required this.pharmacyId,
    required this.medicineId,
    this.medicine,
    this.pharmacy,
    required this.price,
    required this.quantity,
    required this.inStock,
    this.expiryDate,
  });

  factory InventoryModel.fromJson(Map<String, dynamic> json) {
    final pharmacyRaw = json['pharmacy'];
    final medicineRaw = json['medicine'];
    return InventoryModel(
      id: json['_id'] ?? '',
      pharmacyId: pharmacyRaw is Map
          ? (pharmacyRaw['_id'] ?? '') as String
          : (pharmacyRaw ?? '') as String,
      medicineId: medicineRaw is Map
          ? (medicineRaw['_id'] ?? '') as String
          : (medicineRaw ?? '') as String,
      medicine: medicineRaw is Map
          ? Map<String, dynamic>.from(medicineRaw as Map)
          : null,
      pharmacy: pharmacyRaw is Map
          ? Map<String, dynamic>.from(pharmacyRaw as Map)
          : null,
      price: (json['price'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      inStock: json['in_stock'] as bool? ?? false,
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'] as String)
          : null,
    );
  }

  String get pharmacyName => pharmacy?['name'] as String? ?? '';
  String get pharmacyAddress => pharmacy?['address'] as String? ?? '';
  String get medicineName => medicine?['name'] as String? ?? '';
  String get medicineCategory => medicine?['category'] as String? ?? '';
}
