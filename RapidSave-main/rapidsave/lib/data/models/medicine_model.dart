class MedicineModel {
  final String id;
  final String name;
  final String? genericName;
  final String category;
  final String? manufacturer;
  final String? description;
  final String? dosage;
  final String? sideEffects;
  final String unit;
  final bool requiresPrescription;

  const MedicineModel({
    required this.id,
    required this.name,
    this.genericName,
    required this.category,
    this.manufacturer,
    this.description,
    this.dosage,
    this.sideEffects,
    this.unit = 'tablet',
    this.requiresPrescription = false,
  });

  factory MedicineModel.fromJson(Map<String, dynamic> json) => MedicineModel(
    id: json['_id'] ?? '',
    name: json['name'] ?? '',
    genericName: json['generic_name'] as String?,
    category: json['category'] ?? '',
    manufacturer: json['manufacturer'] as String?,
    description: json['description'] as String?,
    dosage: json['dosage'] as String?,
    sideEffects: json['side_effects'] as String?,
    unit: json['unit'] as String? ?? 'tablet',
    requiresPrescription: json['requires_prescription'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'generic_name': genericName,
    'category': category,
    'manufacturer': manufacturer,
    'description': description,
    'dosage': dosage,
    'side_effects': sideEffects,
    'unit': unit,
    'requires_prescription': requiresPrescription,
  };
}
