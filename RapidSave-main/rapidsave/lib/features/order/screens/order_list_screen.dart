import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/order_service.dart';
import '../../../shared/widgets/app_loader.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _orderService = OrderService();

  List<Map<String, dynamic>> _orders = [];
  bool _loading = false;
  String? _error;

  static const _tabs = [
    {'label': 'All', 'status': null},
    {'label': 'Active', 'status': 'confirmed'},
    {'label': 'Ready', 'status': 'ready'},
    {'label': 'Done', 'status': 'completed'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _fetchOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _orderService.getMyOrders(limit: 50);
      if (mounted) setState(() => _orders = list);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final status = _tabs[_tabController.index]['status'] as String?;
    if (status == null) return _orders;
    return _orders.where((o) => o['status'] == status).toList();
  }

  int _count(String status) => _orders.where((o) => o['status'] == status).length;

  String _formatDate(String? raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today, ${DateFormat('h:mm a').format(dt.toLocal())}';
    if (diff.inDays == 1) return 'Yesterday, ${DateFormat('h:mm a').format(dt.toLocal())}';
    return DateFormat('MMM d, h:mm a').format(dt.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('My Orders', style: GoogleFonts.workSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                            Text('${_orders.length} total orders', style: GoogleFonts.workSans(fontSize: 13, color: Colors.white70)),
                          ],
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => context.push('/search'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              children: [
                                const Icon(Icons.add_rounded, color: AppColors.teal, size: 16),
                                const SizedBox(width: 4),
                                Text('New Order', style: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _HeaderStat(label: 'Pending', value: _count('pending').toString(), color: AppColors.accent),
                        const SizedBox(width: 8),
                        _HeaderStat(label: 'Active', value: _count('confirmed').toString(), color: AppColors.teal),
                        const SizedBox(width: 8),
                        _HeaderStat(label: 'Completed', value: _count('completed').toString(), color: AppColors.success),
                        const SizedBox(width: 8),
                        _HeaderStat(label: 'Cancelled', value: _count('cancelled').toString(), color: AppColors.danger),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 40,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17)),
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        labelColor: AppColors.teal,
                        unselectedLabelColor: Colors.white,
                        labelStyle: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w700),
                        unselectedLabelStyle: GoogleFonts.workSans(fontSize: 12),
                        tabs: _tabs.map((t) => Tab(text: t['label'] as String)).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Content ───────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const AppLoader()
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.grey300),
                        const SizedBox(height: 16),
                        Text('Could not load orders', style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _fetchOrders,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(20)),
                            child: Text('Retry', style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  )
                : filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.grey300),
                        const SizedBox(height: 16),
                        Text('No orders here', style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        Text('Your orders will appear here', style: GoogleFonts.workSans(fontSize: 13, color: AppColors.textHint)),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () => context.go('/search'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(20)),
                            child: Text('Browse Medicines', style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchOrders,
                    color: AppColors.teal,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _OrderCard(
                        order: filtered[i],
                        formatDate: _formatDate,
                        onTap: () => context.push('/orders/${filtered[i]['_id']}'),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _HeaderStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.workSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
            Text(label, style: GoogleFonts.workSans(fontSize: 10, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final VoidCallback onTap;
  final String Function(String?) formatDate;

  const _OrderCard({required this.order, required this.onTap, required this.formatDate});

  Color _statusColor(String s) {
    switch (s) {
      case 'pending': return AppColors.accent;
      case 'confirmed': return AppColors.teal;
      case 'ready': return AppColors.primary;
      case 'completed': return AppColors.success;
      case 'cancelled': return AppColors.danger;
      default: return AppColors.grey400;
    }
  }

  Color _statusBg(String s) {
    switch (s) {
      case 'pending': return AppColors.accentLight;
      case 'confirmed': return AppColors.tealLight;
      case 'ready': return AppColors.primaryPale;
      case 'completed': return AppColors.successLight;
      case 'cancelled': return AppColors.dangerLight;
      default: return AppColors.grey100;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'pending': return Icons.hourglass_top_rounded;
      case 'confirmed': return Icons.check_circle_rounded;
      case 'ready': return Icons.storefront_rounded;
      case 'completed': return Icons.done_all_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      default: return Icons.circle_outlined;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'pending': return 'Pending';
      case 'confirmed': return 'Confirmed';
      case 'ready': return 'Ready for Pickup';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default: return s;
    }
  }

  String _orderId(Map<String, dynamic> o) {
    final id = o['_id'] as String? ?? '';
    return id.length > 8 ? 'ORD-${id.substring(id.length - 6).toUpperCase()}' : id;
  }

  String _pharmacyName(Map<String, dynamic> o) {
    final p = o['pharmacy'];
    if (p is Map) return p['name'] as String? ?? '';
    return '';
  }

  String _itemsSummary(Map<String, dynamic> o) {
    final items = o['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return 'No items';
    final names = items.map((item) {
      if (item is Map) {
        final inv = item['inventory'];
        if (inv is Map) {
          final med = inv['medicine'];
          if (med is Map) return med['name'] as String? ?? '';
        }
      }
      return '';
    }).where((s) => s.isNotEmpty).toList();
    if (names.isEmpty) return '${items.length} item(s)';
    return names.join(', ');
  }

  int _totalAmount(Map<String, dynamic> o) => (o['total_amount'] as num?)?.toInt() ?? 0;

  String _formatTotal(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? 'pending';
    final isDelivery = order['type'] == 'delivery';
    final total = _totalAmount(order);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(color: _statusBg(status), borderRadius: BorderRadius.circular(14)),
                    child: Icon(_statusIcon(status), color: _statusColor(status), size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(_orderId(order), style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: _statusBg(status), borderRadius: BorderRadius.circular(20)),
                              child: Text(_statusLabel(status), style: GoogleFonts.workSans(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(status))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(_pharmacyName(order), style: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(_itemsSummary(order), style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textHint), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 13, color: AppColors.grey400),
                  const SizedBox(width: 4),
                  Text(formatDate(order['createdAt'] as String?), style: GoogleFonts.workSans(fontSize: 11, color: AppColors.textSecondary)),
                  if (isDelivery) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.delivery_dining_rounded, size: 13, color: AppColors.primary),
                    const SizedBox(width: 3),
                    Text('Delivery', style: GoogleFonts.workSans(fontSize: 11, color: AppColors.primary)),
                  ],
                  const Spacer(),
                  if (total > 0)
                    Text('${_formatTotal(total)} RWF', style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(width: 10),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.grey400, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
