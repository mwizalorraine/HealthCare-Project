import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../data/services/medicine_service.dart';
import '../../../shared/widgets/app_loader.dart';

class MedicineSearchScreen extends ConsumerStatefulWidget {
  const MedicineSearchScreen({super.key});

  @override
  ConsumerState<MedicineSearchScreen> createState() => _MedicineSearchScreenState();
}

class _MedicineSearchScreenState extends ConsumerState<MedicineSearchScreen>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _medicineService = MedicineService();
  late AnimationController _searchAnim;

  String _query = '';
  String _selected = 'All';
  bool _loading = false;
  bool _searchFocused = false;
  Position? _position;
  List<Map<String, dynamic>> _medicines = [];
  List<String> _recentSearches = [];

  static const _categories = [
    {'key': 'All', 'icon': Icons.apps_rounded},
    {'key': 'Pain', 'icon': Icons.healing_rounded},
    {'key': 'Antibiotic', 'icon': Icons.biotech_rounded},
    {'key': 'Cardiac', 'icon': Icons.favorite_rounded},
    {'key': 'Pediatric', 'icon': Icons.child_care_rounded},
    {'key': 'Skin', 'icon': Icons.face_rounded},
    {'key': 'Mental', 'icon': Icons.psychology_rounded},
    {'key': 'Diabetic', 'icon': Icons.water_drop_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _searchAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _focusNode.addListener(() {
      setState(() => _searchFocused = _focusNode.hasFocus);
      if (_focusNode.hasFocus) {
        _searchAnim.forward();
      } else {
        _searchAnim.reverse();
      }
    });
    _getLocation();
    _fetchMedicines();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    _searchAnim.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) await Geolocator.requestPermission();
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) setState(() => _position = pos);
    } catch (_) {}
  }

  Future<void> _fetchMedicines() async {
    setState(() => _loading = true);
    try {
      final results = await _medicineService.searchMedicines(
        query: _query.isEmpty ? null : _query,
        category: _selected == 'All' ? null : _selected,
      );
      if (mounted) setState(() => _medicines = results);
    } catch (_) {
      if (mounted) setState(() => _medicines = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String query) {
    setState(() => _query = query);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (_query == query) _fetchMedicines();
    });
  }

  void _submitSearch(String query) {
    if (query.trim().isEmpty) return;
    setState(() {
      if (!_recentSearches.contains(query)) {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 6) _recentSearches.removeLast();
      }
    });
    _focusNode.unfocus();
    _fetchMedicines();
  }

  void _onMedicineTap(Map<String, dynamic> medicine) {
    context.push('/medicine/${medicine['_id'] ?? medicine['id']}');
  }


  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appL10nProvider);
    final isDark = ref.watch(settingsProvider).isDark;
    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.scaffold;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.findMedicines,
                                style: GoogleFonts.workSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                              Text(
                                '${_medicines.length} ${l10n.medicinesNearYou}',
                                style: GoogleFonts.workSans(fontSize: 12, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        // GPS indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _position != null ? Icons.location_on_rounded : Icons.location_off_rounded,
                                color: _position != null ? const Color(0xFF4ADE80) : Colors.white70,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _position != null ? l10n.gpsActive : l10n.noGps,
                                style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ── Search bar ──────────────────────────────────────────
                    AnimatedBuilder(
                      animation: _searchAnim,
                      builder: (_, child) => Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1 + _searchAnim.value * 0.08),
                              blurRadius: 12 + _searchAnim.value * 6,
                              spreadRadius: _searchAnim.value * 1,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      child: Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _searchFocused ? AppColors.teal : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: _searchFocused ? AppColors.teal : AppColors.grey400,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                focusNode: _focusNode,
                                onChanged: _onSearch,
                                onSubmitted: _submitSearch,
                                textInputAction: TextInputAction.search,
                                style: GoogleFonts.workSans(fontSize: 14, color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: l10n.searchHint,
                                  hintStyle: GoogleFonts.workSans(fontSize: 14, color: AppColors.textHint),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            if (_query.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  _onSearch('');
                                },
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.grey200),
                                  child: const Icon(Icons.close_rounded, color: AppColors.grey500, size: 14),
                                ),
                              ),
                            if (_query.isEmpty) ...[
                              Container(width: 1, height: 20, color: AppColors.grey200),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () {}, // voice search hook
                                child: const Icon(Icons.mic_none_rounded, color: AppColors.grey400, size: 20),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Category filter ───────────────────────────────────────────────
          SizedBox(
            height: 56,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final key = cat['key'] as String;
                final icon = cat['icon'] as IconData;
                final isSel = key == _selected;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selected = key);
                    _fetchMedicines();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.teal : (isDark ? AppColors.darkSurface : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSel ? AppColors.teal : borderColor,
                      ),
                      boxShadow: isSel
                          ? [BoxShadow(color: AppColors.teal.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 14, color: isSel ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                        const SizedBox(width: 5),
                        Text(
                          key,
                          style: GoogleFonts.workSans(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? Colors.white : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Recent searches (when focused and no query) ───────────────────
          if (_searchFocused && _query.isEmpty && _recentSearches.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.recentSearches,
                        style: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _recentSearches.clear()),
                        child: Text(l10n.clearAll, style: GoogleFonts.workSans(fontSize: 11, color: AppColors.teal, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _recentSearches.map((s) => GestureDetector(
                      onTap: () {
                        _searchCtrl.text = s;
                        _onSearch(s);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.grey100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.history_rounded, size: 12, color: AppColors.grey400),
                            const SizedBox(width: 5),
                            Text(s, style: GoogleFonts.workSans(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // ── Medicine list ─────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const AppLoader()
                : _medicines.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80, height: 80,
                              decoration: BoxDecoration(color: AppColors.tealLight, shape: BoxShape.circle),
                              child: const Icon(Icons.medication_rounded, size: 44, color: AppColors.teal),
                            ),
                            const SizedBox(height: 16),
                            Text(l10n.noMedicinesFound, style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary)),
                            const SizedBox(height: 8),
                            Text('Try a different search term', style: GoogleFonts.workSans(fontSize: 13, color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchMedicines,
                        color: AppColors.teal,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: _medicines.length,
                          itemBuilder: (_, i) => _MedicineCard(
                            medicine: _medicines[i],
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            l10n: l10n,
                            onTap: () => _onMedicineTap(_medicines[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Medicine card ─────────────────────────────────────────────────────────────
class _MedicineCard extends StatelessWidget {
  final Map<String, dynamic> medicine;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final AppL10n l10n;
  final VoidCallback onTap;

  const _MedicineCard({
    required this.medicine,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.l10n,
    required this.onTap,
  });

  static const _catIcons = {
    'Pain': Icons.healing_rounded,
    'Antibiotic': Icons.biotech_rounded,
    'Cardiac': Icons.favorite_rounded,
    'Pediatric': Icons.child_care_rounded,
    'Skin': Icons.face_rounded,
    'Mental': Icons.psychology_rounded,
    'Diabetic': Icons.water_drop_rounded,
  };

  static const _catColors = {
    'Pain': Color(0xFF0ABFBC),
    'Antibiotic': Color(0xFF8B5CF6),
    'Cardiac': Color(0xFFEF4444),
    'Pediatric': Color(0xFF3B82F6),
    'Skin': Color(0xFFF59E0B),
    'Mental': Color(0xFF10B981),
    'Diabetic': Color(0xFF6366F1),
  };

  @override
  Widget build(BuildContext context) {
    final inStock = medicine['in_stock'] as bool? ?? true;
    final count = medicine['pharmacies_count'] as int? ?? 0;
    final category = medicine['category'] as String? ?? '';
    final icon = _catIcons[category] ?? Icons.medication_rounded;
    final color = _catColors[category] ?? AppColors.teal;
    final price = medicine['price'];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine['name'] as String? ?? '',
                    style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$category  ·  $count pharmacies nearby',
                    style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: inStock ? AppColors.successLight : AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          inStock ? l10n.inStock : l10n.outOfStock,
                          style: GoogleFonts.workSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: inStock ? AppColors.success : AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (price != null)
                  Text(
                    '$price RWF',
                    style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700, color: textPrimary),
                  ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: inStock ? AppColors.teal : AppColors.grey200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    inStock ? l10n.find : l10n.notify,
                    style: GoogleFonts.workSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: inStock ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
