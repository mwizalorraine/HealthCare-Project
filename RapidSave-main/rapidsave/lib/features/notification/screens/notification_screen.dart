import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../data/services/fcm_service.dart';
import '../../../data/services/notification_service.dart';
import '../../../shared/widgets/app_loader.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final _notifService = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final list = await _notifService.getNotifications(limit: 50);
      if (mounted) setState(() => _notifications = list);
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _unreadCount => _notifications.where((n) => n['is_read'] == false).length;

  Future<void> _markAllRead() async {
    try {
      await _notifService.markAllAsRead();
      setState(() {
        for (final n in _notifications) n['is_read'] = true;
      });
    } catch (_) {}
  }

  Future<void> _markRead(Map<String, dynamic> n) async {
    if (n['is_read'] == true) return;
    try {
      await _notifService.markAsRead(n['_id'] as String);
      setState(() => n['is_read'] = true);
    } catch (_) {}
  }

  void _delete(String id) => setState(() => _notifications.removeWhere((n) => n['_id'] == id));

  Future<void> _showTokenDialog() async {
    final token = await FcmService().getToken();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('FCM Device Token', style: GoogleFonts.workSans(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Copy this token and paste it in Firebase Console → Send test message → Add an FCM registration token.',
                style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.tealLight.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
              child: SelectableText(
                token ?? 'Token not available — make sure you are logged in.',
                style: GoogleFonts.workSans(fontSize: 11, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.workSans(color: AppColors.textSecondary)),
          ),
          if (token != null)
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.teal),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: token));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Token copied to clipboard', style: GoogleFonts.workSans(color: Colors.white)),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(16),
                ));
              },
              child: Text('Copy', style: GoogleFonts.workSans(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Future<void> _sendTest() async {
    setState(() => _testing = true);
    try {
      await _notifService.sendTestNotification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Test notification sent! Check your device.', style: GoogleFonts.workSans(color: Colors.white)),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
      await Future.delayed(const Duration(seconds: 2));
      _fetch(); // refresh list so the new test notification appears
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString(), style: GoogleFonts.workSans(color: Colors.white)),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  String _formatTime(String? raw) {
    if (raw == null) return '';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d').format(dt.toLocal());
  }

  _NotifStyle _styleFor(String type) {
    switch (type) {
      case 'order_confirmed': return _NotifStyle(Icons.check_circle_rounded, AppColors.teal, AppColors.tealLight);
      case 'order_ready': return _NotifStyle(Icons.storefront_rounded, AppColors.success, AppColors.successLight);
      case 'order_cancelled': return _NotifStyle(Icons.cancel_rounded, AppColors.danger, AppColors.dangerLight);
      case 'payment_verified': return _NotifStyle(Icons.payment_rounded, AppColors.primary, AppColors.primaryPale);
      case 'payment_rejected': return _NotifStyle(Icons.payment_rounded, AppColors.danger, AppColors.dangerLight);
      case 'delivery': return _NotifStyle(Icons.delivery_dining_rounded, AppColors.accent, AppColors.accentLight);
      case 'chat': return _NotifStyle(Icons.chat_bubble_rounded, AppColors.primary, AppColors.primaryPale);
      default: return _NotifStyle(Icons.notifications_rounded, AppColors.teal, AppColors.tealLight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(settingsProvider).isDark;
    final scaffoldBg = isDark ? AppColors.darkScaffold : AppColors.scaffold;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final unread = _notifications.where((n) => n['is_read'] == false).toList();
    final read = _notifications.where((n) => n['is_read'] == true).toList();

    return Scaffold(
      backgroundColor: scaffoldBg,
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
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Notifications', style: GoogleFonts.workSans(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                          if (_unreadCount > 0)
                            Text('$_unreadCount unread', style: GoogleFonts.workSans(fontSize: 13, color: Colors.white70)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: _testing ? null : _sendTest,
                      onLongPress: _showTokenDialog,
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _testing
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.science_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                    if (_unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _markAllRead,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                          child: Text('Mark all read', style: GoogleFonts.workSans(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // ── List ──────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const AppLoader()
                : _notifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.grey300),
                        const SizedBox(height: 16),
                        Text('No notifications', style: GoogleFonts.workSans(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetch,
                    color: AppColors.teal,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                      children: [
                        if (unread.isNotEmpty) ...[
                          _SectionLabel(label: 'New', textColor: AppColors.textSecondary),
                          const SizedBox(height: 8),
                          ...unread.map((n) => _NotificationTile(
                            notification: n,
                            style: _styleFor(n['type'] as String? ?? ''),
                            formatTime: _formatTime,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            onTap: () => _markRead(n),
                            onDismiss: () => _delete(n['_id'] as String),
                          )),
                          const SizedBox(height: 16),
                        ],
                        if (read.isNotEmpty) ...[
                          _SectionLabel(label: 'Earlier', textColor: AppColors.textSecondary),
                          const SizedBox(height: 8),
                          ...read.map((n) => _NotificationTile(
                            notification: n,
                            style: _styleFor(n['type'] as String? ?? ''),
                            formatTime: _formatTime,
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textPrimary: textPrimary,
                            onTap: () {},
                            onDismiss: () => _delete(n['_id'] as String),
                          )),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _NotifStyle {
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _NotifStyle(this.icon, this.color, this.bgColor);
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color textColor;
  const _SectionLabel({required this.label, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: GoogleFonts.workSans(fontSize: 13, fontWeight: FontWeight.w700, color: textColor));
  }
}

class _NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final _NotifStyle style;
  final String Function(String?) formatTime;
  final Color cardBg;
  final Color borderColor;
  final Color textPrimary;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationTile({
    required this.notification,
    required this.style,
    required this.formatTime,
    required this.cardBg,
    required this.borderColor,
    required this.textPrimary,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = notification['is_read'] as bool? ?? true;
    final unreadBg = AppColors.tealLight.withValues(alpha: 0.18);

    return Dismissible(
      key: Key(notification['_id'] as String),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead ? cardBg : unreadBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isRead ? borderColor : AppColors.teal.withValues(alpha: 0.35), width: 0.5),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(color: style.bgColor, borderRadius: BorderRadius.circular(14)),
                child: Icon(style.icon, color: style.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(notification['title'] as String? ?? '', style: GoogleFonts.workSans(fontSize: 13, fontWeight: isRead ? FontWeight.w600 : FontWeight.w700, color: textPrimary))),
                        if (!isRead) Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.teal)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(notification['body'] as String? ?? '', style: GoogleFonts.workSans(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
                    const SizedBox(height: 6),
                    Text(formatTime(notification['createdAt'] as String?), style: GoogleFonts.workSans(fontSize: 11, color: AppColors.textHint)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
