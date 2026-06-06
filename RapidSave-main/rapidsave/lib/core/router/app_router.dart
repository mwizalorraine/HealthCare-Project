import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rapidsave/features/profile/screens/change_password_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/privacy_policy_screen.dart';
import '../../features/profile/screens/about_screen.dart';
import '../../features/profile/screens/help_screen.dart';
import '../../core/providers/settings_provider.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/verify_email_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/medicine/screens/medicine_search_screen.dart';
import '../../features/pharmacy/screens/nearby_pharmacies_screen.dart';
import '../../features/order/screens/order_list_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/notification/screens/notification_screen.dart';
import '../../features/pharmacy/screens/pharmacy_detail_screen.dart';
import '../../features/medicine/screens/medicine_detail_screen.dart';
import '../../features/order/screens/order_detail_screen.dart';
import '../../features/order/screens/create_order_screen.dart';
import '../../features/order/screens/payment_proof_screen.dart';
import '../../features/delivery/screens/delivery_tracking_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../constants/app_colors.dart';
import 'package:flutter/material.dart';
import '../../features/pharmacy/screens/pharmacy_admin_screen.dart';
import '../../features/pharmacy/screens/pharmacy_select_screen.dart';
import '../../features/admin/screens/admin_screen.dart';

class _AuthChangeNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

const _publicRoutes = [
  '/splash',
  '/onboarding',
  '/login',
  '/register',
  '/verify-email',
  '/forgot-password',
  '/reset-password',
  '/pharmacy-admin',   // covers /pharmacy-admin, /pharmacy-admin/new, /pharmacy-admin/:id
  '/admin',
];

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier();
  ref.listen<AuthState>(authProvider, (_, __) => authNotifier.notify());
  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isAuthenticated = ref.read(authProvider).isAuthenticated;
      final loc = state.matchedLocation;
      final isPublic = _publicRoutes.any((r) => loc.startsWith(r));
      if (!isAuthenticated && !isPublic) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/verify-email',
        builder: (_, state) =>
            VerifyEmailScreen(email: state.extra as String? ?? ''),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) =>
            ResetPasswordScreen(email: state.extra as String? ?? ''),
      ),
      // Pharmacy selection landing page
      GoRoute(
        path: '/pharmacy-admin',
        builder: (_, __) => const PharmacySelectScreen(),
      ),
      // Create new pharmacy
      GoRoute(
        path: '/pharmacy-admin/new',
        builder: (_, __) => const PharmacyAdminScreen(pharmacyId: null),
      ),
      // Manage a specific pharmacy by ID
      GoRoute(
        path: '/pharmacy-admin/:id',
        builder: (_, state) =>
            PharmacyAdminScreen(pharmacyId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminScreen(),
      ),
      GoRoute(
        path: '/change-password',
        builder: (_, __) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (_, __) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (_, __) => const AboutScreen(),
      ),
      GoRoute(
        path: '/help',
        builder: (_, __) => const HelpScreen(),
      ),

      // ── Shell with bottom nav ──────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(
            path: '/search',
            builder: (_, __) => const MedicineSearchScreen(),
          ),
          GoRoute(
            path: '/pharmacies',
            builder: (_, __) => const NearbyPharmaciesScreen(),
          ),
          GoRoute(path: '/orders', builder: (_, __) => const OrderListScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Detail routes (no bottom nav) ──────────────────────────────────
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/pharmacy/:id',
        builder: (_, state) =>
            PharmacyDetailScreen(id: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/medicine/:id',
        builder: (_, state) =>
            MedicineDetailScreen(id: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/orders/:id',
        builder: (_, state) =>
            OrderDetailScreen(id: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/create-order',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CreateOrderScreen(
            pharmacyId: extra?['pharmacyId'] as String? ?? '',
            inventoryId: extra?['inventoryId'] as String?,
            medicineId: extra?['medicineId'] as String?,
            medicineName: extra?['medicineName'] as String?,
            medicineCategory: extra?['medicineCategory'] as String?,
            medicinePrice: extra?['medicinePrice'] as int?,
            stockQuantity: extra?['stockQuantity'] as int?,
          );
        },
      ),
      GoRoute(
        path: '/payment-proof/:orderId',
        builder: (_, state) =>
            PaymentProofScreen(orderId: state.pathParameters['orderId'] ?? ''),
      ),
      GoRoute(
        path: '/delivery/:id',
        builder: (_, state) => DeliveryTrackingScreen(
          deliveryId: state.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (_, state) => ChatScreen(
          conversationId: state.pathParameters['conversationId'] ?? '',
        ),
      ),
    ],
    errorBuilder: (_, state) => const SplashScreen(),
  );
});

// ── App shell with bottom navigation ──────────────────────────────────────────
class _AppShell extends ConsumerWidget {
  final Widget child;
  const _AppShell({required this.child});

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/pharmacies')) return 2;
    if (location.startsWith('/orders')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = _currentIndex(context);
    final isDark = ref.watch(settingsProvider).isDark;
    final navBg = isDark ? AppColors.darkCard : Colors.white;
    final l10n = ref.watch(appL10nProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_rounded, label: l10n.navHome, isSelected: index == 0, onTap: () => context.go('/home'), isDark: isDark),
                _NavItem(icon: Icons.search_rounded, label: l10n.navSearch, isSelected: index == 1, onTap: () => context.go('/search'), isDark: isDark),
                _NavItem(icon: Icons.local_pharmacy_rounded, label: l10n.navPharmacies, isSelected: index == 2, onTap: () => context.go('/pharmacies'), isDark: isDark),
                _NavItem(icon: Icons.receipt_long_rounded, label: l10n.navOrders, isSelected: index == 3, onTap: () => context.go('/orders'), isDark: isDark),
                _NavItem(icon: Icons.person_rounded, label: l10n.navProfile, isSelected: index == 4, onTap: () => context.go('/profile'), isDark: isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav item ──────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = isDark ? AppColors.teal.withOpacity(0.15) : AppColors.tealLight;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: isSelected ? AppColors.teal : AppColors.grey400),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.teal)),
            ],
          ],
        ),
      ),
    );
  }
}
