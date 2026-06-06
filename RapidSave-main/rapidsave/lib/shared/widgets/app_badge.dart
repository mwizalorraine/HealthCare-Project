import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class AppBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? textColor;
  final double? fontSize;

  const AppBadge({
    super.key,
    required this.text,
    this.color,
    this.textColor,
    this.fontSize,
  });

  factory AppBadge.success(String text) => AppBadge(
    text: text,
    color: AppColors.successLight,
    textColor: AppColors.success,
  );

  factory AppBadge.danger(String text) => AppBadge(
    text: text,
    color: AppColors.dangerLight,
    textColor: AppColors.danger,
  );

  factory AppBadge.warning(String text) => AppBadge(
    text: text,
    color: AppColors.warningLight,
    textColor: AppColors.warning,
  );

  factory AppBadge.teal(String text) => AppBadge(
    text: text,
    color: AppColors.tealLight,
    textColor: AppColors.tealDark,
  );

  factory AppBadge.primary(String text) => AppBadge(
    text: text,
    color: AppColors.primaryPale,
    textColor: AppColors.primary,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? AppColors.tealLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize ?? 11,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.tealDark,
        ),
      ),
    );
  }
}
