import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../data/services/medicine_service.dart';
import '../../../data/services/pharmacy_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_loader.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _pharmacyService = PharmacyService();
  final _medicineService = MedicineService();

  List<Map<String, dynamic>> _pharmacies = [];
  List<Map<String, dynamic>> _medicines  = [];
  bool _loadingPharmacies = true;
  bool _loadingMedicines  = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _loadPharmacies();
    _loadMedicines();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPharmacies() async {
    setState(() => _loadingPharmacies = true);
    try {
      final list = await _pharmacyService.getAllPharmacies(limit: 100);
      if (mounted) setState(() => _pharmacies = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingPharmacies = false);
    }
  }

  Future<void> _loadMedicines() async {
    setState(() => _loadingMedicines = true);
    try {
      final list = await _medicineService.searchMedicines(limit: 100);
      if (mounted) setState(() => _medicines = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingMedicines = false);
    }
  }

  Future<void> _verifyPharmacy(String id) async {
    try {
      await _pharmacyService.verifyPharmacy(id);
      _showSnack('Pharmacy verified ✓ — now visible to patients');
      _loadPharmacies();
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''), error: true);
    }
  }

  void _showAddMedicineDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedUnit;
    String? selectedCategory;
    bool saving = false;

    const categories = ['Pain', 'Antibiotic', 'Cardiac', 'Pediatric', 'Skin', 'Mental', 'Diabetic', 'Other'];
    const units = ['Tablet', 'Capsule', 'Syrup', 'Injection', 'Cream', 'Drops', 'Sachet', 'Inhaler', 'Patch', 'Suppository'];

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('Add New Medicine', style: GoogleFonts.workSans(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Medicine Name *',
                    hintText: 'e.g. Paracetamol 500mg',
                    labelStyle: GoogleFonts.workSans(),
                  ),
                  style: GoogleFonts.workSans(),
                ),
                const SizedBox(height: 12),

                // Unit — REQUIRED by backend
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Unit *',
                    hintText: 'e.g. Tablet',
                    labelStyle: GoogleFonts.workSans(),
                  ),
                  style: GoogleFonts.workSans(fontSize: 14, color: AppColors.textPrimary),
                  value: selectedUnit,
                  items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (v) => setS(() => selectedUnit = v),
                ),
                const SizedBox(height: 12),

                // Category — optional but useful
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: GoogleFonts.workSans(),
                  ),
                  style: GoogleFonts.workSans(fontSize: 14, color: AppColors.textPrimary),
                  value: selectedCategory,
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setS(() => selectedCategory = v),
                ),
                const SizedBox(height: 12),

                // Description
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Description (optional)',
                    labelStyle: GoogleFonts.workSans(),
                  ),
                  style: GoogleFonts.workSans(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.workSans()),
            ),
            ElevatedButton(
              onPressed: saving ? null : () async {
                if (nameCtrl.text.trim().isEmpty) { _showSnack('Enter medicine name', error: true); return; }
                if (selectedUnit == null) { _showSnack('Select a unit (e.g. Tablet)', error: true); return; }
                setS(() => saving = true);
                try {
                  await _medicineService.createMedicine(
                    name: nameCtrl.text.trim(),
                    unit: selectedUnit!,
                    category: selectedCategory,
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  );
                  Navigator.pop(ctx);
                  _showSnack('${nameCtrl.text.trim()} added to catalog ✓');
                  _loadMedicines();
                } catch (e) {
                  setS(() => saving = false);
                  _showSnack(e.toString().replaceAll('Exception: ', ''), error: true);
                }
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Add Medicine', style: GoogleFonts.workSans(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.workSans(color: Colors.white)),
      backgroundColor: error ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _confirmSignOut() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign Out', style: GoogleFonts.workSans(fontWeight: FontWeight.w700)),
        content: Text('Are you sure?', style: GoogleFonts.workSans()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.workSans())),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            child: Text('Sign Out', style: GoogleFonts.workSans(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _pendingPharmacies =>
      _pharmacies.where((p) => p['is_verified'] != true).toList();
  List<Map<String, dynamic>> get _verifiedPharmacies =>
      _pharmacies.where((p) => p['is_verified'] == true).toList();

  @override
  Widget build(BuildContext context) {
    final isDark      = ref.watch(settingsProvider).isDark;
    final user        = ref.watch(authProvider).user;
    final scaffoldBg  = isDark ? AppColors.darkScaffold : AppColors.scaffold;
    final cardBg      = isDark ? AppColors.darkCard     : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder   : AppColors.border;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B3A6B), Color(0xFF0891B2), Color(0xFF0ABFBC)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Admin Panel', style: GoogleFonts.workSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                              Text('Welcome, ${user?.name.split(' ').first ?? 'Admin'}', style: GoogleFonts.workSans(fontSize: 12, color: Colors.white70)),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _confirmSignOut,
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatChip(label: 'Pharmacies', value: _pharmacies.length.toString(), icon: Icons.store_rounded, color: Colors.white),
                        const SizedBox(width: 10),
                        _StatChip(label: 'Pending', value: _pendingPharmacies.length.toString(), icon: Icons.hourglass_empty_rounded, color: Colors.orange),
                        const SizedBox(width: 10),
                        _StatChip(label: 'Medicines', value: _medicines.length.toString(), icon: Icons.medication_rounded, color: const Color(0xFF4ADE80)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pending banner
          if (!_loadingPharmacies && _pendingPharmacies.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.warningLight,
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded, color: AppColors.warning, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${_pendingPharmacies.length} pharmacies waiting for approval',
                    style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.warning),
                  ),
                ],
              ),
            ),

          // Tabs
          Container(
            color: cardBg,
            child: TabBar(
              controller: _tabCtrl,
              labelColor: AppColors.teal,
              unselectedLabelColor: AppColors.grey400,
              indicatorColor: AppColors.teal,
              labelStyle: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.workSans(fontSize: 13),
              tabs: [
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Pharmacies'),
                  if (_pendingPharmacies.isNotEmpty) ...[
                    const SizedBox(width: 5),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(10)), child: Text('${_pendingPharmacies.length}', style: GoogleFonts.workSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white))),
                  ],
                ])),
                const Tab(text: 'Medicines'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // ── Pharmacies tab ─────────────────────────────────────────
                _loadingPharmacies
                    ? const AppLoader()
                    : _pharmacies.isEmpty
                        ? _empty('No pharmacies registered yet', Icons.storefront_rounded)
                        : RefreshIndicator(
                            onRefresh: _loadPharmacies,
                            color: AppColors.teal,
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                              children: [
                                if (_pendingPharmacies.isNotEmpty) ...[
                                  _sectionLabel('PENDING APPROVAL', AppColors.warning),
                                  const SizedBox(height: 8),
                                  ..._pendingPharmacies.map((p) => _PharmacyCard(pharmacy: p, cardBg: cardBg, borderColor: borderColor, textPrimary: textPrimary, onVerify: () => _verifyPharmacy(p['_id'] as String))),
                                  const SizedBox(height: 20),
                                ],
                                if (_verifiedPharmacies.isNotEmpty) ...[
                                  _sectionLabel('VERIFIED PHARMACIES', AppColors.success),
                                  const SizedBox(height: 8),
                                  ..._verifiedPharmacies.map((p) => _PharmacyCard(pharmacy: p, cardBg: cardBg, borderColor: borderColor, textPrimary: textPrimary, onVerify: null)),
                                ],
                              ],
                            ),
                          ),

                // ── Medicines tab ──────────────────────────────────────────
                Column(
                  children: [
                    // Add button bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: GestureDetector(
                        onTap: _showAddMedicineDialog,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF0ABFBC), Color(0xFF0891B2)]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text('Add New Medicine to Catalog', style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // List
                    Expanded(
                      child: _loadingMedicines
                          ? const AppLoader()
                          : _medicines.isEmpty
                              ? _empty('No medicines in catalog yet.\nTap the button above to add one.', Icons.medication_rounded)
                              : RefreshIndicator(
                                  onRefresh: _loadMedicines,
                                  color: AppColors.teal,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 30),
                                    itemCount: _medicines.length,
                                    itemBuilder: (_, i) {
                                      final m = _medicines[i];
                                      final name     = m['name']     as String? ?? '';
                                      final category = m['category'] as String? ?? '';
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor, width: 0.5)),
                                        child: Row(
                                          children: [
                                            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.medication_rounded, color: AppColors.teal, size: 22)),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(name, style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                                                  if (category.isNotEmpty)
                                                    Text(category, style: GoogleFonts.workSans(fontSize: 11, color: AppColors.textSecondary)),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(20)),
                                              child: Text('In Catalog', style: GoogleFonts.workSans(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.success)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(String msg, IconData icon) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 56, color: AppColors.grey300),
        const SizedBox(height: 12),
        Text(msg, style: GoogleFonts.workSans(fontSize: 14, color: AppColors.textSecondary), textAlign: TextAlign.center),
      ],
    ),
  );

  Widget _sectionLabel(String text, Color color) => Text(
    text,
    style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.6),
  );
}

