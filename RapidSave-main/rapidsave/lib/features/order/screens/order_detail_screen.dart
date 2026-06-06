import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/delivery_service.dart';
import '../../../data/services/order_service.dart';
import '../../../data/services/conversation_service.dart';
import '../../../shared/widgets/app_loader.dart';

class OrderDetailScreen extends StatefulWidget {
  final String id;
  const OrderDetailScreen({super.key, required this.id});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _orderService = OrderService();
  final _conversationService = ConversationService();
  final _deliveryService = DeliveryService();

  Map<String, dynamic>? _order;
  bool _loading = true;
  bool _chatLoading = false;
  bool _trackLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });
    try {
      final o = await _orderService.getOrderById(widget.id);
      if (mounted) setState(() => _order = o);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openChat() async {
    setState(() => _chatLoading = true);
    try {
      final conv = await _conversationService.getOrCreateConversation(widget.id);
      if (conv == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open chat. Please try again.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        return;
      }
      final convId = conv['_id'] as String? ?? '';
      if (mounted && convId.isNotEmpty) context.push('/chat/$convId');
    } catch (_) {
    } finally {
      if (mounted) setState(() => _chatLoading = false);
    }
  }

  Future<void> _trackDelivery() async {
    setState(() => _trackLoading = true);
    try {
      final delivery = await _deliveryService.getDeliveryByOrder(widget.id);
      if (delivery == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery tracking not available yet.')),
        );
        return;
      }
      final deliveryId = delivery['_id'] as String? ?? '';
      if (mounted && deliveryId.isNotEmpty) context.push('/delivery/$deliveryId');
    } catch (_) {
    } finally {
      if (mounted) setState(() => _trackLoading = false);
    }
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    return DateFormat('MMM d, yyyy • h:mm a').format(dt.toLocal());
  }

  String _orderId(String id) =>
      id.length > 8 ? 'ORD-${id.substring(id.length - 6).toUpperCase()}' : id;

  String _formatTotal(int amount) => amount.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(backgroundColor: AppColors.scaffold, body: AppLoader());
    if (_error != null || _order == null) {
      return Scaffold(
        backgroundColor: AppColors.scaffold,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.arrow_back_rounded, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(child: Center(child: Text('Failed to load order'))),
            ],
          ),
        ),
      );
    }

    final order = _order!;
    final status = order['status'] as String? ?? 'pending';
    // payment is nested: order.payment.status
    final payment = order['payment'] as Map<String, dynamic>?;
    final paymentStatus = payment?['status'] as String? ?? 'unpaid';
    final isDelivery = order['type'] == 'delivery';
    // backend populates pharmacy_id, not pharmacy
    final pharmacy = (order['pharmacy_id'] ?? order['pharmacy']) as Map<String, dynamic>?;
    final items = order['items'] as List<dynamic>? ?? [];
    final total = (order['total_amount'] as num?)?.toInt() ?? 0;
    final rawId = order['_id'] as String? ?? widget.id;

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
                            const SizedBox(width: 12),
                            Text('Order Details', style: GoogleFonts.workSans(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
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
                                    width: 52, height: 52,
                                    decoration: BoxDecoration(color: _statusBg(status), borderRadius: BorderRadius.circular(14)),
                                    child: Icon(_statusIcon(status), color: _statusColor(status), size: 26),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_orderId(rawId), style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                        Text(_formatDate(order['createdAt'] as String?), style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(color: _statusBg(status), borderRadius: BorderRadius.circular(20)),
                                    child: Text(_statusLabel(status), style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w700, color: _statusColor(status))),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Divider(color: AppColors.divider),
                              const SizedBox(height: 10),
                              _OrderProgress(status: status),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Pharmacy ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _DetailCard(
                  title: 'Pharmacy',
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.teal, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pharmacy?['name'] as String? ?? 'Pharmacy', style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            if ((pharmacy?['address'] as String?)?.isNotEmpty == true)
                              Text(pharmacy!['address'] as String, style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Items ─────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _DetailCard(
                  title: 'Medicines Ordered',
                  child: Column(
                    children: [
                      ...items.map((item) {
                        final m = item as Map<String, dynamic>;
                        // inventory_id is populated; inside it medicine_id is also populated
                        final inv = (m['inventory_id'] ?? m['inventory']) as Map<String, dynamic>?;
                        final med = (inv?['medicine_id'] ?? inv?['medicine']) as Map<String, dynamic>?;
                        final name = med?['name'] as String? ?? 'Medicine';
                        final qty = (m['quantity'] as num?)?.toInt() ?? 1;
                        // unit_price is the price at time of order
                        final price = (m['unit_price'] ?? m['price'] as num?)?.toInt() ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.medication_rounded, color: AppColors.teal, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    Text('Qty: $qty', style: GoogleFonts.workSans(fontSize: 11, color: AppColors.textSecondary)),
                                  ],
                                ),
                              ),
                              if (price > 0)
                                Text('${_formatTotal(price)} RWF', style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            ],
                          ),
                        );
                      }),
                      if (items.isNotEmpty) const Divider(color: AppColors.divider),
                      Row(
                        children: [
                          Text('Total', style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                          const Spacer(),
                          Text('${_formatTotal(total)} RWF', style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.teal)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Delivery & Payment ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _DetailCard(
                        title: 'Order Type',
                        child: Row(
                          children: [
                            Icon(
                              isDelivery ? Icons.delivery_dining_rounded : Icons.store_rounded,
                              color: AppColors.teal,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(isDelivery ? 'Home\nDelivery' : 'Pick\nup', style: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DetailCard(
                        title: 'Payment',
                        child: Row(
                          children: [
                            Icon(Icons.payment_rounded, color: _paymentColor(paymentStatus), size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_paymentLabel(paymentStatus), style: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w600, color: _paymentColor(paymentStatus))),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Notes ─────────────────────────────────────────────────────────
            if ((order['notes'] as String?)?.isNotEmpty == true)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: _DetailCard(
                    title: 'Notes',
                    child: Text(order['notes'] as String, style: GoogleFonts.workSans(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                  ),
                ),
              ),

            // ── Actions ───────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  children: [
                    if (paymentStatus == 'unpaid' || paymentStatus == 'rejected')
                      GestureDetector(
                        onTap: () => context.push('/payment-proof/${widget.id}'),
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(16)),
                          child: Center(child: Text('Upload Payment Proof', style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white))),
                        ),
                      ),
                    // Track Delivery button — shows for delivery orders that are in progress
                    if (isDelivery && (status == 'confirmed' || status == 'ready' || status == 'completed')) ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _trackLoading ? null : _trackDelivery,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF0ABFBC), Color(0xFF0891B2)]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: _trackLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.delivery_dining_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Track Delivery', style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                                  ]),
                          ),
                        ),
                      ),
                    ],
                    if (status == 'confirmed' || status == 'ready') ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _chatLoading ? null : _openChat,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.primaryPale,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Center(
                            child: _chatLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                                : Text('Chat with Pharmacy', style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          ),
                        ),
                      ),
                    ],
                    if (status == 'pending') ...[
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('Cancel Order', style: GoogleFonts.workSans(fontWeight: FontWeight.w700)),
                              content: Text('Are you sure you want to cancel this order?', style: GoogleFonts.workSans()),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                                TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Yes, Cancel', style: GoogleFonts.workSans(color: AppColors.danger))),
                              ],
                            ),
                          );
                          if (confirm == true && mounted) {
                            try {
                              await OrderService().cancelOrder(widget.id);
                              await _fetch();
                            } catch (_) {}
                          }
                        },
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.dangerLight,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                          ),
                          child: Center(child: Text('Cancel Order', style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.danger))),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

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
      case 'ready': return 'Ready';
      case 'completed': return 'Completed';
      case 'cancelled': return 'Cancelled';
      default: return s;
    }
  }

  Color _paymentColor(String p) {
    switch (p) {
      case 'verified': return AppColors.success;
      case 'pending_verification': return AppColors.accent;
      case 'rejected': return AppColors.danger;
      default: return AppColors.grey400;
    }
  }

  String _paymentLabel(String p) {
    switch (p) {
      case 'verified': return 'Verified';
      case 'pending_verification': return 'Pending\nVerification';
      case 'rejected': return 'Rejected';
      default: return 'Unpaid';
    }
  }
}

