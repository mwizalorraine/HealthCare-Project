import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/pharmacy_service.dart';
import '../../../shared/widgets/app_loader.dart';

class PharmacyDetailScreen extends StatefulWidget {
  final String id;
  const PharmacyDetailScreen({super.key, required this.id});

  @override
  State<PharmacyDetailScreen> createState() => _PharmacyDetailScreenState();
}

class _PharmacyDetailScreenState extends State<PharmacyDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _pharmacyService = PharmacyService();

  Map<String, dynamic>? _pharmacy;
  List<Map<String, dynamic>> _inventory = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _fetch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _pharmacyService.getPharmacyById(widget.id),
        _pharmacyService.getPharmacyInventory(widget.id, limit: 50),
      ]);
      if (mounted) {
        setState(() {
          _pharmacy = results[0] as Map<String, dynamic>;
          _inventory = (results[1] as List).cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: AppColors.scaffold, body: AppLoader());

    if (_error != null || _pharmacy == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffold,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_back_rounded, size: 20),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.grey300),
                      const SizedBox(height: 12),
                      Text('Failed to load pharmacy', style: GoogleFonts.workSans(color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _fetch,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(20)),
                          child: Text('Retry', style: GoogleFonts.workSans(color: Colors.white, fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final pharmacy = _pharmacy!;
    final isOpen = pharmacy['is_open'] as bool? ?? false;
    final hasDelivery = pharmacy['has_delivery'] as bool? ?? false;
    final rating = (pharmacy['rating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = (pharmacy['review_count'] as num?)?.toInt() ?? 0;
    final medicinesCount = (pharmacy['medicines_count'] as num?)?.toInt() ?? _inventory.length;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: AppColors.teal,
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF0ABFBC), Color(0xFF0891B2), Color(0xFFE0F7F7), AppColors.white],
                    stops: [0.0, 0.4, 0.75, 1.0],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                            const Spacer(),
                            if (pharmacy['is_verified'] == true)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text('Verified', style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 64, height: 64,
                                    decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(18)),
                                    child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.teal, size: 32),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(pharmacy['name'] as String? ?? '', style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_rounded, size: 12, color: AppColors.grey400),
                                            const SizedBox(width: 3),
                                            Expanded(child: Text(pharmacy['address'] as String? ?? '', style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textSecondary))),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isOpen ? AppColors.successLight : AppColors.dangerLight,
                                                borderRadius: BorderRadius.circular(20),
                                              ),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 5, height: 5,
                                                    decoration: BoxDecoration(shape: BoxShape.circle, color: isOpen ? AppColors.success : AppColors.danger),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(isOpen ? 'Open Now' : 'Closed', style: GoogleFonts.workSans(fontSize: 10, fontWeight: FontWeight.w600, color: isOpen ? AppColors.success : AppColors.danger)),
                                                ],
                                              ),
                                            ),
                                            if (rating > 0) ...[
                                              const SizedBox(width: 8),
                                              const Icon(Icons.star_rounded, color: Color(0xFFFBBC05), size: 14),
                                              const SizedBox(width: 2),
                                              Text('${rating.toStringAsFixed(1)} ($reviewCount)', style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  if ((pharmacy['working_hours'] as String?)?.isNotEmpty == true)
                                    Expanded(child: _InfoChip(icon: Icons.access_time_rounded, label: pharmacy['working_hours'] as String)),
                                  if ((pharmacy['working_hours'] as String?)?.isNotEmpty == true) const SizedBox(width: 8),
                                  Expanded(child: _InfoChip(icon: Icons.medication_rounded, label: '$medicinesCount items')),
                                  if (hasDelivery) ...[
                                    const SizedBox(width: 8),
                                    Expanded(child: _InfoChip(icon: Icons.delivery_dining_rounded, label: 'Delivery')),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Action buttons
                        Row(
                          children: [
                            if ((pharmacy['phone'] as String?)?.isNotEmpty == true)
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final phone = pharmacy['phone'] as String;
                                    final uri = Uri.parse('tel:$phone');
                                    if (await canLaunchUrl(uri)) launchUrl(uri);
                                  },
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(14)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.phone_rounded, color: Colors.white, size: 18),
                                        const SizedBox(width: 8),
                                        Text('Call', style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if ((pharmacy['phone'] as String?)?.isNotEmpty == true) const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => context.push('/create-order', extra: {'pharmacyId': widget.id}),
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.successLight,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.shopping_cart_rounded, color: AppColors.success, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Order', style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Tabs ──────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(22)),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(18)),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w700),
                    unselectedLabelStyle: GoogleFonts.workSans(fontSize: 12),
                    tabs: const [Tab(text: 'Medicines'), Tab(text: 'About'), Tab(text: 'Reviews')],
                  ),
                ),
              ),
            ),

            // ── Tab content ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: IndexedStack(
                index: _tabController.index,
                children: [
                  // Medicines tab
                  _inventory.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(40),
                          child: Center(child: Text('No inventory found', style: GoogleFonts.workSans(color: AppColors.textSecondary))),
                        )
                      : Column(
                          children: _inventory.map((inv) {
                            // Backend populates medicine_id (not 'medicine')
                            final med = (inv['medicine_id'] ?? inv['medicine']) as Map<String, dynamic>?;
                            final name = med?['name'] as String? ?? 'Medicine';
                            final category = med?['category'] as String? ?? '';
                            final price = (inv['price'] as num?)?.toInt() ?? 0;
                            final qty = (inv['quantity'] as num?)?.toInt() ?? 0;
                            final inStock = qty > 0; // use quantity as truth
                            final invId = inv['_id'] as String? ?? '';
                            final medId = med?['_id'] as String? ?? '';

                            return GestureDetector(
                              onTap: inStock && medId.isNotEmpty
                                  ? () => context.push('/create-order', extra: {
                                        'pharmacyId': widget.id,
                                        'inventoryId': invId,
                                        'medicineId': medId,
                                        'medicineName': name,
                                        'medicineCategory': category,
                                        'medicinePrice': price,
                                        'stockQuantity': qty,
                                      })
                                  : null,
                              child: Container(
                                margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48, height: 48,
                                      decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(12)),
                                      child: const Icon(Icons.medication_rounded, color: AppColors.teal, size: 24),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                          if (category.isNotEmpty)
                                            Text(category, style: GoogleFonts.workSans(fontSize: 11, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        if (price > 0)
                                          Text('$price RWF', style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: inStock ? AppColors.successLight : AppColors.dangerLight,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(inStock ? 'In Stock' : 'Out', style: GoogleFonts.workSans(fontSize: 10, fontWeight: FontWeight.w600, color: inStock ? AppColors.success : AppColors.danger)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                  // About tab
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((pharmacy['description'] as String?)?.isNotEmpty == true)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                            child: Text(pharmacy['description'] as String, style: GoogleFonts.workSans(fontSize: 14, color: AppColors.textSecondary, height: 1.6)),
                          ),
                        if ((pharmacy['phone'] as String?)?.isNotEmpty == true) ...[
                          const SizedBox(height: 12),
                          _AboutRow(icon: Icons.phone_rounded, label: 'Phone', value: pharmacy['phone'] as String),
                        ],
                        if ((pharmacy['working_hours'] as String?)?.isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          _AboutRow(icon: Icons.access_time_rounded, label: 'Hours', value: pharmacy['working_hours'] as String),
                        ],
                        if ((pharmacy['email'] as String?)?.isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          _AboutRow(icon: Icons.email_rounded, label: 'Email', value: pharmacy['email'] as String),
                        ],
                        const SizedBox(height: 8),
                        _AboutRow(icon: Icons.delivery_dining_rounded, label: 'Delivery', value: hasDelivery ? 'Available' : 'Not Available'),
                        // Insurance section
                        Builder(builder: (_) {
                          final insurances = (pharmacy['accepted_insurances'] as List<dynamic>?)
                              ?.whereType<String>()
                              .where((s) => s.isNotEmpty)
                              .toList() ?? [];
                          if (insurances.isEmpty) return const SizedBox.shrink();
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 14),
                              Row(children: [
                                const Icon(Icons.health_and_safety_rounded, size: 16, color: AppColors.teal),
                                const SizedBox(width: 6),
                                Text('Accepted Insurances', style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                              ]),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: insurances.map((ins) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.teal.withOpacity(0.3))),
                                  child: Text(ins, style: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.tealDark)),
                                )).toList(),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),

                  // Reviews tab placeholder (reviews not in current API)
                  Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.rate_review_outlined, size: 48, color: AppColors.grey300),
                          const SizedBox(height: 12),
                          Text('No reviews yet', style: GoogleFonts.workSans(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.teal),
          const SizedBox(width: 4),
          Expanded(child: Text(label, style: GoogleFonts.workSans(fontSize: 10, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _AboutRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.teal, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.workSans(fontSize: 11, color: AppColors.textHint)),
              Text(value, style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}
