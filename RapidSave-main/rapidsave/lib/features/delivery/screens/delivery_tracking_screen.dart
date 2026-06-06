import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../data/services/delivery_service.dart';
import '../../../data/services/order_service.dart';
import '../../../data/services/socket_service.dart';
import '../../../shared/widgets/app_loader.dart';

class DeliveryTrackingScreen extends ConsumerStatefulWidget {
  final String deliveryId;
  const DeliveryTrackingScreen({super.key, required this.deliveryId});

  @override
  ConsumerState<DeliveryTrackingScreen> createState() => _DeliveryTrackingScreenState();
}

class _DeliveryTrackingScreenState extends ConsumerState<DeliveryTrackingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;
  final _deliveryService = DeliveryService();
  final _orderService   = OrderService();
  final _socketService  = SocketService();
  final _mapController  = MapController();

  Map<String, dynamic>? _delivery;
  bool _loading = true;
  bool _confirming = false;
  double? _driverLat;
  double? _driverLng;
  Timer? _refreshTimer;
  bool _mapReady = false;

  // Rwanda default center (Kigali)
  static const _defaultLat = -1.9441;
  static const _defaultLng = 30.0619;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _fetch();
    _setupSocket();
    // Refresh every 20 seconds as fallback
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) => _fetch());
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _refreshTimer?.cancel();
    _socketService.leaveDelivery(widget.deliveryId);
    _socketService.off('driver_location');
    _socketService.off('delivery_status_update');
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final d = await _deliveryService.getDeliveryById(widget.deliveryId);
      if (!mounted) return;
      setState(() {
        _delivery = d;
        // Extract driver coords if provided by backend
        final lat = _parseDouble(d?['rider_lat'] ?? d?['riderLat']);
        final lng = _parseDouble(d?['rider_lng'] ?? d?['riderLng']);
        if (lat != null && lng != null) {
          _driverLat = lat;
          _driverLng = lng;
          _animateMapToDriver();
        }
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  void _setupSocket() {
    _socketService.joinDelivery(widget.deliveryId);
    _socketService.onDriverLocation((data) {
      if (!mounted) return;
      final lat = _parseDouble(data['lat']);
      final lng = _parseDouble(data['lng']);
      if (lat != null && lng != null) {
        setState(() {
          _driverLat = lat;
          _driverLng = lng;
        });
        _animateMapToDriver();
      }
    });
    _socketService.onDeliveryStatusUpdate((data) {
      if (!mounted) return;
      final status = data['status'] as String?;
      if (status != null && _delivery != null) {
        // Update locally immediately then re-fetch full data
        setState(() => _delivery!['status'] = status);
        _fetch(); // get latest data from backend
      }
    });
  }

  void _animateMapToDriver() {
    if (_driverLat != null && _driverLng != null && _mapReady) {
      try {
        _mapController.move(LatLng(_driverLat!, _driverLng!), 15.0);
      } catch (_) {}
    }
  }

  List<Map<String, dynamic>> _buildSteps(String status, AppL10n l10n) {
    final steps = [
      {'key': 'assigned',   'title': l10n.stepAssigned,   'subtitle': l10n.stepAssignedSub,   'icon': Icons.check_circle_rounded},
      {'key': 'in_transit', 'title': l10n.stepInTransit,  'subtitle': l10n.stepInTransitSub,  'icon': Icons.delivery_dining_rounded},
      {'key': 'delivered',  'title': l10n.stepDelivered,  'subtitle': l10n.stepDeliveredSub,  'icon': Icons.home_rounded},
    ];
    const order = ['assigned', 'in_transit', 'delivered'];
    final ci = order.indexOf(status);

    return steps.asMap().entries.map((e) {
      final i = e.key;
      final s = Map<String, dynamic>.from(e.value as Map);
      s['done']   = ci > 0 && i < ci;
      s['active'] = ci >= 0 && i == ci;
      return s;
    }).toList();
  }

  String _formatEta(String? raw, AppL10n l10n) {
    if (raw == null) return l10n.calculating;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return l10n.calculating;
    final diff = dt.toLocal().difference(DateTime.now());
    if (diff.isNegative) return l10n.arrivingSoon;
    if (diff.inMinutes < 60) return '~${diff.inMinutes} min';
    return DateFormat('h:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: AppColors.scaffold, body: AppLoader());

    final l10n = ref.watch(appL10nProvider);
    final delivery = _delivery;
    final status = delivery?['status'] as String? ?? 'assigned';
    final riderName = delivery?['rider_name'] as String? ?? delivery?['riderName'] as String? ?? 'Rider';
    final riderPhone = delivery?['rider_phone'] as String? ?? delivery?['riderPhone'] as String?;
    final address = delivery?['address'] as String? ?? '';
    final estimatedAt = delivery?['estimated_at'] as String? ?? delivery?['estimatedAt'] as String?;
    final conversationId = delivery?['conversation_id'] as String? ?? delivery?['conversationId'] as String?;
    final steps = _buildSteps(status, l10n);
    final isDelivered = status == 'delivered';

    final centerLat = _driverLat ?? _defaultLat;
    final centerLng = _driverLng ?? _defaultLng;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: AppColors.teal,
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
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
                        // Top bar
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n.trackDelivery,
                                style: GoogleFonts.workSans(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                            ),
                            if (!isDelivered)
                              AnimatedBuilder(
                                animation: _pulseAnim,
                                builder: (_, child) => Transform.scale(scale: _pulseAnim.value, child: child),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF4ADE80)),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(l10n.liveLabel, style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Rider card
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.tealLight),
                                child: const Icon(Icons.person_rounded, color: AppColors.teal, size: 28),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(riderName, style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                    Text(l10n.yourRider, style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  if (riderPhone != null)
                                    _ActionBtn(
                                      icon: Icons.phone_rounded,
                                      color: AppColors.teal,
                                      bgColor: AppColors.tealLight,
                                      onTap: () async {
                                        final uri = Uri.parse('tel:$riderPhone');
                                        if (await canLaunchUrl(uri)) launchUrl(uri);
                                      },
                                    ),
                                  if (conversationId != null) ...[
                                    const SizedBox(width: 8),
                                    _ActionBtn(
                                      icon: Icons.chat_bubble_rounded,
                                      color: AppColors.primary,
                                      bgColor: AppColors.primaryPale,
                                      onTap: () => context.push('/chat/$conversationId'),
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
                ),
              ),
            ),

            // ── Real-time map ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 220,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: LatLng(centerLat, centerLng),
                            initialZoom: _driverLat != null ? 15.0 : 13.0,
                            minZoom: 3.0,
                            maxZoom: 19.0,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.all,
                            ),
                            onMapReady: () {
                              if (mounted) setState(() => _mapReady = true);
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.rapidsave.app',
                              maxZoom: 19,
                            ),
                            MarkerLayer(
                              markers: [
                                if (_driverLat != null && _driverLng != null)
                                  Marker(
                                    point: LatLng(_driverLat!, _driverLng!),
                                    width: 48,
                                    height: 48,
                                    child: AnimatedBuilder(
                                      animation: _pulseAnim,
                                      builder: (_, child) => Transform.scale(scale: _pulseAnim.value, child: child),
                                      child: _DriverMarker(),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        // Map overlay: label
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.map_rounded, size: 13, color: AppColors.teal),
                                const SizedBox(width: 5),
                                Text(
                                  _driverLat != null ? l10n.riderLocation : 'Live Map',
                                  style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Zoom controls
                        if (_mapReady)
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: Column(
                              children: [
                                _ZoomButton(
                                  icon: Icons.add_rounded,
                                  onTap: () {
                                    final cam = _mapController.camera;
                                    _mapController.move(cam.center, (cam.zoom + 1).clamp(3.0, 19.0));
                                  },
                                ),
                                const SizedBox(height: 4),
                                _ZoomButton(
                                  icon: Icons.remove_rounded,
                                  onTap: () {
                                    final cam = _mapController.camera;
                                    _mapController.move(cam.center, (cam.zoom - 1).clamp(3.0, 19.0));
                                  },
                                ),
                              ],
                            ),
                          ),
                        if (_driverLat == null)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withOpacity(0.04),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.delivery_dining_rounded, size: 40, color: AppColors.teal),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Waiting for driver location...',
                                      style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── ETA card ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0ABFBC), Color(0xFF1B3A6B)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.estimatedArrival, style: GoogleFonts.workSans(fontSize: 12, color: Colors.white70)),
                          Text(
                            _formatEta(estimatedAt, l10n),
                            style: GoogleFonts.workSans(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                          Text(
                            isDelivered ? l10n.orderDelivered : l10n.trackingLive,
                            style: GoogleFonts.workSans(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                      const Spacer(),
                      AnimatedBuilder(
                        animation: _pulseAnim,
                        builder: (_, child) => Transform.scale(scale: _pulseAnim.value, child: child),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                          ),
                          child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 32),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Delivery address ──────────────────────────────────────────────
            if (address.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.location_on_rounded, color: AppColors.danger, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.deliveryAddress, style: GoogleFonts.workSans(fontSize: 11, color: AppColors.textHint)),
                              Text(address, style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Progress tracker ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.deliveryProgress, style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: steps.asMap().entries.map((e) {
                          final i = e.key;
                          final step = e.value;
                          final isDone = step['done'] as bool;
                          final isActive = step['active'] as bool;
                          final isLast = i == steps.length - 1;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  AnimatedBuilder(
                                    animation: _pulseAnim,
                                    builder: (_, child) => Transform.scale(
                                      scale: isActive ? _pulseAnim.value : 1.0,
                                      child: child,
                                    ),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isDone
                                            ? AppColors.success
                                            : isActive
                                                ? AppColors.teal
                                                : AppColors.grey100,
                                        border: isActive
                                            ? Border.all(color: AppColors.teal.withOpacity(0.35), width: 4)
                                            : null,
                                      ),
                                      child: Icon(
                                        isDone ? Icons.check_rounded : step['icon'] as IconData,
                                        color: isDone || isActive ? Colors.white : AppColors.grey400,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  if (!isLast)
                                    Container(
                                      width: 2,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: isDone
                                              ? [AppColors.success, AppColors.success.withOpacity(0.4)]
                                              : isActive
                                                  ? [AppColors.teal, AppColors.grey200]
                                                  : [AppColors.grey200, AppColors.grey200],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 6, bottom: 24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        step['title'] as String,
                                        style: GoogleFonts.workSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: isDone
                                              ? AppColors.success
                                              : isActive
                                                  ? AppColors.textPrimary
                                                  : AppColors.textHint,
                                        ),
                                      ),
                                      Text(
                                        step['subtitle'] as String,
                                        style: GoogleFonts.workSans(fontSize: 11, color: AppColors.textHint),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (isActive)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.teal,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      l10n.nowLabel,
                                      style: GoogleFonts.workSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Confirm Receipt button ────────────────────────────────────────
            if (status == 'delivered')
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: GestureDetector(
                    onTap: _confirming ? null : () async {
                      final orderId = delivery?['order_id'] as String?
                          ?? (delivery?['order'] is Map ? (delivery!['order'] as Map)['_id'] : null) as String?;
                      if (orderId == null) return;
                      setState(() => _confirming = true);
                      try {
                        await _orderService.updateOrderStatus(orderId, 'completed');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Receipt confirmed! Thank you.', style: GoogleFonts.workSans(color: Colors.white)),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                          ));
                          context.pop();
                        }
                      } catch (_) {
                        if (mounted) setState(() => _confirming = false);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF166534), Color(0xFF16A34A)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: Center(
                        child: _confirming
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                                const SizedBox(width: 10),
                                Text('I Received My Order', style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                              ]),
                      ),
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

// ── Driver marker on map ──────────────────────────────────────────────────────
class _DriverMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.teal,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [BoxShadow(color: AppColors.teal.withOpacity(0.5), blurRadius: 10, spreadRadius: 2)],
      ),
      child: const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 24),
    );
  }
}

// ── Zoom button ───────────────────────────────────────────────────────────────
class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}

// ── Action button ──────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.color, required this.bgColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
