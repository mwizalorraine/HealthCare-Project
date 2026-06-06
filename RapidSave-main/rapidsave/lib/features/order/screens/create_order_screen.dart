import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/order_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../core/utils/app_utils.dart';

class CreateOrderScreen extends ConsumerStatefulWidget {
  final String pharmacyId;
  final String? inventoryId;
  final String? medicineId;
  final String? medicineName;
  final String? medicineCategory;
  final int? medicinePrice;
  final int? stockQuantity;

  const CreateOrderScreen({
    super.key,
    required this.pharmacyId,
    this.inventoryId,
    this.medicineId,
    this.medicineName,
    this.medicineCategory,
    this.medicinePrice,
    this.stockQuantity,
  });

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  final _orderService = OrderService();
  final _notesCtrl = TextEditingController();

  int _qty = 1;
  bool _delivery = false;
  bool _submitting = false;

  int get _total => (_qty * (widget.medicinePrice ?? 0));

  String _formatPrice(int price) => price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  IconData _categoryIcon(String? cat) {
    switch (cat?.toLowerCase()) {
      case 'pain':
      case 'pain relief':
        return Icons.medication_rounded;
      case 'antibiotic':
        return Icons.coronavirus_rounded;
      case 'allergy':
      case 'skin':
        return Icons.spa_rounded;
      case 'cardiac':
      case 'heart':
        return Icons.favorite_rounded;
      case 'diabetic':
      case 'sugar':
        return Icons.bloodtype_rounded;
      default:
        return Icons.medication_liquid_rounded;
    }
  }

  Color _categoryColor(String? cat) {
    switch (cat?.toLowerCase()) {
      case 'pain':
      case 'pain relief':
        return AppColors.teal;
      case 'antibiotic':
        return AppColors.primary;
      case 'allergy':
      case 'skin':
        return AppColors.danger;
      case 'cardiac':
      case 'heart':
        return const Color(0xFF9F1239);
      case 'diabetic':
      case 'sugar':
        return const Color(0xFF92400E);
      default:
        return AppColors.secondary;
    }
  }