// ── Pharmacy card ─────────────────────────────────────────────────────────────
class _PharmacyCard extends StatelessWidget {
  final Map<String, dynamic> pharmacy;
  final Color cardBg, borderColor, textPrimary;
  final VoidCallback? onVerify;
  const _PharmacyCard({required this.pharmacy, required this.cardBg, required this.borderColor, required this.textPrimary, required this.onVerify});

  @override
  Widget build(BuildContext context) {
    final name       = pharmacy['name']           as String? ?? 'Pharmacy';
    final address    = pharmacy['address']        as String? ?? '';
    final phone      = pharmacy['phone']          as String? ?? '';
    final license    = pharmacy['license_number'] as String? ?? '';
    final isOpen     = pharmacy['is_open']        as bool?   ?? false;
    final isVerified = pharmacy['is_verified']    as bool?   ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: !isVerified ? AppColors.warning.withValues(alpha: 0.5) : borderColor, width: !isVerified ? 1.5 : 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(color: isVerified ? AppColors.tealLight : AppColors.warningLight, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.local_pharmacy_rounded, color: isVerified ? AppColors.teal : AppColors.warning, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                if (address.isNotEmpty) Text(address, style: GoogleFonts.workSans(fontSize: 11, color: AppColors.textSecondary)),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: isVerified ? AppColors.successLight : AppColors.warningLight, borderRadius: BorderRadius.circular(20)),
                  child: Text(isVerified ? '✓ Verified' : '⏳ Pending', style: GoogleFonts.workSans(fontSize: 10, fontWeight: FontWeight.w700, color: isVerified ? AppColors.success : AppColors.warning)),
                ),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.circle, size: 7, color: isOpen ? const Color(0xFF4ADE80) : AppColors.grey400),
                  const SizedBox(width: 4),
                  Text(isOpen ? 'Open' : 'Closed', style: GoogleFonts.workSans(fontSize: 10, color: AppColors.textSecondary)),
                ]),
              ]),
            ],
          ),
          if (license.isNotEmpty || phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 12, children: [
              if (license.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.badge_rounded, size: 12, color: AppColors.grey400), const SizedBox(width: 4), Text(license, style: GoogleFonts.workSans(fontSize: 11, color: AppColors.textSecondary))]),
              if (phone.isNotEmpty) Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.phone_rounded, size: 12, color: AppColors.grey400), const SizedBox(width: 4), Text(phone, style: GoogleFonts.workSans(fontSize: 11, color: AppColors.textSecondary))]),
            ]),
          ],
          if (onVerify != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onVerify,
              child: Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0ABFBC), Color(0xFF0891B2)]), borderRadius: BorderRadius.circular(12)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text('Approve & Verify', style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 3),
        Text(value, style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(label, style: GoogleFonts.workSans(fontSize: 9, color: Colors.white70)),
      ]),
    ),
  );
}
