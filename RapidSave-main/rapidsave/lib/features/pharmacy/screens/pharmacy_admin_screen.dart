import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../data/services/conversation_service.dart';
import '../../../data/services/delivery_service.dart';
import '../../../data/services/inventory_service.dart';
import '../../../data/services/medicine_service.dart';
import '../../../data/services/order_service.dart';
import '../../../data/services/pharmacy_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_loader.dart';

class PharmacyAdminScreen extends ConsumerStatefulWidget {
  /// When provided, manages this specific pharmacy.
  /// When null, shows the create-pharmacy form.
  final String? pharmacyId;
  const PharmacyAdminScreen({super.key, this.pharmacyId});

  @override
  ConsumerState<PharmacyAdminScreen> createState() => _PharmacyAdminScreenState();
}

class _PharmacyAdminScreenState extends ConsumerState<PharmacyAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  final _orderService = OrderService();
  final _pharmacyService = PharmacyService();
  final _inventoryService = InventoryService();
  final _medicineService = MedicineService();
  final _deliveryService = DeliveryService();
  final _conversationService = ConversationService();

  Map<String, dynamic>? _pharmacy;
  List<Map<String, dynamic>> _orders = [];
  List<Map<String, dynamic>> _pendingPayments = [];
  List<Map<String, dynamic>> _inventory = [];

  bool _loadingPharmacy = true;
  bool _loadingOrders = true;
  bool _loadingPayments = true;
  bool _loadingInventory = false;

  String _orderFilter = 'all';
  final _inventorySearchCtrl = TextEditingController();

  static const _orderFilters = ['all', 'pending', 'confirmed', 'ready', 'completed'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (_tabCtrl.indexIsChanging) return;
      // Load inventory lazily when tab is first opened
      if (_tabCtrl.index == 2 && _inventory.isEmpty && !_loadingInventory) {
        _loadInventory();
      }
      setState(() {});
    });
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _inventorySearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await _loadPharmacy();
    await Future.wait([_loadOrders(), _loadPendingPayments()]);
  }

  Future<void> _loadPharmacy() async {
    // No pharmacyId means "create new" mode — skip loading, show create form
    if (widget.pharmacyId == null) {
      setState(() { _pharmacy = null; _loadingPharmacy = false; });
      return;
    }

    setState(() => _loadingPharmacy = true);
    try {
      final p = await _pharmacyService.getPharmacyById(widget.pharmacyId!);
      if (!mounted) return;
      setState(() => _pharmacy = p);
      if (_tabCtrl.index == 2 && _inventory.isEmpty && !_loadingInventory) {
        _loadInventory();
      }
    } catch (e) {
      if (mounted) _showSnack('Could not load pharmacy: ${e.toString().replaceAll('Exception: ', '')}', error: true);
    } finally {
      if (mounted) setState(() => _loadingPharmacy = false);
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _loadingOrders = true);
    try {
      final pharmacyId = _pharmacy?['_id'] as String?;
      final list = await _orderService.getPharmacyOrders(
        status: _orderFilter == 'all' ? null : _orderFilter,
        pharmacyId: pharmacyId,
      );
      if (mounted) setState(() => _orders = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingOrders = false);
    }
  }

  Future<void> _loadPendingPayments() async {
    setState(() => _loadingPayments = true);
    try {
      final pharmacyId = _pharmacy?['_id'] as String?;
      final list = await _orderService.getPendingPayments(pharmacyId: pharmacyId);
      if (mounted) setState(() => _pendingPayments = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingPayments = false);
    }
  }

  Future<void> _loadInventory({String? search}) async {
    final pharmacyId = _pharmacy?['_id'] as String?;
    if (pharmacyId == null) return;
    setState(() => _loadingInventory = true);
    try {
      final list = await _inventoryService.getPharmacyInventory(pharmacyId, search: search);
      if (mounted) setState(() => _inventory = list);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingInventory = false);
    }
  }

  Future<void> _toggleOpen() async {
    try {
      final id = _pharmacy?['_id'] as String?;
      final isOpen = id != null
          ? await _pharmacyService.toggleOpenById(id)
          : await _pharmacyService.toggleOpen();
      if (mounted) {
        setState(() { if (_pharmacy != null) _pharmacy!['is_open'] = isOpen; });
        _showSnack(isOpen ? 'Pharmacy is now Open' : 'Pharmacy is now Closed');
      }
    } catch (e) {
      _showSnack('Failed to update status', error: true);
    }
  }

  Future<void> _updateOrderStatus(String orderId, String status) async {
    try {
      await _orderService.updateOrderStatus(orderId, status);
      _showSnack('Order updated to $status');
      // Reload orders (shows loader in orders tab) and silently refresh payments
      await _loadOrders();
      _silentRefreshPayments();
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''), error: true);
    }
  }

  Future<void> _verifyPayment(String orderId, String action) async {
    String? reason;
    if (action == 'reject') {
      reason = await _showRejectDialog();
      if (reason == null) return;
    }
    try {
      await _orderService.verifyPayment(orderId, action, reason: reason);
      _showSnack(action == 'verify' ? 'Payment verified ✓' : 'Payment rejected');
      // Immediately remove from list — no full-screen reload needed
      if (mounted) {
        setState(() => _pendingPayments.removeWhere((p) => p['_id'] == orderId));
      }
      // Silently refresh both lists in the background (no loading flag)
      _silentRefreshPayments();
      _loadOrders();
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''), error: true);
    }
  }

  Future<void> _silentRefreshPayments() async {
    try {
      final pharmacyId = _pharmacy?['_id'] as String?;
      final list = await _orderService.getPendingPayments(pharmacyId: pharmacyId);
      if (mounted) setState(() => _pendingPayments = list);
    } catch (_) {}
  }

  Future<String?> _showRejectDialog() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject Payment', style: GoogleFonts.workSans(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: InputDecoration(hintText: 'Reason (optional)', hintStyle: GoogleFonts.workSans(fontSize: 13)),
          style: GoogleFonts.workSans(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.workSans())),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            child: Text('Reject', style: GoogleFonts.workSans(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteInventoryItem(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Remove Item', style: GoogleFonts.workSans(fontWeight: FontWeight.w700)),
        content: Text('Remove this medicine from your inventory?', style: GoogleFonts.workSans()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.workSans())),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            child: Text('Remove', style: GoogleFonts.workSans(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _inventoryService.deleteInventoryItem(id);
      _showSnack('Item removed');
      _loadInventory();
    } catch (_) {
      _showSnack('Failed to remove item', error: true);
    }
  }

  void _showEditInventoryDialog(Map<String, dynamic> item) {
    final med = item['medicine_id'];
    final medName = (med is Map ? med['name'] : 'Medicine') as String? ?? 'Medicine';
    final medId = (med is Map ? med['_id'] : item['medicine_id']) as String? ?? '';
    final priceCtrl = TextEditingController(text: (item['price'] as num?)?.toString() ?? '');
    final qtyCtrl = TextEditingController(text: (item['quantity'] as num?)?.toString() ?? '');

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(medName, style: GoogleFonts.workSans(fontWeight: FontWeight.w700, fontSize: 15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Price (RWF)', suffixText: 'RWF', labelStyle: GoogleFonts.workSans()),
              style: GoogleFonts.workSans(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Quantity', labelStyle: GoogleFonts.workSans()),
              style: GoogleFonts.workSans(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.workSans())),
          ElevatedButton(
            onPressed: () async {
              final price = int.tryParse(priceCtrl.text.trim());
              final qty = int.tryParse(qtyCtrl.text.trim());
              if (price == null || qty == null) return;
              Navigator.pop(ctx);
              try {
                await _inventoryService.upsertInventory(medicineId: medId, price: price, quantity: qty);
                _showSnack('Inventory updated');
                _loadInventory();
              } catch (e) {
                _showSnack('Failed to update', error: true);
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            child: Text('Save', style: GoogleFonts.workSans(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Chat with patient ──────────────────────────────────────────────────────
  Future<void> _chatWithPatient(Map<String, dynamic> order) async {
    final orderId = order['_id'] as String? ?? '';
    if (orderId.isEmpty) return;

    try {
      final conv = await _conversationService.getOrCreateConversation(orderId);
      if (conv == null) {
        _showSnack('Could not open chat', error: true);
        return;
      }
      final convId = conv['_id'] as String? ?? '';
      if (convId.isEmpty) {
        _showSnack('Could not open chat', error: true);
        return;
      }
      if (mounted) context.push('/chat/$convId');
    } catch (e) {
      _showSnack(e.toString().replaceAll('Exception: ', ''), error: true);
    }
  }

  // ── Add medicine to inventory ──────────────────────────────────────────────
  // Loads ALL medicines from the catalog immediately so the admin just
  // scrolls, picks one, and enters their price + quantity. No searching
  // required — the filter bar is optional and just narrows the list.
  Future<void> _showAddMedicineDialog() async {
    final priceCtrl  = TextEditingController();
    final qtyCtrl    = TextEditingController();
    final filterCtrl = TextEditingController();

    List<Map<String, dynamic>> allMedicines = [];
    List<Map<String, dynamic>> filtered     = [];
    bool loading  = true;
    Map<String, dynamic>? selected;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {

          // Load catalog once on first build
          if (loading && allMedicines.isEmpty) {
            _medicineService.searchMedicines(limit: 100).then((list) {
              setS(() { allMedicines = list; filtered = list; loading = false; });
            }).catchError((_) {
              setS(() => loading = false);
            });
          }

          // ── Step 2: set price & quantity ──────────────────────────────
          if (selected != null) {
            final name     = selected!['name']     as String? ?? 'Medicine';
            final category = selected!['category'] as String? ?? '';
            final medId    = selected!['_id']      as String? ?? '';

            return AlertDialog(
              title: Row(
                children: [
                  GestureDetector(
                    onTap: () { priceCtrl.clear(); qtyCtrl.clear(); setS(() => selected = null); },
                    child: const Icon(Icons.arrow_back_rounded, size: 20, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(name, style: GoogleFonts.workSans(fontWeight: FontWeight.w700, fontSize: 15), overflow: TextOverflow.ellipsis)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(20)),
                      child: Text(category, style: GoogleFonts.workSans(fontSize: 11, color: AppColors.tealDark, fontWeight: FontWeight.w600)),
                    ),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    decoration: InputDecoration(labelText: 'Your Price (RWF) *', suffixText: 'RWF', labelStyle: GoogleFonts.workSans()),
                    style: GoogleFonts.workSans(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Quantity in stock *', labelStyle: GoogleFonts.workSans()),
                    style: GoogleFonts.workSans(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: GoogleFonts.workSans(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final price = int.tryParse(priceCtrl.text.trim());
                    final qty   = int.tryParse(qtyCtrl.text.trim());
                    if (price == null || price <= 0) { _showSnack('Enter a valid price', error: true); return; }
                    if (qty   == null || qty   <  0) { _showSnack('Enter a valid quantity', error: true); return; }
                    Navigator.pop(ctx);
                    try {
                      await _inventoryService.upsertInventory(medicineId: medId, price: price, quantity: qty);
                      _showSnack('$name added to inventory ✓');
                      _loadInventory();
                    } catch (e) {
                      _showSnack(e.toString().replaceAll('Exception: ', ''), error: true);
                    }
                  },
                  style: ElevatedButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
                  child: Text('Add to Inventory', style: GoogleFonts.workSans(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            );
          }

          // ── Step 1: pick from catalog ─────────────────────────────────
          return AlertDialog(
            title: Text('Medicine Catalog', style: GoogleFonts.workSans(fontWeight: FontWeight.w700, fontSize: 16)),
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Optional filter bar
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_list_rounded, size: 16, color: AppColors.grey400),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: filterCtrl,
                            onChanged: (q) {
                              final lower = q.toLowerCase();
                              setS(() {
                                filtered = q.trim().isEmpty
                                    ? allMedicines
                                    : allMedicines.where((m) =>
                                        (m['name'] as String? ?? '').toLowerCase().contains(lower) ||
                                        (m['category'] as String? ?? '').toLowerCase().contains(lower),
                                      ).toList();
                              });
                            },
                            style: GoogleFonts.workSans(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Filter by name or category...',
                              hintStyle: GoogleFonts.workSans(fontSize: 12, color: AppColors.textHint),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        if (filterCtrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () { filterCtrl.clear(); setS(() => filtered = allMedicines); },
                            child: const Icon(Icons.close_rounded, size: 14, color: AppColors.grey400),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Medicine list
                  if (loading)
                    const SizedBox(height: 120, child: Center(child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2))),
                  if (!loading && filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: Text('No medicines found', style: GoogleFonts.workSans(color: AppColors.textSecondary))),
                    ),
                  if (!loading && filtered.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 320),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final m = filtered[i];
                          final name     = m['name']     as String? ?? '';
                          final category = m['category'] as String? ?? '';
                          return GestureDetector(
                            onTap: () => setS(() => selected = m),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.grey50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(10)),
                                    child: const Icon(Icons.medication_rounded, color: AppColors.teal, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700)),
                                        if (category.isNotEmpty)
                                          Text(category, style: GoogleFonts.workSans(fontSize: 11, color: AppColors.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(20)),
                                    child: Text('Select', style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.workSans(color: AppColors.textSecondary)),
              ),
            ],
          );
        },
      ),
    );
    // Do NOT dispose controllers — the dialog close animation may still
    // reference the TextFields. Let GC handle cleanup.
  }

  // ── Create delivery or manage existing one ────────────────────────────────
  Future<void> _showCreateDeliveryDialog(Map<String, dynamic> order) async {
    final orderId = order['_id'] as String? ?? '';

    // Check if delivery already exists first
    try {
      final existing = await _deliveryService.getDeliveryByOrder(orderId);
      if (existing != null) {
        // Delivery already exists — show management options instead
        if (mounted) _showDeliveryManagementSheet(existing);
        return;
      }
    } catch (_) {}

    final addressCtrl  = TextEditingController(text: order['delivery_address'] as String? ?? '');
    final riderNameCtrl  = TextEditingController();
    final riderPhoneCtrl = TextEditingController();
    final pharmacyLat = (_pharmacy?['location']?['coordinates'] as List?)?.elementAtOrNull(1);
    final pharmacyLng = (_pharmacy?['location']?['coordinates'] as List?)?.elementAtOrNull(0);
    final latCtrl = TextEditingController(text: pharmacyLat?.toString() ?? '-1.9441');
    final lngCtrl = TextEditingController(text: pharmacyLng?.toString() ?? '30.0619');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Create Delivery', style: GoogleFonts.workSans(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Order will be dispatched for delivery', style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            TextField(controller: addressCtrl, decoration: InputDecoration(labelText: 'Delivery Address *', labelStyle: GoogleFonts.workSans()), style: GoogleFonts.workSans(), maxLines: 2),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextField(controller: latCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: InputDecoration(labelText: 'Latitude', labelStyle: GoogleFonts.workSans(fontSize: 12), isDense: true), style: GoogleFonts.workSans(fontSize: 13))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: lngCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), decoration: InputDecoration(labelText: 'Longitude', labelStyle: GoogleFonts.workSans(fontSize: 12), isDense: true), style: GoogleFonts.workSans(fontSize: 13))),
            ]),
            const Divider(height: 20),
            TextField(controller: riderNameCtrl, decoration: InputDecoration(labelText: 'Rider Name (optional)', labelStyle: GoogleFonts.workSans()), style: GoogleFonts.workSans()),
            const SizedBox(height: 10),
            TextField(controller: riderPhoneCtrl, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Rider Phone (optional)', labelStyle: GoogleFonts.workSans()), style: GoogleFonts.workSans()),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: GoogleFonts.workSans())),
          ElevatedButton(
            onPressed: () async {
              if (addressCtrl.text.trim().isEmpty) { _showSnack('Delivery address is required', error: true); return; }
              final lat = double.tryParse(latCtrl.text.trim()) ?? -1.9441;
              final lng = double.tryParse(lngCtrl.text.trim()) ?? 30.0619;
              Navigator.pop(ctx);
              try {
                await _deliveryService.createDelivery(
                  orderId: orderId,
                  address: addressCtrl.text.trim(),
                  lat: lat, lng: lng,
                  riderName:  riderNameCtrl.text.trim().isEmpty  ? null : riderNameCtrl.text.trim(),
                  riderPhone: riderPhoneCtrl.text.trim().isEmpty ? null : riderPhoneCtrl.text.trim(),
                );
                _showSnack('Delivery dispatched ✓');
                _loadOrders();
              } catch (e) {
                final msg = e.toString().replaceAll('Exception: ', '');
                // 409 means it was already created — fetch and manage it
                if (msg.contains('already exists') || msg.contains('409')) {
                  final existing = await _deliveryService.getDeliveryByOrder(orderId);
                  if (existing != null && mounted) _showDeliveryManagementSheet(existing);
                } else {
                  _showSnack(msg, error: true);
                }
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            child: Text('Dispatch', style: GoogleFonts.workSans(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Manage an existing delivery ────────────────────────────────────────────
  void _showDeliveryManagementSheet(Map<String, dynamic> delivery) {
    final deliveryId = delivery['_id'] as String? ?? '';
    final status     = delivery['status'] as String? ?? 'assigned';
    final address    = delivery['address'] as String? ?? '';
    final riderName  = delivery['rider_name'] as String? ?? delivery['riderName'] as String? ?? 'Not assigned';

    const statusOrder = ['assigned', 'in_transit', 'delivered'];
    const nextLabel   = {'assigned': 'Mark In Transit', 'in_transit': 'Mark Delivered'};
    const nextStatus  = {'assigned': 'in_transit', 'in_transit': 'delivered'};

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).padding.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Delivery Management', style: GoogleFonts.workSans(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),

            // Status badge
            Row(children: [
              const Icon(Icons.local_shipping_rounded, color: AppColors.teal, size: 18),
              const SizedBox(width: 8),
              Text('Status: ', style: GoogleFonts.workSans(fontSize: 13, color: AppColors.textSecondary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(20)),
                child: Text(status[0].toUpperCase() + status.substring(1).replaceAll('_', ' '), style: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal)),
              ),
            ]),
            if (address.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.location_on_rounded, color: AppColors.grey400, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(address, style: GoogleFonts.workSans(fontSize: 13, color: AppColors.textSecondary))),
              ]),
            ],
            Row(children: [
              const Icon(Icons.person_rounded, color: AppColors.grey400, size: 16),
              const SizedBox(width: 6),
              Text('Rider: $riderName', style: GoogleFonts.workSans(fontSize: 13, color: AppColors.textSecondary)),
            ]),
            const SizedBox(height: 20),

            // Update status button (only if not delivered)
            if (nextStatus.containsKey(status)) ...[
              GestureDetector(
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await _deliveryService.updateDeliveryStatus(deliveryId, nextStatus[status]!);
                    _showSnack('Delivery updated: ${nextStatus[status]} ✓');
                    _loadOrders();
                  } catch (e) {
                    _showSnack(e.toString().replaceAll('Exception: ', ''), error: true);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF0ABFBC), Color(0xFF0891B2)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.update_rounded, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(nextLabel[status]!, style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Track button — opens patient-facing tracking screen
            GestureDetector(
              onTap: () { Navigator.pop(ctx); context.push('/delivery/$deliveryId'); },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(color: AppColors.primaryPale, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primary.withValues(alpha: 0.3))),
                child: Center(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.map_rounded, color: AppColors.primary, size: 18),
                    const SizedBox(width: 8),
                    Text('View Tracking Map', style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ]),
                ),
              ),
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
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _showInsuranceSheet() async {
    final current = List<String>.from(
      (_pharmacy?['accepted_insurances'] as List<dynamic>? ?? []).cast<String>(),
    );
    final ctrl = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('Manage Insurances', style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Insurance providers your pharmacy accepts', style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 14),
                if (current.isNotEmpty) ...[
                  Wrap(
                    spacing: 8, runSpacing: 6,
                    children: current.map((ins) => Chip(
                      label: Text(ins, style: GoogleFonts.workSans(fontSize: 12, color: AppColors.tealDark)),
                      backgroundColor: AppColors.tealLight,
                      deleteIcon: const Icon(Icons.close_rounded, size: 14, color: AppColors.teal),
                      onDeleted: () => setS(() => current.remove(ins)),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                        child: Row(children: [
                          const Icon(Icons.health_and_safety_rounded, color: AppColors.teal, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: ctrl,
                              style: GoogleFonts.workSans(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Add insurance (e.g. RSSB)',
                                hintStyle: GoogleFonts.workSans(fontSize: 13, color: AppColors.textHint),
                                border: InputBorder.none,
                                isDense: true, contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final val = ctrl.text.trim();
                        if (val.isNotEmpty && !current.contains(val)) setS(() => current.add(val));
                        ctrl.clear();
                      },
                      child: Container(width: 46, height: 46, decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.add_rounded, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final id = _pharmacy?['_id'] as String?;
                      if (id != null) {
                        await _pharmacyService.updatePharmacyById(id, {'accepted_insurances': current});
                      } else {
                        await _pharmacyService.updateMyPharmacy({'accepted_insurances': current});
                      }
                      if (mounted) {
                        setState(() { if (_pharmacy != null) _pharmacy!['accepted_insurances'] = current; });
                        _showSnack('Insurance list updated ✓');
                      }
                    } catch (_) {
                      _showSnack('Failed to update insurances', error: true);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF0ABFBC), Color(0xFF0891B2)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(child: Text('Save Changes', style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white))),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmSignOut() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign Out', style: GoogleFonts.workSans(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to sign out?', style: GoogleFonts.workSans()),
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

  int get _pendingCount => _orders.where((o) => o['status'] == 'pending').length;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isDark = ref.watch(settingsProvider).isDark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.scaffold;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    // ── If loading, show full-screen loader ─────────────────────────────────
    if (_loadingPharmacy) {
      return const Scaffold(body: AppLoader());
    }

    // ── No pharmacy yet — show setup wizard ─────────────────────────────────
    if (_pharmacy == null) {
      return _CreatePharmacyScreen(
        isDark: isDark,
        cardBg: cardBg,
        scaffoldBg: scaffoldBg,
        onCreated: (pharmacy) {
          final id = pharmacy['_id'] as String?;
          if (id != null && mounted) {
            // Navigate to the dashboard for the newly created pharmacy
            context.pushReplacement('/pharmacy-admin/$id');
          } else {
            setState(() => _pharmacy = pharmacy);
            _loadOrders();
            _loadPendingPayments();
          }
        },
        onSignOut: _confirmSignOut,
        onRetryLoad: () => context.go('/pharmacy-admin'),
        pharmacyService: _pharmacyService,
        userName: user?.name.split(' ').first ?? 'Admin',
      );
    }

    final isVerified = _pharmacy?['is_verified'] as bool? ?? false;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Column(
        children: [
          _buildHeader(user, isDark),

          // ── Pending verification banner ──────────────────────────────────
          if (!isVerified)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.warningLight,
              child: Row(
                children: [
                  const Icon(Icons.hourglass_empty_rounded, color: AppColors.warning, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your pharmacy is pending admin approval. Patients won\'t see it yet.',
                      style: GoogleFonts.workSans(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w600),
                    ),
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
              indicatorWeight: 2.5,
              labelStyle: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.workSans(fontSize: 13),
              tabs: [
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Orders'),
                  if (_pendingCount > 0) ...[const SizedBox(width: 5), _Badge(_pendingCount.toString())],
                ])),
                Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Payments'),
                  if (_pendingPayments.isNotEmpty) ...[const SizedBox(width: 5), _Badge(_pendingPayments.length.toString())],
                ])),
                const Tab(text: 'Inventory'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildOrdersTab(cardBg, borderColor, textPrimary, isDark),
                _buildPaymentsTab(cardBg, borderColor, textPrimary, isDark),
                _buildInventoryTab(cardBg, borderColor, textPrimary, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(user, bool isDark) {
    final isOpen = _pharmacy?['is_open'] as bool? ?? false;
    final pharmacyName = _pharmacy?['name'] as String? ?? 'My Pharmacy';
    final totalOrders = _orders.length;
    final confirmedCount = _orders.where((o) => o['status'] == 'confirmed' || o['status'] == 'ready').length;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0ABFBC), Color(0xFF0891B2), Color(0xFF1B3A6B)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  // Back to pharmacy selection
                  GestureDetector(
                    onTap: () => context.canPop() ? context.pop() : context.go('/pharmacy-admin'),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pharmacyName, style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white), overflow: TextOverflow.ellipsis),
                        Text('Hi, ${user?.name.split(' ').first ?? 'Admin'} 👋', style: GoogleFonts.workSans(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  // Open / Closed toggle
                  GestureDetector(
                    onTap: _toggleOpen,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOpen ? const Color(0xFF4ADE80).withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isOpen ? const Color(0xFF4ADE80) : Colors.white38),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: isOpen ? const Color(0xFF4ADE80) : Colors.white38)),
                          const SizedBox(width: 6),
                          Text(isOpen ? 'Open' : 'Closed', style: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _showInsuranceSheet,
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 8),
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
              const SizedBox(height: 14),
              // Stats
              Row(
                children: [
                  _StatPill(label: 'New', value: _pendingCount.toString(), color: AppColors.accent, icon: Icons.fiber_new_rounded),
                  const SizedBox(width: 8),
                  _StatPill(label: 'Active', value: confirmedCount.toString(), color: const Color(0xFF4ADE80), icon: Icons.timelapse_rounded),
                  const SizedBox(width: 8),
                  _StatPill(label: 'Payments', value: _pendingPayments.length.toString(), color: Colors.orangeAccent, icon: Icons.payment_rounded),
                  const SizedBox(width: 8),
                  _StatPill(label: 'Total', value: totalOrders.toString(), color: Colors.lightBlueAccent, icon: Icons.receipt_long_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersTab(Color cardBg, Color borderColor, Color textPrimary, bool isDark) {
    return Column(
      children: [
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            children: _orderFilters.map((f) {
              final sel = f == _orderFilter;
              return GestureDetector(
                onTap: () { setState(() => _orderFilter = f); _loadOrders(); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.teal : (isDark ? AppColors.darkSurface : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? AppColors.teal : borderColor),
                    boxShadow: sel ? [BoxShadow(color: AppColors.teal.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))] : [],
                  ),
                  child: Text(f[0].toUpperCase() + f.substring(1), style: GoogleFonts.workSans(fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: sel ? Colors.white : textPrimary)),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: _loadingOrders
              ? const AppLoader()
              : _orders.isEmpty
                  ? _emptyState('No orders found', Icons.receipt_long_rounded)
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      color: AppColors.teal,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                        itemCount: _orders.length,
                        itemBuilder: (_, i) => _OrderCard(
                          order: _orders[i],
                          cardBg: cardBg,
                          borderColor: borderColor,
                          textPrimary: textPrimary,
                          onUpdateStatus: _updateOrderStatus,
                          onChatWithPatient: () => _chatWithPatient(_orders[i]),
                          onCreateDelivery: () => _showCreateDeliveryDialog(_orders[i]),
                          onViewDetail: (id) => context.push('/orders/$id'),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildPaymentsTab(Color cardBg, Color borderColor, Color textPrimary, bool isDark) {
    return _loadingPayments
        ? const AppLoader()
        : _pendingPayments.isEmpty
            ? _emptyState('No pending payments', Icons.payment_rounded)
            : RefreshIndicator(
                onRefresh: _loadPendingPayments,
                color: AppColors.teal,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  itemCount: _pendingPayments.length,
                  itemBuilder: (_, i) => _PaymentCard(
                    key: ValueKey(_pendingPayments[i]['_id']),
                    order: _pendingPayments[i],
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textPrimary: textPrimary,
                    onVerify: () => _verifyPayment(_pendingPayments[i]['_id'] as String, 'verify'),
                    onReject: () => _verifyPayment(_pendingPayments[i]['_id'] as String, 'reject'),
                    onViewDetail: (id) => context.push('/orders/$id'),
                  ),
                ),
              );
  }

  Widget _buildInventoryTab(Color cardBg, Color borderColor, Color textPrimary, bool isDark) {
    if (_pharmacy == null && !_loadingPharmacy) {
      return _emptyState('No pharmacy profile found.\nContact admin to set up your pharmacy.', Icons.store_rounded);
    }
    return Column(
      children: [
            // Search + Add button row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor)),
                      child: Row(
                        children: [
                          const Icon(Icons.search_rounded, color: AppColors.grey400, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _inventorySearchCtrl,
                              onChanged: (v) => _loadInventory(search: v),
                              style: GoogleFonts.workSans(fontSize: 13, color: textPrimary),
                              decoration: InputDecoration(hintText: 'Search medicine...', hintStyle: GoogleFonts.workSans(fontSize: 13, color: AppColors.textHint), border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                            ),
                          ),
                          if (_inventorySearchCtrl.text.isNotEmpty)
                            GestureDetector(onTap: () { _inventorySearchCtrl.clear(); _loadInventory(); }, child: const Icon(Icons.close_rounded, color: AppColors.grey400, size: 16)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Add medicine button
                  GestureDetector(
                    onTap: _showAddMedicineDialog,
                    child: Container(
                      height: 46, width: 46,
                      decoration: BoxDecoration(color: AppColors.teal, borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loadingInventory
                  ? const AppLoader()
                  : _inventory.isEmpty
                      ? _emptyState('No medicines in inventory.\nTap + to add medicines.', Icons.medication_rounded)
                      : RefreshIndicator(
                          onRefresh: _loadInventory,
                          color: AppColors.teal,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                            itemCount: _inventory.length,
                            itemBuilder: (_, i) => _InventoryCard(
                              item: _inventory[i],
                              cardBg: cardBg,
                              borderColor: borderColor,
                              textPrimary: textPrimary,
                              onEdit: () => _showEditInventoryDialog(_inventory[i]),
                              onDelete: () => _deleteInventoryItem(_inventory[i]['_id'] as String),
                            ),
                          ),
                        ),
            ),
      ],
    );
  }

  Widget _emptyState(String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.tealLight, shape: BoxShape.circle), child: Icon(icon, size: 36, color: AppColors.teal)),
          const SizedBox(height: 14),
          Text(msg, style: GoogleFonts.workSans(fontSize: 14, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create Pharmacy Setup Screen
// ─────────────────────────────────────────────────────────────────────────────

class _CreatePharmacyScreen extends StatefulWidget {
  final bool isDark;
  final Color cardBg;
  final Color scaffoldBg;
  final void Function(Map<String, dynamic>) onCreated;
  final VoidCallback onSignOut;
  final VoidCallback onRetryLoad; // called when admin taps "I already have one"
  final PharmacyService pharmacyService;
  final String userName;

  const _CreatePharmacyScreen({
    required this.isDark,
    required this.cardBg,
    required this.scaffoldBg,
    required this.onCreated,
    required this.onSignOut,
    required this.onRetryLoad,
    required this.pharmacyService,
    required this.userName,
  });

  @override
  State<_CreatePharmacyScreen> createState() => _CreatePharmacyScreenState();
}

class _CreatePharmacyScreenState extends State<_CreatePharmacyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _licenseCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _latCtrl = TextEditingController(text: '-1.9441');
  final _lngCtrl = TextEditingController(text: '30.0619');
  final _insuranceCtrl = TextEditingController();

  List<String> _insurances = [];
  bool _loading = false;
  bool _locating = false;
  bool _submitted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _licenseCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _insuranceCtrl.dispose();
    super.dispose();
  }

  Future<void> _getMyLocation() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        _showSnack('Location permission denied permanently');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latCtrl.text = pos.latitude.toStringAsFixed(6);
        _lngCtrl.text = pos.longitude.toStringAsFixed(6);
      });
      _showSnack('Location captured ✓');
    } catch (_) {
      _showSnack('Could not get location', error: true);
    } finally {
      setState(() => _locating = false);
    }
  }

  Future<void> _submit() async {
    if (_submitted || _loading) return; // block any double-tap
    if (!_formKey.currentState!.validate()) return;
    final lat = double.tryParse(_latCtrl.text.trim());
    final lng = double.tryParse(_lngCtrl.text.trim());
    if (lat == null || lng == null) {
      _showSnack('Enter valid coordinates', error: true);
      return;
    }
    _submitted = true;
    setState(() => _loading = true);
    try {
      final pharmacy = await widget.pharmacyService.createPharmacy(
        name: _nameCtrl.text.trim(),
        licenseNumber: _licenseCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        lat: lat,
        lng: lng,
        acceptedInsurances: _insurances,
      );
      if (!mounted) return;
      _showSnack('Pharmacy created successfully! 🎉');
      widget.onCreated(pharmacy);
    } catch (e) {
      _submitted = false; // allow retry on error
      _showSnack(e.toString().replaceAll('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final textPrimary = widget.isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Scaffold(
      backgroundColor: widget.scaffoldBg,
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0ABFBC), Color(0xFF0891B2), Color(0xFF1B3A6B)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: widget.onRetryLoad, // goes back to selection screen
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome, ${widget.userName}!', style: GoogleFonts.workSans(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                          Text('Set up your pharmacy to get started', style: GoogleFonts.workSans(fontSize: 12, color: Colors.white70)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: widget.onSignOut,
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.tealLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.teal, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Fill in your pharmacy details below. Your pharmacy will be reviewed by an admin before appearing to patients.',
                              style: GoogleFonts.workSans(fontSize: 12, color: AppColors.tealDark, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text('PHARMACY DETAILS', style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
                    const SizedBox(height: 12),

                    // Name
                    _Field(
                      ctrl: _nameCtrl,
                      label: 'Pharmacy Name *',
                      hint: 'e.g. Kigali Central Pharmacy',
                      icon: Icons.local_pharmacy_rounded,
                      isDark: widget.isDark,
                      cardBg: widget.cardBg,
                      textPrimary: textPrimary,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    // License number
                    _Field(
                      ctrl: _licenseCtrl,
                      label: 'License Number *',
                      hint: 'e.g. PHARM-2024-001',
                      icon: Icons.badge_rounded,
                      isDark: widget.isDark,
                      cardBg: widget.cardBg,
                      textPrimary: textPrimary,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Phone
                    _Field(
                      ctrl: _phoneCtrl,
                      label: 'Phone Number *',
                      hint: 'e.g. +250 788 000 000',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      isDark: widget.isDark,
                      cardBg: widget.cardBg,
                      textPrimary: textPrimary,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    // Address
                    _Field(
                      ctrl: _addressCtrl,
                      label: 'Physical Address *',
                      hint: 'e.g. KG 5 Ave, Kigali City',
                      icon: Icons.location_on_rounded,
                      maxLines: 2,
                      isDark: widget.isDark,
                      cardBg: widget.cardBg,
                      textPrimary: textPrimary,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),

                    const SizedBox(height: 24),
                    Text('PHARMACY LOCATION', style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
                    const SizedBox(height: 8),
                    Text('Used to show your pharmacy on the map for nearby patients.', style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),

                    // GPS button
                    GestureDetector(
                      onTap: _locating ? null : _getMyLocation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _locating ? AppColors.grey100 : AppColors.tealLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.teal.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_locating)
                              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.teal, strokeWidth: 2))
                            else
                              const Icon(Icons.my_location_rounded, color: AppColors.teal, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _locating ? 'Getting location...' : 'Use My Current Location',
                              style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.teal),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Lat / Lng fields
                    Row(
                      children: [
                        Expanded(
                          child: _Field(
                            ctrl: _latCtrl,
                            label: 'Latitude *',
                            hint: '-1.9441',
                            icon: Icons.explore_rounded,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            isDark: widget.isDark,
                            cardBg: widget.cardBg,
                            textPrimary: textPrimary,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _Field(
                            ctrl: _lngCtrl,
                            label: 'Longitude *',
                            hint: '30.0619',
                            icon: Icons.explore_rounded,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            isDark: widget.isDark,
                            cardBg: widget.cardBg,
                            textPrimary: textPrimary,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Required';
                              if (double.tryParse(v) == null) return 'Invalid';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Text('ACCEPTED INSURANCES', style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
                    const SizedBox(height: 6),
                    Text('Add insurance providers your pharmacy accepts (optional).', style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 12),

                    // Insurance chips
                    if (_insurances.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _insurances.map((ins) => Chip(
                          label: Text(ins, style: GoogleFonts.workSans(fontSize: 12, color: AppColors.tealDark)),
                          backgroundColor: AppColors.tealLight,
                          deleteIcon: const Icon(Icons.close_rounded, size: 14, color: AppColors.teal),
                          onDeleted: () => setState(() => _insurances.remove(ins)),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        )).toList(),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Insurance input row
                    Row(
                      children: [
                        Expanded(
                          child: _Field(
                            ctrl: _insuranceCtrl,
                            label: 'Insurance Name',
                            hint: 'e.g. RSSB, MMI, Radiant',
                            icon: Icons.health_and_safety_rounded,
                            isDark: widget.isDark,
                            cardBg: widget.cardBg,
                            textPrimary: textPrimary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            final val = _insuranceCtrl.text.trim();
                            if (val.isNotEmpty && !_insurances.contains(val)) {
                              setState(() => _insurances.add(val));
                            }
                            _insuranceCtrl.clear();
                          },
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.teal,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Submit
                    GestureDetector(
                      onTap: _loading ? null : _submit,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF0ABFBC), Color(0xFF0891B2)]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: AppColors.teal.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Center(
                          child: _loading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.store_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Create Pharmacy', style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Retry button — for admins who already created a pharmacy
                    // but the app failed to load it
                    GestureDetector(
                      onTap: widget.onRetryLoad,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.teal.withValues(alpha: 0.5)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.refresh_rounded, color: AppColors.teal, size: 18),
                            const SizedBox(width: 8),
                            Text('Back to My Pharmacies', style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.teal)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable form field ───────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool isDark;
  final Color cardBg;
  final Color textPrimary;
  final String? Function(String?)? validator;

  const _Field({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.icon,
    required this.isDark,
    required this.cardBg,
    required this.textPrimary,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.workSans(fontSize: 14, color: textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.teal),
        labelStyle: GoogleFonts.workSans(fontSize: 13, color: AppColors.textSecondary),
        hintStyle: GoogleFonts.workSans(fontSize: 13, color: AppColors.textHint),
        fillColor: cardBg,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.teal, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.danger)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatPill({required this.label, required this.value, required this.color, required this.icon});

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

class _Badge extends StatelessWidget {
  final String text;
  const _Badge(this.text);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(10)),
    child: Text(text, style: GoogleFonts.workSans(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
  );
}

class _ActionBtn extends StatefulWidget {
  final String label;
  final Color color;
  final bool outline;
  final IconData? icon;
  final Future<void> Function() onTap;
  const _ActionBtn({required this.label, required this.color, required this.onTap, this.outline = false, this.icon});

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _busy ? null : () async {
      setState(() => _busy = true);
      await widget.onTap();
      if (mounted) setState(() => _busy = false);
    },
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: widget.outline ? Colors.transparent : widget.color,
        borderRadius: BorderRadius.circular(20),
        border: widget.outline ? Border.all(color: widget.color) : null,
      ),
      child: _busy
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: widget.outline ? widget.color : Colors.white,
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 13, color: widget.outline ? widget.color : Colors.white),
                  const SizedBox(width: 4),
                ],
                Text(widget.label, style: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w700, color: widget.outline ? widget.color : Colors.white)),
              ],
            ),
    ),
  );
}

class _PayStatusBadge extends StatelessWidget {
  final String status;
  const _PayStatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final (color, bg, label) = switch (status) {
      'verified' => (AppColors.success, AppColors.successLight, '✓ Paid'),
      'pending_verification' => (AppColors.warning, AppColors.warningLight, '⏳ Verifying'),
      'rejected' => (AppColors.danger, AppColors.dangerLight, '✗ Rejected'),
      _ => (AppColors.grey500, AppColors.grey100, 'Unpaid'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: GoogleFonts.workSans(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── Order card ────────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final Color cardBg, borderColor, textPrimary;
  final Future<void> Function(String, String) onUpdateStatus;
  final Future<void> Function() onChatWithPatient;
  final Future<void> Function() onCreateDelivery;
  final void Function(String) onViewDetail;

  const _OrderCard({required this.order, required this.cardBg, required this.borderColor, required this.textPrimary, required this.onUpdateStatus, required this.onChatWithPatient, required this.onCreateDelivery, required this.onViewDetail});

  static const _statusColor = {'pending': Color(0xFFEF9F27), 'confirmed': Color(0xFF0ABFBC), 'ready': Color(0xFF10B981), 'completed': Color(0xFF166534), 'cancelled': Color(0xFF9F1239)};
  static const _statusBg = {'pending': Color(0xFFFEF3C7), 'confirmed': Color(0xFFE0F7F7), 'ready': Color(0xFFD1FAE5), 'completed': Color(0xFFDCFCE7), 'cancelled': Color(0xFFFFF1F2)};

  String get _patientName { final p = order['patient_id']; return (p is Map ? p['name'] : null) as String? ?? 'Patient'; }
  String get _patientPhone { final p = order['patient_id']; return (p is Map ? p['phone'] : null) as String? ?? ''; }
  List<String> get _items {
    final list = order['items'] as List<dynamic>? ?? [];
    return list.map((e) {
      if (e is Map) { final m = e['medicine_id']; return (m is Map ? m['name'] : null) as String? ?? 'Medicine'; }
      return 'Medicine';
    }).toList();
  }
  String _time(String? raw) { if (raw == null) return ''; final dt = DateTime.tryParse(raw); return dt == null ? '' : DateFormat('MMM d, h:mm a').format(dt.toLocal()); }

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String? ?? 'pending';
    final total = order['total_amount'] as num? ?? 0;
    // payment is nested: order.payment.status
    final payment = order['payment'] as Map<String, dynamic>?;
    final payStatus = payment?['status'] as String? ?? order['payment_status'] as String? ?? 'unpaid';
    final orderId = order['_id'] as String? ?? '';
    final sc = _statusColor[status] ?? AppColors.grey400;
    final sb = _statusBg[status] ?? AppColors.grey100;

    return GestureDetector(
      onTap: () { if (orderId.isNotEmpty) onViewDetail(orderId); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor, width: 0.5), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  Container(width: 38, height: 38, decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.person_rounded, color: AppColors.teal, size: 20)),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_patientName, style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                    if (_patientPhone.isNotEmpty) Text(_patientPhone, style: GoogleFonts.workSans(fontSize: 11, color: AppColors.textSecondary)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: sb, borderRadius: BorderRadius.circular(20)), child: Text(status[0].toUpperCase() + status.substring(1), style: GoogleFonts.workSans(fontSize: 10, fontWeight: FontWeight.w700, color: sc))),
                    const SizedBox(height: 3),
                    Text(_time(order['created_at'] as String? ?? order['createdAt'] as String?), style: GoogleFonts.workSans(fontSize: 10, color: AppColors.textHint)),
                  ]),
                ],
              ),
            ),
            if (_items.isNotEmpty)
              Padding(padding: const EdgeInsets.fromLTRB(14, 0, 14, 6), child: Text(_items.join(' · '), style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(children: [
                Text('${NumberFormat('#,###').format(total)} RWF', style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w800, color: textPrimary)),
                const SizedBox(width: 8),
                _PayStatusBadge(payStatus),
              ]),
            ),
                    if (status != 'completed' && status != 'cancelled')
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (status == 'pending') ...[
                      _ActionBtn(label: 'Confirm', color: AppColors.teal, onTap: () => onUpdateStatus(orderId, 'confirmed')),
                      _ActionBtn(label: 'Decline', color: AppColors.danger, onTap: () => onUpdateStatus(orderId, 'cancelled')),
                    ],
                    if (status == 'confirmed') ...[
                      _ActionBtn(label: 'Mark Ready', color: AppColors.success, onTap: () => onUpdateStatus(orderId, 'ready')),
                      _ActionBtn(label: 'Cancel', color: AppColors.danger, outline: true, onTap: () => onUpdateStatus(orderId, 'cancelled')),
                    ],
                    if (status == 'ready') ...[
                      // Show "Dispatch" for delivery orders, "Complete" for pickups
                      if (order['type'] == 'delivery')
                        _ActionBtn(label: 'Dispatch', color: AppColors.primary, icon: Icons.delivery_dining_rounded, onTap: onCreateDelivery)
                      else
                        _ActionBtn(label: 'Complete', color: AppColors.success, onTap: () => onUpdateStatus(orderId, 'completed')),
                      _ActionBtn(label: 'Cancel', color: AppColors.danger, outline: true, onTap: () => onUpdateStatus(orderId, 'cancelled')),
                    ],
                    // Chat button always visible for non-terminal orders
                    _ActionBtn(label: 'Chat', color: AppColors.primary, icon: Icons.chat_bubble_rounded, outline: true, onTap: onChatWithPatient),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Payment card ──────────────────────────────────────────────────────────────
class _PaymentCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final Color cardBg, borderColor, textPrimary;
  final Future<void> Function() onVerify;
  final Future<void> Function() onReject;
  final void Function(String) onViewDetail;

  const _PaymentCard({super.key, required this.order, required this.cardBg, required this.borderColor, required this.textPrimary, required this.onVerify, required this.onReject, required this.onViewDetail});

  @override
  State<_PaymentCard> createState() => _PaymentCardState();
}

class _PaymentCardState extends State<_PaymentCard> {
  bool _verifying = false;
  bool _rejecting = false;

  String get _patientName { final p = widget.order['patient_id']; return (p is Map ? p['name'] : null) as String? ?? 'Patient'; }

  @override
  Widget build(BuildContext context) {
    final orderId  = widget.order['_id'] as String? ?? '';
    final total    = widget.order['total_amount'] as num? ?? 0;
    final payment  = widget.order['payment'] as Map<String, dynamic>?;
    final proofMap = payment?['proof'] as Map<String, dynamic>?;
    final proof    = proofMap?['url'] as String? ?? widget.order['payment_proof'] as String?;
    final provider  = payment?['provider']  as String? ?? widget.order['payment_provider']  as String? ?? '';
    final reference = payment?['reference'] as String? ?? widget.order['payment_reference'] as String? ?? '';
    final busy = _verifying || _rejecting;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: widget.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.payment_rounded, color: AppColors.accent, size: 20)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_patientName, style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w700, color: widget.textPrimary)),
              Text('${NumberFormat('#,###').format(total)} RWF', style: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal)),
            ])),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(20)), child: Text('Pending', style: GoogleFonts.workSans(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.warning))),
          ]),
          if (provider.isNotEmpty || reference.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (provider.isNotEmpty) Row(children: [const Icon(Icons.phone_android_rounded, size: 12, color: AppColors.grey400), const SizedBox(width: 6), Text('Provider: $provider', style: GoogleFonts.workSans(fontSize: 12))]),
                if (reference.isNotEmpty) ...[const SizedBox(height: 4), Row(children: [const Icon(Icons.tag_rounded, size: 12, color: AppColors.grey400), const SizedBox(width: 6), Expanded(child: Text('Ref: $reference', style: GoogleFonts.workSans(fontSize: 12), overflow: TextOverflow.ellipsis))])],
              ]),
            ),
          ],
          if (proof != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => widget.onViewDetail(orderId),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(proof, height: 130, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 60, color: AppColors.grey100, child: Center(child: Text('View proof →', style: GoogleFonts.workSans(color: AppColors.teal, fontWeight: FontWeight.w600))))),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: busy ? null : () async {
                  setState(() => _verifying = true);
                  await widget.onVerify();
                  if (mounted) setState(() => _verifying = false);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(12)),
                  child: _verifying
                      ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16), const SizedBox(width: 6), Text('Verify', style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white))]),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: busy ? null : () async {
                  setState(() => _rejecting = true);
                  await widget.onReject();
                  if (mounted) setState(() => _rejecting = false);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.danger.withValues(alpha: 0.4))),
                  child: _rejecting
                      ? const Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.danger, strokeWidth: 2)))
                      : Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.cancel_rounded, color: AppColors.danger, size: 16), const SizedBox(width: 6), Text('Reject', style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.danger))]),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ── Inventory card ────────────────────────────────────────────────────────────
class _InventoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color cardBg, borderColor, textPrimary;
  final VoidCallback onEdit, onDelete;

  const _InventoryCard({required this.item, required this.cardBg, required this.borderColor, required this.textPrimary, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final med = item['medicine_id'];
    final name = (med is Map ? med['name'] : 'Medicine') as String? ?? 'Medicine';
    final category = (med is Map ? med['category'] : '') as String? ?? '';
    final price = item['price'] as num? ?? 0;
    final qty = item['quantity'] as num? ?? 0;
    // Use quantity as the source of truth — the in_stock field in the DB
    // may be stale because findOneAndUpdate bypasses the pre-save hook.
    final inStock = qty > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(14), border: Border.all(color: borderColor, width: 0.5)),
      child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.medication_rounded, color: AppColors.teal, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary), overflow: TextOverflow.ellipsis),
          if (category.isNotEmpty) Text(category, style: GoogleFonts.workSans(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Row(children: [
            Text('${NumberFormat('#,###').format(price)} RWF', style: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal)),
            const SizedBox(width: 8),
            Text('Qty: $qty', style: GoogleFonts.workSans(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: inStock ? AppColors.successLight : AppColors.dangerLight, borderRadius: BorderRadius.circular(10)), child: Text(inStock ? 'In Stock' : 'Out', style: GoogleFonts.workSans(fontSize: 9, fontWeight: FontWeight.w700, color: inStock ? AppColors.success : AppColors.danger))),
          ]),
        ])),
        Row(children: [
          GestureDetector(onTap: onEdit, child: Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.edit_rounded, color: AppColors.teal, size: 15))),
          const SizedBox(width: 6),
          GestureDetector(onTap: onDelete, child: Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.dangerLight, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.delete_rounded, color: AppColors.danger, size: 15))),
        ]),
      ]),
    );
  }
}
