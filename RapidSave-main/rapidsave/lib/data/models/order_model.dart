class OrderModel {
  final String id;
  final String pharmacyId;
  final Map<String, dynamic>? pharmacy;
  final List<Map<String, dynamic>> items;
  final String status;
  final String type;
  final String paymentStatus;
  final int totalAmount;
  final String? notes;
  final DateTime createdAt;
  final String? deliveryId;

  const OrderModel({
    required this.id,
    required this.pharmacyId,
    this.pharmacy,
    required this.items,
    required this.status,
    required this.type,
    required this.paymentStatus,
    required this.totalAmount,
    this.notes,
    required this.createdAt,
    this.deliveryId,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final pharmacyRaw = json['pharmacy'];
    final deliveryRaw = json['delivery'];

    return OrderModel(
      id: json['_id'] ?? '',
      pharmacyId: pharmacyRaw is Map
          ? (pharmacyRaw['_id'] ?? '') as String
          : (pharmacyRaw ?? '') as String,
      pharmacy: pharmacyRaw is Map
          ? Map<String, dynamic>.from(pharmacyRaw as Map)
          : null,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      status: json['status'] as String? ?? 'pending',
      type: json['type'] as String? ?? 'reservation',
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      deliveryId: deliveryRaw is Map
          ? deliveryRaw['_id'] as String?
          : deliveryRaw as String?,
    );
  }

  bool get isDelivery => type == 'delivery';
  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isReady => status == 'ready';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get pharmacyName => pharmacy?['name'] as String? ?? '';
  String get pharmacyAddress => pharmacy?['address'] as String? ?? '';

  String get formattedTotal {
    final str = totalAmount.toString();
    return str.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
