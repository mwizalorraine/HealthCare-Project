class DeliveryModel {
  final String id;
  final String orderId;
  final String status;
  final String? riderName;
  final String? riderPhone;
  final String address;
  final DateTime? estimatedAt;
  final String? conversationId;
  final List<double>? coordinates;

  const DeliveryModel({
    required this.id,
    required this.orderId,
    required this.status,
    this.riderName,
    this.riderPhone,
    required this.address,
    this.estimatedAt,
    this.conversationId,
    this.coordinates,
  });

  factory DeliveryModel.fromJson(Map<String, dynamic> json) {
    final orderRaw = json['order'];
    final convRaw = json['conversation'];

    List<double>? coords;
    try {
      final destRaw = json['destination'];
      if (destRaw is Map) {
        final rawCoords = destRaw['coordinates'] as List<dynamic>?;
        if (rawCoords != null && rawCoords.length >= 2) {
          coords = [
            (rawCoords[0] as num).toDouble(),
            (rawCoords[1] as num).toDouble(),
          ];
        }
      }
    } catch (_) {}

    return DeliveryModel(
      id: json['_id'] ?? '',
      orderId: orderRaw is Map
          ? (orderRaw['_id'] ?? '') as String
          : (orderRaw ?? '') as String,
      status: json['status'] as String? ?? 'assigned',
      riderName: json['rider_name'] as String?,
      riderPhone: json['rider_phone'] as String?,
      address: json['address'] as String? ?? '',
      estimatedAt: json['estimated_at'] != null
          ? DateTime.tryParse(json['estimated_at'] as String)
          : null,
      conversationId: convRaw is Map
          ? convRaw['_id'] as String?
          : convRaw as String?,
      coordinates: coords,
    );
  }

  bool get isAssigned => status == 'assigned';
  bool get isInTransit => status == 'in_transit';
  bool get isDelivered => status == 'delivered';
  bool get isFailed => status == 'failed';
}
