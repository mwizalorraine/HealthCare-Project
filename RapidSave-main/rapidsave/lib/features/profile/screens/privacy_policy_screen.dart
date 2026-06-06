import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/settings_provider.dart';

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(settingsProvider).isDark;
    final scaffoldBg  = isDark ? AppColors.darkScaffold : AppColors.scaffold;
    final cardBg      = isDark ? AppColors.darkCard : Colors.white;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
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
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Privacy Policy', style: GoogleFonts.workSans(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                        Text('Last updated: January 2025', style: GoogleFonts.workSans(fontSize: 12, color: Colors.white70)),
                      ],
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
                _PolicyCard(
                  bg: cardBg,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  sections: const [
                    _PolicySection(
                      icon: Icons.info_outline_rounded,
                      title: 'Information We Collect',
                      body:
                          'We collect information you provide directly to us, such as your name, email address, phone number, and delivery address when you register or place an order. We also collect location data when you use our delivery tracking features.',
                    ),
                    _PolicySection(
                      icon: Icons.medical_services_outlined,
                      title: 'How We Use Your Information',
                      body:
                          'We use the information we collect to provide, maintain, and improve our pharmacy delivery services, process your orders, send you order notifications and delivery updates, and communicate with you about products and services.',
                    ),
                    _PolicySection(
                      icon: Icons.share_outlined,
                      title: 'Information Sharing',
                      body:
                          'We do not sell or share your personal information with third parties for their marketing purposes. We may share your information with pharmacies to fulfill your orders, and with delivery riders only as necessary to complete your delivery.',
                    ),
                    _PolicySection(
                      icon: Icons.location_on_outlined,
                      title: 'Location Data',
                      body:
                          'We collect your location to show nearby pharmacies and to enable real-time delivery tracking. Location access is only used while the app is active. We do not track your location in the background.',
                    ),
                    _PolicySection(
                      icon: Icons.notifications_outlined,
                      title: 'Push Notifications',
                      body:
                          'We use Firebase Cloud Messaging to send you push notifications about order status updates, delivery progress, and important account information. You can disable notifications at any time through your device settings.',
                    ),
                    _PolicySection(
                      icon: Icons.lock_outline_rounded,
                      title: 'Data Security',
                      body:
                          'We implement industry-standard security measures to protect your personal information. All data is transmitted over encrypted HTTPS connections. Passwords are hashed and never stored in plain text.',
                    ),
                    _PolicySection(
                      icon: Icons.delete_outline_rounded,
                      title: 'Data Retention',
                      body:
                          'We retain your personal data for as long as your account is active. You may request deletion of your account and associated data by contacting our support team at support@rapidsave.rw.',
                    ),
                    _PolicySection(
                      icon: Icons.contact_support_outlined,
                      title: 'Contact Us',
                      body:
                          'If you have any questions about this Privacy Policy, please contact us at:\n\nRapidSave Support\nEmail: support@rapidsave.rw\nKigali, Rwanda',
                    ),
                  ],
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

class _PolicySection {
  final IconData icon;
  final String title;
  final String body;
  const _PolicySection({required this.icon, required this.title, required this.body});
}

class _PolicyCard extends StatelessWidget {
  final Color bg;
  final Color borderColor;
  final Color textPrimary;
  final List<_PolicySection> sections;

  const _PolicyCard({
    required this.bg,
    required this.borderColor,
    required this.textPrimary,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: sections.asMap().entries.map((e) {
          final isLast = e.key == sections.length - 1;
          final s = e.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(10)),
                      child: Icon(s.icon, color: AppColors.teal, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.title, style: GoogleFonts.workSans(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary)),
                          const SizedBox(height: 6),
                          Text(s.body, style: GoogleFonts.workSans(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) Divider(height: 1, indent: 64, color: borderColor),
            ],
          );
        }).toList(),
      ),
    );
  }
}
