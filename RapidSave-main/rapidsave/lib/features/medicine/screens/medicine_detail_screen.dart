import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../../shared/widgets/app_loader.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/medicine_service.dart';

class MedicineDetailScreen extends StatefulWidget {
  final String id;
  const MedicineDetailScreen({super.key, required this.id});

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  final _medicineService = MedicineService();

  Map<String, dynamic>? _medicine;
  // Each item is an inventory record with populated `pharmacy` field
  List<Map<String, dynamic>> _inventory = [];
  bool _loading = false;
  Position? _position;

  @override
  void initState() {
    super.initState();
    _getLocation();
    _fetchMedicine();
  }

  Future<void> _getLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) setState(() => _position = pos);
      if (_medicine != null) _fetchInventory();
    } catch (_) {}
  }

  Future<void> _fetchMedicine() async {
    setState(() => _loading = true);
    try {
      final med = await _medicineService.getMedicineById(widget.id);
      setState(() => _medicine = med);
      await _fetchInventory();
    } catch (_) {
      setState(() => _medicine = {
        '_id': widget.id,
        'name': 'Medicine',
        'category': 'General',
        'in_stock': true,
        'description': 'No description available.',
      });
      await _fetchInventory();
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchInventory() async {
    try {
      final list = await _medicineService.getInventoryForMedicine(
        widget.id,
        lat: _position?.latitude,
        lng: _position?.longitude,
      );
      if (mounted) setState(() => _inventory = list);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final medicine = _medicine;
    final inStock = _inventory.any((inv) => ((inv['quantity'] as num?) ?? 0) > 0);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: _loading
          ? const AppLoader()
          : Column(
              children: [
                // ── Header ────────────────────────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0ABFBC), Color(0xFF0891B2), Color(0xFF1B3A6B)],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Medicine Details',
                                      style: GoogleFonts.workSans(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                                    ),
                                    Text(
                                      medicine?['category'] as String? ?? '',
                                      style: GoogleFonts.workSans(fontSize: 13, color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                                child: Text(
                                  inStock ? '✓ In Stock' : '✗ Out of Stock',
                                  style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 64, height: 64,
                                  decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(18)),
                                  child: const Icon(Icons.medication_rounded, color: AppColors.teal, size: 32),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        medicine?['name'] as String? ?? '',
                                        style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        medicine?['category'] as String? ?? '',
                                        style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: inStock ? AppColors.successLight : AppColors.dangerLight,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              inStock ? 'In Stock' : 'Out of Stock',
                                              style: GoogleFonts.workSans(fontSize: 10, fontWeight: FontWeight.w600, color: inStock ? AppColors.success : AppColors.danger),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.local_pharmacy_rounded, size: 12, color: AppColors.grey400),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${_inventory.length} pharmacies',
                                            style: GoogleFonts.workSans(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Body ──────────────────────────────────────────────────
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _fetchMedicine,
                    color: AppColors.teal,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                      children: [
                        if (medicine?['description'] != null)
                          _InfoSection(
                            title: 'Description',
                            content: medicine!['description'] as String,
                            icon: Icons.info_outline_rounded,
                          ),
                        if (medicine?['dosage'] != null) ...[
                          const SizedBox(height: 12),
                          _InfoSection(
                            title: 'Dosage',
                            content: medicine!['dosage'] as String,
                            icon: Icons.medical_information_outlined,
                          ),
                        ],
                        if (medicine?['side_effects'] != null) ...[
                          const SizedBox(height: 12),
                          _InfoSection(
                            title: 'Side Effects',
                            content: medicine!['side_effects'] as String,
                            icon: Icons.warning_amber_rounded,
                            iconColor: AppColors.warning,
                            bgColor: AppColors.warningLight,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.dangerLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.danger.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.health_and_safety_outlined, color: AppColors.danger, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Always consult a licensed pharmacist or doctor before use. Do not self-medicate.',
                                  style: GoogleFonts.workSans(fontSize: 12, color: AppColors.danger, height: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Available at pharmacies ──────────────────────
                        Row(
                          children: [
                            Text(
                              'Available At',
                              style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            const Spacer(),
                            if (_position != null)
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 12, color: AppColors.teal),
                                  const SizedBox(width: 3),
                                  Text('Sorted by distance', style: GoogleFonts.workSans(fontSize: 11, color: AppColors.teal)),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (_inventory.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Center(
                              child: Text(
                                'No pharmacies found nearby',
                                style: GoogleFonts.workSans(fontSize: 14, color: AppColors.textSecondary),
                              ),
                            ),
                          )
                        else
                          ..._inventory.map((inv) {
                            // Backend populates pharmacy_id (not 'pharmacy')
                            final pharmacy = (inv['pharmacy_id'] ?? inv['pharmacy']) as Map<String, dynamic>?;
                            final qty = (inv['quantity'] as num?)?.toInt() ?? 0;
                            final pInStock = qty > 0; // use quantity as truth
                            final price = (inv['price'] as num?)?.toInt() ?? 0;
                            final distance = (inv['distance'] as num?)?.toDouble();
                            final distStr = distance != null ? '${distance.toStringAsFixed(1)}km' : '';
                            final pharmacyName = pharmacy?['name'] as String? ?? 'Pharmacy';
                            final pharmacyId = pharmacy?['_id'] as String? ?? '';
                            final pharmacyAddress = pharmacy?['address'] as String? ?? '';
                            final inventoryId = inv['_id'] as String? ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.border),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      color: pInStock ? AppColors.tealLight : AppColors.grey100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(Icons.local_pharmacy_rounded, color: pInStock ? AppColors.teal : AppColors.grey400, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(pharmacyName, style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                        Row(
                                          children: [
                                            if (distStr.isNotEmpty) ...[
                                              const Icon(Icons.location_on_rounded, size: 11, color: AppColors.grey400),
                                              const SizedBox(width: 2),
                                              Text(distStr, style: GoogleFonts.workSans(fontSize: 11, color: AppColors.textSecondary)),
                                              const SizedBox(width: 8),
                                            ],
                                            Text('$price RWF', style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.teal)),
                                          ],
                                        ),
                                        if (pharmacyAddress.isNotEmpty)
                                          Text(pharmacyAddress, style: GoogleFonts.workSans(fontSize: 11, color: AppColors.textHint)),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: pInStock
                                        ? () => context.push('/create-order', extra: {
                                              'pharmacyId': pharmacyId,
                                              'inventoryId': inventoryId,
                                              'medicineId': widget.id,
                                              'medicineName': medicine?['name'] ?? '',
                                              'medicineCategory': medicine?['category'] ?? '',
                                              'medicinePrice': price,
                                              'stockQuantity': qty,
                                            })
                                        : null,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: pInStock ? AppColors.teal : AppColors.grey200,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        pInStock ? 'Order' : 'N/A',
                                        style: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w700, color: pInStock ? Colors.white : AppColors.textHint),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),

                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () => context.go('/pharmacies'),
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.teal,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: AppColors.teal.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: Center(
                              child: Text(
                                'See All Nearby Pharmacies →',
                                style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color? iconColor;
  final Color? bgColor;

  const _InfoSection({required this.title, required this.content, required this.icon, this.iconColor, this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(color: bgColor ?? AppColors.tealLight, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor ?? AppColors.teal, size: 16),
              ),
              const SizedBox(width: 10),
              Text(title, style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),
          Text(content, style: GoogleFonts.workSans(fontSize: 13, color: AppColors.textSecondary, height: 1.6)),
        ],
      ),
    );
  }
}
