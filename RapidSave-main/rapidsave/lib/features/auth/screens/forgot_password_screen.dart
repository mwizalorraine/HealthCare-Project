import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../../../core/utils/app_utils.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (_emailCtrl.text.trim().isEmpty) {
      AppUtils.showError('Please enter your email address');
      return;
    }
    if (!_emailCtrl.text.contains('@')) {
      AppUtils.showError('Please enter a valid email address');
      return;
    }
    FocusScope.of(context).unfocus();

    final error = await ref
        .read(authProvider.notifier)
        .forgotPassword(_emailCtrl.text.trim());

    if (!mounted) return;
    if (error != null) {
      AppUtils.showError(error);
    } else {
      setState(() => _sent = true);
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: Stack(
        children: [
          // Gradient top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: size.height * 0.42,
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
              ),
            ),
          ),

          // White bottom card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: size.height * 0.63,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppDimensions.paddingL,
                0,
                AppDimensions.paddingL,
                padding.bottom + AppDimensions.paddingL,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Back
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => context.go('/login'),
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
                  ),

                  SizedBox(height: size.height * 0.03),

                  // Icon + title
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        children: [
                          // Lock icon
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                child: _sent
                                    ? const Icon(
                                        key: ValueKey('sent'),
                                        Icons.check_circle_rounded,
                                        size: 56,
                                        color: AppColors.success,
                                      )
                                    : const Icon(
                                        key: ValueKey('lock'),
                                        Icons.lock_reset_rounded,
                                        size: 56,
                                        color: AppColors.teal,
                                      ),
                              ),
                            ),
                          ),

                          SizedBox(height: size.height * 0.025),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              key: ValueKey(_sent),
                              _sent ? 'Email Sent!' : 'Forgot Password?',
                              style: GoogleFonts.workSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              key: ValueKey('sub$_sent'),
                              _sent
                                  ? 'Check your inbox for the reset token'
                                  : 'No worries! Enter your email and\nwe\'ll send you a reset code',
                              style: GoogleFonts.workSans(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.85),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: size.height * 0.045),

                  // Form / Success
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      child: _sent
                          ? _SuccessCard(
                              email: _emailCtrl.text.trim(),
                              onReset: () => context.go(
                                '/reset-password',
                                extra: _emailCtrl.text.trim(),
                              ),
                              onResend: _sendReset,
                              onLogin: () => context.go('/login'),
                            )
                          : _EmailForm(
                              controller: _emailCtrl,
                              isLoading: isLoading,
                              onSend: _sendReset,
                              onLogin: () => context.go('/login'),
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

// ── Email form ────────────────────────────────────────────────────────────────
class _EmailForm extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;
  final VoidCallback onLogin;

  const _EmailForm({
    required this.controller,
    required this.isLoading,
    required this.onSend,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.tealLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.teal.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.teal,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'We\'ll send a reset token to your email. Use it on the next screen.',
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    color: AppColors.tealDark,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        AppTextField(
          label: 'Email Address',
          hint: 'Enter your registered email',
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icons.email_outlined,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => onSend(),
        ),

        const SizedBox(height: 28),

        AppButton(
          text: 'Send Reset Code',
          onPressed: onSend,
          isLoading: isLoading,
        ),

        const SizedBox(height: 24),

        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Remember your password? ',
                style: GoogleFonts.workSans(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: onLogin,
                child: Text(
                  'Sign In',
                  style: GoogleFonts.workSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Success card ──────────────────────────────────────────────────────────────
class _SuccessCard extends StatelessWidget {
  final String email;
  final VoidCallback onReset;
  final VoidCallback onResend;
  final VoidCallback onLogin;

  const _SuccessCard({
    required this.email,
    required this.onReset,
    required this.onResend,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('success'),
      children: [
        // Email badge
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.mark_email_read_rounded,
                color: AppColors.success,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reset code sent to',
                      style: GoogleFonts.workSans(
                        fontSize: 12,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: GoogleFonts.workSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Steps
        _StepRow(number: '1', text: 'Open your email inbox'),
        const SizedBox(height: 12),
        _StepRow(number: '2', text: 'Copy the reset token from the email'),
        const SizedBox(height: 12),
        _StepRow(number: '3', text: 'Paste it on the next screen'),

        const SizedBox(height: 28),

        AppButton(text: 'Enter Reset Token', onPressed: onReset),

        const SizedBox(height: 16),

        // Resend + login
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive it? ",
              style: GoogleFonts.workSans(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            GestureDetector(
              onTap: onResend,
              child: Text(
                'Resend',
                style: GoogleFonts.workSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal,
                ),
              ),
            ),
            Text(
              '  •  ',
              style: GoogleFonts.workSans(
                fontSize: 13,
                color: AppColors.textHint,
              ),
            ),
            GestureDetector(
              onTap: onLogin,
              child: Text(
                'Sign In',
                style: GoogleFonts.workSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final String number;
  final String text;

  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.tealLight,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.workSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.tealDark,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.workSans(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
