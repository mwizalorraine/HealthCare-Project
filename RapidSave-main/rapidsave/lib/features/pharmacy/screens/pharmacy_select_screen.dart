import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/pharmacy_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_loader.dart';

class PharmacySelectScreen extends ConsumerStatefulWidget {
  const PharmacySelectScreen({super.key});

  @override
  ConsumerState<PharmacySelectScreen> createState() => _PharmacySelectScreenState();
}

class _PharmacySelectScreenState extends ConsumerState<PharmacySelectScreen> {
  final _service = PharmacyService();
  List<Map<String, dynamic>> _pharmacies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _service.getMyPharmacies();
      if (mounted) setState(() => _pharmacies = list);
    } catch (_) {
      if (mounted) setState(() => _pharmacies = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _signOut() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Sign Out', style: GoogleFonts.workSans(fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to sign out?', style: GoogleFonts.workSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.workSans()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text('Sign Out', style: GoogleFonts.workSans(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Pharmacies',
                                style: GoogleFonts.workSans(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                              Text(
                                user?.name ?? 'Pharmacy Admin',
                                style: GoogleFonts.workSans(fontSize: 12, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: _signOut,
                          child: Container(
                            width: 38, height: 38,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _loading
                          ? 'Loading...'
                          : _pharmacies.isEmpty
                              ? 'No pharmacies yet. Create your first one!'
                              : '${_pharmacies.length} registered ${_pharmacies.length == 1 ? 'pharmacy' : 'pharmacies'}',
                      style: GoogleFonts.workSans(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body
          Expanded(
            child: _loading
                ? const AppLoader()
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.teal,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      children: [
                        ..._pharmacies.map((ph) => _PharmacyTile(
                          pharmacy: ph,
                          onTap: () => context.push('/pharmacy-admin/${ph['_id']}'),
                        )),
                        const SizedBox(height: 8),
                        // Add new pharmacy card
                        GestureDetector(
                          onTap: () => context.push('/pharmacy-admin/new'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                            decoration: BoxDecoration(
                              color: AppColors.tealLight,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.teal.withOpacity(0.4), width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Add New Pharmacy',
                                  style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.tealDark),
                                ),
                              ],
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

class _PharmacyTile extends StatelessWidget {
  final Map<String, dynamic> pharmacy;
  final VoidCallback onTap;
  const _PharmacyTile({required this.pharmacy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOpen = pharmacy['is_open'] as bool? ?? false;
    final isVerified = pharmacy['is_verified'] as bool? ?? false;
    final address = pharmacy['address'] as String? ?? '';
    final insurances = (pharmacy['accepted_insurances'] as List<dynamic>?)
        ?.whereType<String>()
        .where((s) => s.isNotEmpty)
        .take(3)
        .toList() ?? [];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                color: isOpen ? AppColors.tealLight : AppColors.grey100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.local_pharmacy_rounded, color: isOpen ? AppColors.teal : AppColors.grey400, size: 28),
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
                          style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                      ),
                      if (!isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(10)),
                          child: Text('Pending', style: GoogleFonts.workSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warning)),
                        ),
                    ],
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(address, style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isOpen ? AppColors.successLight : AppColors.dangerLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: isOpen ? AppColors.success : AppColors.danger)),
                            const SizedBox(width: 4),
                            Text(isOpen ? 'Open' : 'Closed', style: GoogleFonts.workSans(fontSize: 10, fontWeight: FontWeight.w600, color: isOpen ? AppColors.success : AppColors.danger)),
                          ],
                        ),
                      ),
                      ...insurances.map((ins) => Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFEDE9FE), borderRadius: BorderRadius.circular(20)),
                        child: Text(ins, style: GoogleFonts.workSans(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF7C3AED))),
                      )),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }
}