// ── Order progress ────────────────────────────────────────────────────────────
class _OrderProgress extends StatelessWidget {
  final String status;
  const _OrderProgress({required this.status});

  @override
  Widget build(BuildContext context) {
    const steps = ['Pending', 'Confirmed', 'Ready', 'Completed'];
    const statusMap = {'pending': 0, 'confirmed': 1, 'ready': 2, 'completed': 3, 'cancelled': -1};
    final currentStep = statusMap[status] ?? 0;

    if (status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(10)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel_rounded, color: AppColors.danger, size: 16),
            const SizedBox(width: 6),
            Text('This order was cancelled', style: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.danger)),
          ],
        ),
      );
    }

    return Row(
      children: steps.asMap().entries.map((e) {
        final i = e.key;
        final step = e.value;
        final done = i <= currentStep;
        final active = i == currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? AppColors.teal : AppColors.grey100,
                        border: Border.all(color: done ? AppColors.teal : AppColors.border, width: active ? 2 : 1),
                      ),
                      child: Icon(done ? Icons.check_rounded : Icons.circle, color: done ? Colors.white : AppColors.grey300, size: done ? 14 : 8),
                    ),
                    const SizedBox(height: 4),
                    Text(step, style: GoogleFonts.workSans(fontSize: 9, fontWeight: active ? FontWeight.w700 : FontWeight.w400, color: done ? AppColors.teal : AppColors.textHint), textAlign: TextAlign.center),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(height: 2, margin: const EdgeInsets.only(bottom: 18), color: i < currentStep ? AppColors.teal : AppColors.grey200),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Detail card ───────────────────────────────────────────────────────────────
class _DetailCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _DetailCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
