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

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _tokenCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _success = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Password strength
  int get _strength {
    final p = _passCtrl.text;
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 6) score++;
    if (p.length >= 10) score++;
    if (p.contains(RegExp(r'[A-Z]'))) score++;
    if (p.contains(RegExp(r'[0-9]'))) score++;
    if (p.contains(RegExp(r'[!@#\$%^&*]'))) score++;
    return score;
  }

  String get _strengthLabel {
    switch (_strength) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
      case 3:
        return 'Fair';
      case 4:
        return 'Strong';
      case 5:
        return 'Very Strong';
      default:
        return '';
    }
  }

  Color get _strengthColor {
    switch (_strength) {
      case 0:
      case 1:
        return AppColors.danger;
      case 2:
      case 3:
        return AppColors.accent;
      case 4:
        return AppColors.teal;
      case 5:
        return AppColors.success;
      default:
        return AppColors.border;
    }
  }

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
    _tokenCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final error = await ref
        .read(authProvider.notifier)
        .resetPassword(
          token: _tokenCtrl.text.trim(),
          newPassword: _passCtrl.text,
        );

    if (!mounted) return;
    if (error != null) {
      AppUtils.showError(error);
    } else {
      setState(() => _success = true);
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
                      onTap: () => context.go('/forgot-password'),
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
                          // Animated icon
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
                                child: _success
                                    ? const Icon(
                                        key: ValueKey('done'),
                                        Icons.verified_rounded,
                                        size: 56,
                                        color: AppColors.success,
                                      )
                                    : const Icon(
                                        key: ValueKey('key'),
                                        Icons.key_rounded,
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
                              key: ValueKey(_success),
                              _success ? 'Password Reset!' : 'Reset Password',
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
                              key: ValueKey('sub$_success'),
                              _success
                                  ? 'Your password has been updated\nsuccessfully'
                                  : 'Enter the token from your email\nand set a new password',
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
                      child: _success
                          ? _SuccessView(onLogin: () => context.go('/login'))
                          : _ResetForm(
                              formKey: _formKey,
                              tokenCtrl: _tokenCtrl,
                              passCtrl: _passCtrl,
                              confirmCtrl: _confirmCtrl,
                              isLoading: isLoading,
                              strength: _strength,
                              strengthLabel: _strengthLabel,
                              strengthColor: _strengthColor,
                              onReset: _reset,
                              onPasswordChanged: () => setState(() {}),
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

// ── Reset form ────────────────────────────────────────────────────────────────
class _ResetForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController tokenCtrl;
  final TextEditingController passCtrl;
  final TextEditingController confirmCtrl;
  final bool isLoading;
  final int strength;
  final String strengthLabel;
  final Color strengthColor;
  final VoidCallback onReset;
  final VoidCallback onPasswordChanged;

  const _ResetForm({
    required this.formKey,
    required this.tokenCtrl,
    required this.passCtrl,
    required this.confirmCtrl,
    required this.isLoading,
    required this.strength,
    required this.strengthLabel,
    required this.strengthColor,
    required this.onReset,
    required this.onPasswordChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        key: const ValueKey('form'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Token field
          AppTextField(
            label: 'Reset Token',
            hint: 'Paste the token from your email',
            controller: tokenCtrl,
            prefixIcon: Icons.vpn_key_outlined,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Token is required';
              return null;
            },
          ),

          const SizedBox(height: 16),

          // New password
          AppTextField(
            label: 'New Password',
            hint: 'Enter new password',
            controller: passCtrl,
            isPassword: true,
            prefixIcon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.next,
            onChanged: (_) => onPasswordChanged(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Password is required';
              if (v.length < 6) return 'Minimum 6 characters';
              return null;
            },
          ),

          // Strength indicator
          if (passCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: strength / 5,
                      backgroundColor: AppColors.grey200,
                      valueColor: AlwaysStoppedAnimation(strengthColor),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  strengthLabel,
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: strengthColor,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Confirm password
          AppTextField(
            label: 'Confirm Password',
            hint: 'Re-enter new password',
            controller: confirmCtrl,
            isPassword: true,
            prefixIcon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => onReset(),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm password';
              if (v != passCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),

          const SizedBox(height: 8),

          // Password tips
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Password tips',
                  style: GoogleFonts.workSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                _Tip(
                  met: passCtrl.text.length >= 6,
                  text: 'At least 6 characters',
                ),
                _Tip(
                  met: passCtrl.text.contains(RegExp(r'[A-Z]')),
                  text: 'One uppercase letter',
                ),
                _Tip(
                  met: passCtrl.text.contains(RegExp(r'[0-9]')),
                  text: 'One number',
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          AppButton(
            text: 'Reset Password',
            onPressed: onReset,
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
}

// ── Tip row ───────────────────────────────────────────────────────────────────
class _Tip extends StatelessWidget {
  final bool met;
  final String text;

  const _Tip({required this.met, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 14,
            color: met ? AppColors.success : AppColors.grey400,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.workSans(
              fontSize: 12,
              color: met ? AppColors.success : AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success view ──────────────────────────────────────────────────────────────
class _SuccessView extends StatelessWidget {
  final VoidCallback onLogin;
  const _SuccessView({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('success'),
      children: [
        // Success card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(color: AppColors.success.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.success,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                'Password Updated Successfully',
                style: GoogleFonts.workSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your password has been reset. You can now sign in with your new password.',
                style: GoogleFonts.workSans(
                  fontSize: 13,
                  color: AppColors.success,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        AppButton(text: 'Sign In Now', onPressed: onLogin),
      ],
    );
  }
}
