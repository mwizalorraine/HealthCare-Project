import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/utils/app_utils.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final settings = ref.watch(settingsProvider);
    final l10n = ref.watch(appL10nProvider);
    final isDark = settings.isDark;
    final padding = MediaQuery.of(context).padding;

    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final sectionBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.scaffold;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0ABFBC), Color(0xFF0891B2), Color(0xFF1B5E8A)],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    children: [
                      // Top row
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.myProfile,
                                style: GoogleFonts.workSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                              ),
                              Text(
                                DateFormat('MMMM dd, yyyy').format(DateTime.now()),
                                style: GoogleFonts.workSans(fontSize: 13, color: Colors.white70),
                              ),
                            ],
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => context.push('/edit-profile'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                                  const SizedBox(width: 6),
                                  Text(l10n.editProfile, style: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── User card ──────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 4))],
                        ),
                        child: Row(
                          children: [
                            // Avatar
                            Stack(
                              children: [
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [AppColors.tealLight, AppColors.teal.withOpacity(0.3)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(color: AppColors.teal.withOpacity(0.4), width: 2),
                                  ),
                                  child: Center(
                                    child: Text(
                                      AppUtils.getInitials(user?.name ?? 'U'),
                                      style: GoogleFonts.workSans(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.teal),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.teal),
                                    child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user?.name ?? 'User', style: GoogleFonts.workSans(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary)),
                                  const SizedBox(height: 2),
                                  Text(user?.email ?? '', style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textSecondary)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(20)),
                                    child: Text(
                                      user?.role == 'pharmacy_admin'
                                          ? '💊 ${l10n.pharmacyAdmin}'
                                          : user?.role == 'admin'
                                              ? '⚡ ${l10n.adminRole}'
                                              : '🏥 ${l10n.patient}',
                                      style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.tealDark),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Verified badge
                            Column(
                              children: [
                                Icon(
                                  user?.emailVerified == true ? Icons.verified_rounded : Icons.warning_amber_rounded,
                                  color: user?.emailVerified == true ? AppColors.success : AppColors.warning,
                                  size: 22,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  user?.emailVerified == true ? l10n.verified : l10n.unverified,
                                  style: GoogleFonts.workSans(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: user?.emailVerified == true ? AppColors.success : AppColors.warning,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Stats row ──────────────────────────────────────────
                      Row(
                        children: [
                          _StatCard(value: '12', label: l10n.navOrders, icon: Icons.receipt_long_rounded, color: AppColors.teal, bgColor: AppColors.tealLight, cardBg: cardBg),
                          const SizedBox(width: 10),
                          _StatCard(value: '5', label: l10n.navPharmacies, icon: Icons.local_pharmacy_rounded, color: AppColors.primary, bgColor: AppColors.primaryPale, cardBg: cardBg),
                          const SizedBox(width: 10),
                          _StatCard(value: '8', label: 'Medicines', icon: Icons.medication_rounded, color: AppColors.secondary, bgColor: AppColors.secondaryLight, cardBg: cardBg),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Account ───────────────────────────────────────────────────────
          _SectionHeader(title: l10n.sectionAccount),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _SettingsCard(
                bg: sectionBg,
                borderColor: borderColor,
                children: [
                  _SettingsItem(icon: Icons.person_outline_rounded, label: l10n.personalInfo, textColor: textPrimary, onTap: () => context.push('/edit-profile')),
                  _Divider(color: borderColor),
                  _SettingsItem(icon: Icons.phone_outlined, label: l10n.phoneNumber, value: user?.phone ?? 'Not set', textColor: textPrimary, onTap: () => context.push('/edit-profile')),
                  _Divider(color: borderColor),
                  _SettingsItem(icon: Icons.location_on_outlined, label: l10n.myAddress, textColor: textPrimary, onTap: () {}),
                ],
              ),
            ),
          ),

          // ── Orders & History ──────────────────────────────────────────────
          _SectionHeader(title: l10n.sectionOrdersHistory),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _SettingsCard(
                bg: sectionBg,
                borderColor: borderColor,
                children: [
                  _SettingsItem(icon: Icons.receipt_long_rounded, label: l10n.myOrders, textColor: textPrimary, onTap: () => context.go('/orders')),
                  _Divider(color: borderColor),
                  _SettingsItem(icon: Icons.favorite_outline_rounded, label: l10n.savedPharmacies, textColor: textPrimary, onTap: () {}),
                  _Divider(color: borderColor),
                  _SettingsItem(icon: Icons.history_rounded, label: l10n.orderHistory, textColor: textPrimary, onTap: () => context.go('/orders')),
                ],
              ),
            ),
          ),

          // ── Security ──────────────────────────────────────────────────────
          _SectionHeader(title: l10n.sectionSecurity),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _SettingsCard(
                bg: sectionBg,
                borderColor: borderColor,
                children: [
                  _SettingsItem(icon: Icons.lock_outline_rounded, label: l10n.changePassword, textColor: textPrimary, onTap: () => context.push('/change-password')),
                  _Divider(color: borderColor),
                  _SettingsItem(icon: Icons.notifications_outlined, label: l10n.notifications, textColor: textPrimary, onTap: () => context.push('/notifications')),
                  _Divider(color: borderColor),
                  _SettingsItem(icon: Icons.privacy_tip_outlined, label: l10n.privacyPolicy, textColor: textPrimary, onTap: () => context.push('/privacy-policy')),
                ],
              ),
            ),
          ),

          // ── App Settings ──────────────────────────────────────────────────
          _SectionHeader(title: l10n.sectionAppSettings),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _SettingsCard(
                bg: sectionBg,
                borderColor: borderColor,
                children: [
                  _SettingsItem(
                    icon: Icons.language_rounded,
                    label: l10n.language,
                    value: ref.read(settingsProvider.notifier).localeName,
                    textColor: textPrimary,
                    onTap: () => _showLanguagePicker(context, ref, l10n),
                  ),
                  _Divider(color: borderColor),
                  _SettingsItemToggle(
                    icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    label: l10n.darkMode,
                    value: isDark,
                    textColor: textPrimary,
                    onChanged: (_) => ref.read(settingsProvider.notifier).toggleTheme(),
                  ),
                  _Divider(color: borderColor),
                  _SettingsItem(icon: Icons.notifications_active_outlined, label: l10n.pushNotifications, value: l10n.on, textColor: textPrimary, onTap: () {}),
                  _Divider(color: borderColor),
                  _SettingsItem(icon: Icons.location_on_outlined, label: l10n.locationServices, value: l10n.on, textColor: textPrimary, onTap: () {}),
                ],
              ),
            ),
          ),

          // ── Support ───────────────────────────────────────────────────────
          _SectionHeader(title: l10n.sectionSupport),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _SettingsCard(
                bg: sectionBg,
                borderColor: borderColor,
                children: [
                  _SettingsItem(icon: Icons.help_outline_rounded, label: l10n.helpSupport, textColor: textPrimary, onTap: () => context.push('/help')),
                  _Divider(color: borderColor),
                  _SettingsItem(icon: Icons.star_outline_rounded, label: l10n.rateApp, textColor: textPrimary, onTap: () {}),
                  _Divider(color: borderColor),
                  _SettingsItem(icon: Icons.info_outline_rounded, label: l10n.aboutApp, value: 'v1.0.0', textColor: textPrimary, onTap: () => context.push('/about')),
                ],
              ),
            ),
          ),

          // ── Sign out ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: GestureDetector(
                onTap: () => _confirmSignOut(context, ref, l10n),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.dangerLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.danger.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.logout_rounded, color: AppColors.danger, size: 20),
                      const SizedBox(width: 10),
                      Text(l10n.signOut, style: GoogleFonts.workSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.danger)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: padding.bottom + 40)),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, WidgetRef ref, AppL10n l10n) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Consumer(
        builder: (ctx, r, __) {
          final isDark = r.watch(settingsProvider).isDark;
          final sheetBg = isDark ? AppColors.darkCard : Colors.white;
          final currentLang = r.watch(settingsProvider).locale.languageCode;
          return Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).padding.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Text(l10n.selectLanguage, style: GoogleFonts.workSans(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _LangTile(flag: '🇬🇧', name: l10n.english, lang: 'en', currentLang: currentLang, isDark: isDark),
                const SizedBox(height: 8),
                _LangTile(flag: '🇫🇷', name: l10n.french, lang: 'fr', currentLang: currentLang, isDark: isDark),
                const SizedBox(height: 8),
                _LangTile(flag: '🇷🇼', name: l10n.kinyarwanda, lang: 'rw', currentLang: currentLang, isDark: isDark),
                const SizedBox(height: 8),
                _LangTile(flag: '🇹🇿', name: l10n.kiswahili, lang: 'sw', currentLang: currentLang, isDark: isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref, AppL10n l10n) {
    // Non-async: we handle navigation entirely inside the button callback
    // to avoid the '!_debugLocked' assertion that fires when logout() triggers
    // the router's redirect while the dialog's pop animation is still running.
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(l10n.signOutTitle, style: GoogleFonts.workSans(fontWeight: FontWeight.w700)),
        content: Text(l10n.signOutMessage, style: GoogleFonts.workSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.cancel, style: GoogleFonts.workSans(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              // 1. Close the dialog — the Navigator processes this pop synchronously.
              Navigator.of(dialogCtx).pop();
              // 2. Defer logout to the next frame so the Navigator is fully
              //    unlocked before we trigger the router's redirect.
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                await ref.read(authProvider.notifier).logout();
                // GoRouter's refreshListenable fires when auth state → null,
                // but we also call go() explicitly as a reliable fallback.
                if (context.mounted) context.go('/login');
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(l10n.signOut, style: GoogleFonts.workSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Language tile ─────────────────────────────────────────────────────────────
class _LangTile extends ConsumerWidget {
  final String flag;
  final String name;
  final String lang;
  final String currentLang;
  final bool isDark;
  const _LangTile({required this.flag, required this.name, required this.lang, required this.currentLang, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = lang == currentLang;
    return GestureDetector(
      onTap: () {
        ref.read(settingsProvider.notifier).setLocale(Locale(lang));
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.tealLight : (isDark ? AppColors.darkSurface : Colors.transparent),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColors.teal : (isDark ? AppColors.darkBorder : AppColors.border)),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.workSans(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color cardBg;

  const _StatCard({required this.value, required this.label, required this.icon, required this.color, required this.bgColor, required this.cardBg});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 8),
            Text(value, style: GoogleFonts.workSans(fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label, style: GoogleFonts.workSans(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.workSans(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8),
        ),
      ),
    );
  }
}

// ── Settings card ─────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final Color bg;
  final Color borderColor;
  const _SettingsCard({required this.children, required this.bg, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(children: children),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final Color color;
  const _Divider({required this.color});

  @override
  Widget build(BuildContext context) => Divider(height: 1, indent: 66, endIndent: 0, color: color);
}

// ── Settings item ─────────────────────────────────────────────────────────────
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Color textColor;
  final VoidCallback onTap;

  const _SettingsItem({required this.icon, required this.label, this.value, required this.textColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: AppColors.teal, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w500, color: textColor))),
            if (value != null) Text(value!, style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textHint)),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, color: AppColors.grey400, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Settings item with toggle ─────────────────────────────────────────────────
class _SettingsItemToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final Color textColor;
  final ValueChanged<bool> onChanged;

  const _SettingsItemToggle({required this.icon, required this.label, required this.value, required this.textColor, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppColors.teal, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w500, color: textColor))),
          Switch.adaptive(value: value, onChanged: onChanged, activeTrackColor: AppColors.teal),
        ],
      ),
    );
  }
}
