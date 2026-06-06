class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final bool isActive;
  final bool emailVerified;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.isActive = true,
    this.emailVerified = false,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['_id'] ?? '',
    name: json['name'] ?? '',
    email: json['email'] ?? '',
    role: json['role'] ?? 'patient',
    phone: json['phone'],
    isActive: json['is_active'] ?? true,
    emailVerified: json['email_verified'] ?? false,
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'email': email,
    'role': role,
    'phone': phone,
    'is_active': isActive,
    'email_verified': emailVerified,
    'createdAt': createdAt.toIso8601String(),
  };

  bool get isPatient => role == 'patient';
  bool get isPharmacyAdmin => role == 'pharmacy_admin';
  bool get isAdmin => role == 'admin';
}
