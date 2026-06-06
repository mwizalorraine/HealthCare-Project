import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/pharmacy_service.dart';
import '../../../shared/widgets/app_loader.dart';

class NearbyPharmaciesScreen extends ConsumerStatefulWidget {
  const NearbyPharmaciesScreen({super.key});

  @override
  ConsumerState<NearbyPharmaciesScreen> createState() =>
      _NearbyPharmaciesScreenState();
}

class _NearbyPharmaciesScreenState extends ConsumerState<NearbyPharmaciesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  final _insuranceCtrl = TextEditingController();
  final _mapController = MapController();
  final _pharmacyService = PharmacyService();

  String _query = '';
  String _activeInsurance = '';
  bool _loading = false;
  bool _showMap = false;
  Position? _position;

  LatLng _center = const LatLng(-1.9441, 30.0619);

  List<Map<String, dynamic>> _pharmacies = [];


  List<Map<String, dynamic>> get _filtered {
    return _pharmacies.where((p) {
      final matchQuery =
          _query.isEmpty ||
          p['name'].toString().toLowerCase().contains(_query.toLowerCase()) ||
          p['address'].toString().toLowerCase().contains(_query.toLowerCase());
      // Backend returns is_open / has_delivery; older shape may use open / delivery
      final isOpen = p['is_open'] as bool? ?? p['open'] as bool? ?? false;
      final hasDelivery = p['has_delivery'] as bool? ?? p['delivery'] as bool? ?? false;
      final tabIndex = _tabController.index;
      if (tabIndex == 1) return matchQuery && isOpen;
      if (tabIndex == 2) return matchQuery && hasDelivery;
      return matchQuery;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _getLocationAndFetch();
  }

  Future<void> _getLocationAndFetch({String? insurance}) async {
    setState(() => _loading = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _position = pos;
        _center = LatLng(pos.latitude, pos.longitude);
      });

      try {
        final effectiveInsurance = insurance ?? (_activeInsurance.isNotEmpty ? _activeInsurance : null);
        final list = await _pharmacyService.getNearbyPharmacies(
          lat: pos.latitude,
          lng: pos.longitude,
          radius: 10,
          insurance: effectiveInsurance,
        );
        if (mounted) setState(() => _pharmacies = list);
      } catch (_) {
        if (mounted) setState(() => _pharmacies = []);
      }
    } catch (_) {
      if (mounted) setState(() => _pharmacies = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _searchByInsurance() {
    final ins = _insuranceCtrl.text.trim();
    setState(() => _activeInsurance = ins);
    if (_position != null) {
      _fetchWithPosition(insurance: ins.isNotEmpty ? ins : null);
    } else {
      _getLocationAndFetch(insurance: ins.isNotEmpty ? ins : null);
    }
  }

  Future<void> _fetchWithPosition({String? insurance}) async {
    final pos = _position;
    if (pos == null) return;
    setState(() => _loading = true);
    try {
      final list = await _pharmacyService.getNearbyPharmacies(
        lat: pos.latitude,
        lng: pos.longitude,
        radius: 10,
        insurance: insurance,
      );
      if (mounted) setState(() => _pharmacies = list);
    } catch (_) {
      if (mounted) setState(() => _pharmacies = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  LatLng _getPharmacyLatLng(Map<String, dynamic> pharmacy) {
    try {
      final coords = pharmacy['location']['coordinates'] as List;
      return LatLng(
        (coords[1] as num).toDouble(),
        (coords[0] as num).toDouble(),
      );
    } catch (_) {
      return _center;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _insuranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0ABFBC),
                  Color(0xFF0891B2),
                  Color(0xFF1B3A6B),
                ],
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nearby Pharmacies',
                              style: GoogleFonts.workSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: Colors.white70,
                                  size: 13,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _position != null
                                      ? 'Kigali, Rwanda'
                                      : 'Getting location...',
                                  style: GoogleFonts.workSans(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _showMap = !_showMap),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _showMap
                                      ? Icons.list_rounded
                                      : Icons.map_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _showMap ? 'List' : 'Map',
                                  style: GoogleFonts.workSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Name / area search
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.search_rounded,
                            color: AppColors.grey400,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (v) => setState(() => _query = v),
                              style: GoogleFonts.workSans(
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search pharmacy name or area...',
                                hintStyle: GoogleFonts.workSans(
                                  fontSize: 14,
                                  color: AppColors.textHint,
                                ),
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
                                setState(() => _query = '');
                              },
                              child: const Icon(
                                Icons.close_rounded,
                                color: AppColors.grey400,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Insurance filter row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.health_and_safety_rounded,
                                  color: AppColors.grey400,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _insuranceCtrl,
                                    onSubmitted: (_) => _searchByInsurance(),
                                    style: GoogleFonts.workSans(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Filter by insurance (e.g. RSSB)...',
                                      hintStyle: GoogleFonts.workSans(
                                        fontSize: 13,
                                        color: AppColors.textHint,
                                      ),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                if (_activeInsurance.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      _insuranceCtrl.clear();
                                      setState(() => _activeInsurance = '');
                                      _fetchWithPosition();
                                    },
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.grey400,
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _searchByInsurance,
                          child: Container(
                            height: 44,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: _activeInsurance.isNotEmpty
                                  ? const Color(0xFF0ABFBC)
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                'Search',
                                style: GoogleFonts.workSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Tab bar
                    Container(
                      height: 40,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: AppColors.teal,
                        unselectedLabelColor: Colors.white,
                        labelStyle: GoogleFonts.workSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        unselectedLabelStyle: GoogleFonts.workSans(
                          fontSize: 12,
                        ),
                        tabs: const [
                          Tab(text: 'All'),
                          Tab(text: 'Open Now'),
                          Tab(text: 'Delivery'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Stats pills ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _StatPill(
                  icon: Icons.local_pharmacy_rounded,
                  label: '${_pharmacies.length} Total',
                  color: AppColors.teal,
                ),
                const SizedBox(width: 8),
                if (_activeInsurance.isNotEmpty)
                  _StatPill(
                    icon: Icons.health_and_safety_rounded,
                    label: _activeInsurance,
                    color: const Color(0xFF7C3AED),
                  )
                else ...[
                  _StatPill(
                    icon: Icons.check_circle_rounded,
                    label: '${_pharmacies.where((p) => (p['is_open'] ?? p['open']) == true).length} Open',
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  _StatPill(
                    icon: Icons.delivery_dining_rounded,
                    label: '${_pharmacies.where((p) => (p['has_delivery'] ?? p['delivery']) == true).length} Delivery',
                    color: AppColors.primary,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Map or List ───────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? AppLoader()
                : _showMap
                ? _buildMap()
                : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.rapidsave.rapidsave',
              maxZoom: 19,
            ),

            // User location marker
            if (_position != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: _center,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.teal,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withOpacity(0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_pin_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),

            // Pharmacy markers
            MarkerLayer(
              markers: _filtered.map((pharmacy) {
                final latLng = _getPharmacyLatLng(pharmacy);
                final isOpen = pharmacy['is_open'] as bool? ?? pharmacy['open'] as bool? ?? false;
                return Marker(
                  point: latLng,
                  width: 140,
                  height: 60,
                  child: GestureDetector(
                    onTap: () => context.push('/pharmacy/${pharmacy['_id']}'),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isOpen ? AppColors.teal : AppColors.grey500,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            pharmacy['name'] as String,
                            style: GoogleFonts.workSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        CustomPaint(
                          size: const Size(12, 8),
                          painter: _TrianglePainter(
                            color: isOpen ? AppColors.teal : AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // My location button
        Positioned(
          bottom: 16,
          right: 16,
          child: GestureDetector(
            onTap: () {
              if (_position != null) {
                _mapController.move(_center, 14);
              } else {
                _getLocationAndFetch();
              }
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.my_location_rounded,
                color: AppColors.teal,
                size: 24,
              ),
            ),
          ),
        ),

        // Pharmacies count badge
        Positioned(
          top: 12,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
              ],
            ),
            child: Text(
              '${_filtered.length} pharmacies shown',
              style: GoogleFonts.workSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_pharmacy_outlined,
              size: 64,
              color: AppColors.grey300,
            ),
            const SizedBox(height: 16),
            Text(
              'No pharmacies found',
              style: GoogleFonts.workSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _getLocationAndFetch,
      color: AppColors.teal,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => _PharmacyCard(
          pharmacy: _filtered[i],
          onTap: () => context.push('/pharmacy/${_filtered[i]['_id']}'),
        ),
      ),
    );
  }
}

// ── Triangle painter ──────────────────────────────────────────────────────────
class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Stat pill ─────────────────────────────────────────────────────────────────
class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.workSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pharmacy card ─────────────────────────────────────────────────────────────
class _PharmacyCard extends StatelessWidget {
  final Map<String, dynamic> pharmacy;
  final VoidCallback onTap;

  const _PharmacyCard({required this.pharmacy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOpen = pharmacy['is_open'] as bool? ?? pharmacy['open'] as bool? ?? false;
    final hasDelivery = pharmacy['has_delivery'] as bool? ?? pharmacy['delivery'] as bool? ?? false;
    final distance = pharmacy['distance_km'] ?? pharmacy['distance'];
    final distStr = distance != null
        ? '${(distance as num).toStringAsFixed(1)}km'
        : '';
    final insurances = (pharmacy['accepted_insurances'] as List<dynamic>?)
        ?.whereType<String>()
        .where((s) => s.isNotEmpty)
        .take(3)
        .toList() ?? [];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: isOpen ? AppColors.tealLight : AppColors.grey100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.local_pharmacy_rounded,
                      color: isOpen ? AppColors.teal : AppColors.grey400,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                pharmacy['name'] as String? ?? '',
                                style: GoogleFonts.workSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFFBBC05),
                                  size: 14,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${pharmacy['rating'] ?? ''}',
                                  style: GoogleFonts.workSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  ' (${pharmacy['reviews'] ?? 0})',
                                  style: GoogleFonts.workSans(
                                    fontSize: 11,
                                    color: AppColors.textHint,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 12,
                              color: AppColors.grey400,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                pharmacy['address'] as String? ?? '',
                                style: GoogleFonts.workSans(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isOpen
                                    ? AppColors.successLight
                                    : AppColors.dangerLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isOpen
                                          ? AppColors.success
                                          : AppColors.danger,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isOpen ? 'Open' : 'Closed',
                                    style: GoogleFonts.workSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isOpen
                                          ? AppColors.success
                                          : AppColors.danger,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (distStr.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.grey100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  distStr,
                                  style: GoogleFonts.workSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.grey500,
                                  ),
                                ),
                              ),
                            ],

                            if (hasDelivery) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryPale,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.delivery_dining_rounded,
                                      size: 10,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Delivery',
                                      style: GoogleFonts.workSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom row
            Container(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 13, color: AppColors.grey400),
                      const SizedBox(width: 4),
                      Text(pharmacy['hours'] as String? ?? '', style: GoogleFonts.workSans(fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(width: 12),
                      const Icon(Icons.medication_rounded, size: 13, color: AppColors.grey400),
                      const SizedBox(width: 4),
                      Text('${pharmacy['medicines_count'] ?? 0} medicines', style: GoogleFonts.workSans(fontSize: 11, color: AppColors.textSecondary)),
                      const Spacer(),
                      GestureDetector(
                        onTap: onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(20)),
                          child: Text('View →', style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  if (insurances.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: insurances.map((ins) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE9FE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.health_and_safety_rounded, size: 10, color: Color(0xFF7C3AED)),
                          const SizedBox(width: 3),
                          Text(ins, style: GoogleFonts.workSans(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF7C3AED))),
                        ]),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