  Future<void> _placeOrder() async {
    final inventoryId = widget.inventoryId;
    if (inventoryId == null || inventoryId.isEmpty) {
      AppUtils.showError('No medicine inventory selected. Please search and select a medicine first.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final order = await _orderService.createOrder(
        pharmacyId: widget.pharmacyId,
        items: [
          {'inventory_id': inventoryId, 'quantity': _qty},
        ],
        delivery: _delivery,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (!mounted) return;
      final orderId = order['_id'] ?? order['id'] ?? '';
      AppUtils.showSuccess('Order placed successfully!');
      context.pushReplacement('/orders/$orderId');
    } catch (e) {
      if (!mounted) return;
      AppUtils.showError(e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    final color = _categoryColor(widget.medicineCategory);
    final price = widget.medicinePrice ?? 0;
    final hasInventory = widget.inventoryId != null && widget.inventoryId!.isNotEmpty;

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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  children: [
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Place Order',
                              style: GoogleFonts.workSans(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            Text(
                              'Review and confirm your order',
                              style: GoogleFonts.workSans(fontSize: 12, color: Colors.white70),
                            ),
                          ],
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
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(_categoryIcon(widget.medicineCategory), color: color, size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.medicineName ?? 'Medicine',
                                  style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  widget.medicineCategory ?? '',
                                  style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  price > 0 ? '${_formatPrice(price)} RWF / unit' : 'Price set by pharmacy',
                                  style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.teal),
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

          // ── Body ──────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, padding.bottom + 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!hasInventory)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.accent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Please select a medicine from a pharmacy first to place an order.',
                              style: GoogleFonts.workSans(fontSize: 12, color: AppColors.accent),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (hasInventory) ...[
                    // ── Quantity control ──────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.shopping_cart_rounded, color: AppColors.teal, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Text('Quantity', style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: _qty > 1 ? () => setState(() => _qty--) : null,
                                child: Container(
                                  width: 52, height: 52,
                                  decoration: BoxDecoration(
                                    color: _qty > 1 ? AppColors.tealLight : AppColors.grey100,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: _qty > 1 ? AppColors.teal.withOpacity(0.3) : AppColors.border),
                                  ),
                                  child: Icon(Icons.remove_rounded, size: 24, color: _qty > 1 ? AppColors.teal : AppColors.grey300),
                                ),
                              ),
                              Container(
                                width: 100,
                                alignment: Alignment.center,
                                child: Text('$_qty', style: GoogleFonts.workSans(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                              ),
                              GestureDetector(
                                onTap: (widget.stockQuantity != null && _qty >= widget.stockQuantity!)
                                    ? null
                                    : () => setState(() => _qty++),
                                child: Container(
                                  width: 52, height: 52,
                                  decoration: BoxDecoration(
                                    color: (widget.stockQuantity != null && _qty >= widget.stockQuantity!)
                                        ? AppColors.grey200
                                        : AppColors.teal,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: (widget.stockQuantity != null && _qty >= widget.stockQuantity!)
                                        ? []
                                        : [BoxShadow(color: AppColors.teal.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
                                  ),
                                  child: Icon(Icons.add_rounded, size: 24, color: (widget.stockQuantity != null && _qty >= widget.stockQuantity!) ? AppColors.grey400 : Colors.white),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (widget.stockQuantity != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _qty >= (widget.stockQuantity ?? 0) ? AppColors.accentLight : AppColors.tealLight,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${widget.stockQuantity} unit${widget.stockQuantity == 1 ? '' : 's'} available in stock',
                                style: GoogleFonts.workSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _qty >= (widget.stockQuantity ?? 0) ? AppColors.accent : AppColors.tealDark,
                                ),
                              ),
                            ),
                          if (price > 0) ...[
                            const SizedBox(height: 16),
                            Text(
                              '${_formatPrice(price)} RWF × $_qty = ${_formatPrice(_total)} RWF',
                              style: GoogleFonts.workSans(fontSize: 13, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Delivery option ───────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.delivery_dining_rounded, color: AppColors.teal, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Text('Delivery Option', style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _DeliveryOption(
                            label: 'Pickup at Pharmacy',
                            subtitle: 'Come pick up your order in person',
                            icon: Icons.storefront_rounded,
                            isSelected: !_delivery,
                            onTap: () => setState(() => _delivery = false),
                          ),
                          const SizedBox(height: 10),
                          _DeliveryOption(
                            label: 'Home Delivery',
                            subtitle: 'Rider delivers to your address',
                            icon: Icons.delivery_dining_rounded,
                            isSelected: _delivery,
                            onTap: () => setState(() => _delivery = true),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Payment summary ───────────────────────────────────
                    if (price > 0)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.payment_rounded, color: AppColors.teal, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Text('Payment Summary', style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _SummaryRow(label: widget.medicineName ?? 'Medicine', value: '${_formatPrice(price)} RWF'),
                            const SizedBox(height: 6),
                            _SummaryRow(label: 'Quantity', value: '× $_qty'),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(color: AppColors.divider),
                            ),
                            Row(
                              children: [
                                Text('Total Amount', style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                const Spacer(),
                                Text('${_formatPrice(_total)} RWF', style: GoogleFonts.workSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.teal)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline_rounded, color: AppColors.teal, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Payment via MoMo after order confirmation. Upload proof to complete.',
                                      style: GoogleFonts.workSans(fontSize: 11, color: AppColors.tealDark, height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),

                    // ── Notes ─────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.notes_rounded, color: AppColors.teal, size: 18),
                              ),
                              const SizedBox(width: 10),
                              Text('Instructions (optional)', style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesCtrl,
                            maxLines: 3,
                            style: GoogleFonts.workSans(fontSize: 14, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'e.g. Generic brands okay, need urgent delivery, allergic to...',
                              hintStyle: GoogleFonts.workSans(fontSize: 13, color: AppColors.textHint),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Place order button ─────────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 12, 20, padding.bottom + 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: Row(
          children: [
            if (price > 0) ...[
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total', style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textSecondary)),
                  Text('${_formatPrice(_total)} RWF', style: GoogleFonts.workSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.teal)),
                ],
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: AppButton(
                text: hasInventory ? 'Place Order →' : 'Select a Medicine First',
                onPressed: hasInventory ? _placeOrder : null,
                isLoading: _submitting,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Delivery option widget ──────────────────────────────────────────────────────
class _DeliveryOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DeliveryOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.tealLight : AppColors.grey50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.teal : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.teal : AppColors.grey200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : AppColors.grey400, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? AppColors.tealDark : AppColors.textPrimary)),
                  Text(subtitle, style: GoogleFonts.workSans(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Summary row ───────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: GoogleFonts.workSans(fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text(value, style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }
}
