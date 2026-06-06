class PharmacyModel {
  final String id;
  final String name;
  final String? description;
  final String address;
  final String? phone;
  final String? email;
  final bool isOpen;
  final bool hasDelivery;
  final bool isVerified;
  final double? rating;
  final int reviewCount;
  final Map<String, dynamic>? location;
  final String? hours;
  final double? distance;
  final int medicinesCount;

  const PharmacyModel({
    required this.id,
    required this.name,
    this.description,
    required this.address,
    this.phone,
    this.email,
    this.isOpen = false,
    this.hasDelivery = false,
    this.isVerified = false,
    this.rating,
    this.reviewCount = 0,
    this.location,
    this.hours,
    this.distance,
    this.medicinesCount = 0,
  });

  factory PharmacyModel.fromJson(Map<String, dynamic> json) => PharmacyModel(
    id: json['_id'] ?? '',
    name: json['name'] ?? '',
    description: json['description'] as String?,
    address: json['address'] ?? '',
    phone: json['phone'] as String?,
    email: json['email'] as String?,
    isOpen: json['is_open'] as bool? ?? false,
    hasDelivery: json['has_delivery'] as bool? ?? false,
    isVerified: json['is_verified'] as bool? ?? false,
    rating: (json['rating'] as num?)?.toDouble(),
    reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
    location: json['location'] as Map<String, dynamic>?,
    hours: json['hours'] as String?,
    distance: (json['distance'] as num?)?.toDouble(),
    medicinesCount: (json['medicines_count'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'description': description,
    'address': address,
    'phone': phone,
    'email': email,
    'is_open': isOpen,
    'has_delivery': hasDelivery,
    'is_verified': isVerified,
    'rating': rating,
    'review_count': reviewCount,
    'location': location,
    'hours': hours,
    'distance': distance,
    'medicines_count': medicinesCount,
  };
}
