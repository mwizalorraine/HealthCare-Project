import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/settings_provider.dart';

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  int? _expandedIndex;

  static const _faqs = [
    (
      q: 'How do I place an order?',
      a: 'Browse pharmacies or search for a medicine, tap on the item, and press "Order Now". Fill in your delivery details and submit your order.',
    ),
    (
      q: 'How can I track my delivery?',
      a: 'Once your order is confirmed and a rider is assigned, go to My Orders and tap "Track Delivery" on your order. You will see the rider\'s real-time location on the map.',
    ),
    (
      q: 'What payment methods are accepted?',
      a: 'We currently support payment by uploading a proof of payment (bank transfer or mobile money). Upload your payment screenshot in the order details screen.',
    ),
    (
      q: 'How do I cancel an order?',
      a: 'You can cancel an order as long as it has not been assigned to a rider yet. Open the order details and tap "Cancel Order". Inventory will be restored automatically.',
    ),
    (
      q: 'Can I chat with the pharmacy?',
      a: 'Yes! Once you have an active order, open the order details and tap the "Chat" button to send messages directly to the pharmacy.',
    ),
    (
      q: 'What if I don\'t receive a notification?',
      a: 'Make sure notifications are enabled for RapidSave in your device settings. Also check that battery optimization is disabled for the app so it can receive background notifications.',
    ),
    (
      q: 'How do I change my profile information?',
      a: 'Go to Profile, tap the "Edit Profile" button at the top, update your name or phone number, and tap "Save Changes".',
    ),
    (
      q: 'How do I change my password?',
      a: 'Go to Profile → Security → Change Password. Enter your current password, then set a new one.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(settingsProvider).isDark;
    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.scaffold;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: Column(
        children: [
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Row(
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
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Help & Support',
                      style: GoogleFonts.workSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Contact ────────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.teal.withOpacity(0.12),
                        AppColors.primary.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.teal.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.support_agent_rounded,
                        color: AppColors.teal,
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Need help?',
                        style: GoogleFonts.workSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Our support team is here for you',
                        style: GoogleFonts.workSans(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _ContactButton(
                              icon: Icons.email_outlined,
                              label: 'Email Us',
                              subtitle: 'magnifiqueni01@gmail.com',
                              onTap: () {
                                Clipboard.setData(
                                  const ClipboardData(
                                    text: 'magnifiqueni01@gmail.com',
                                  ),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Email copied to clipboard',
                                      style: GoogleFonts.workSans(
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    margin: const EdgeInsets.all(16),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ContactButton(
                              icon: Icons.phone_outlined,
                              label: 'Call Us',
                              subtitle: '+250 788 000 000',
                              onTap: () {
                                Clipboard.setData(
                                  const ClipboardData(text: '+250788000000'),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Number copied to clipboard',
                                      style: GoogleFonts.workSans(
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    margin: const EdgeInsets.all(16),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'FREQUENTLY ASKED QUESTIONS',
                  style: GoogleFonts.workSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 12),

                // ── FAQ accordion ──────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor, width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      children: _faqs.asMap().entries.map((e) {
                        final i = e.key;
                        final faq = e.value;
                        final isExpanded = _expandedIndex == i;
                        final isLast = i == _faqs.length - 1;
                        return Column(
                          children: [
                            InkWell(
                              onTap: () => setState(
                                () => _expandedIndex = isExpanded ? null : i,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: isExpanded
                                            ? AppColors.teal
                                            : AppColors.tealLight,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${i + 1}',
                                          style: GoogleFonts.workSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isExpanded
                                                ? Colors.white
                                                : AppColors.teal,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        faq.q,
                                        style: GoogleFonts.workSans(
                                          fontSize: 13,
                                          fontWeight: isExpanded
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: textPrimary,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.grey400,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (isExpanded)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  14,
                                ),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.tealLight.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  faq.a,
                                  style: GoogleFonts.workSans(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            if (!isLast)
                              Divider(
                                height: 1,
                                indent: 60,
                                color: borderColor,
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.teal, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.workSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.workSans(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
