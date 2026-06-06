import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';

class AppUtils {
  AppUtils._();

  static void showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? AppColors.danger : AppColors.primary,
      textColor: AppColors.white,
      fontSize: 14,
    );
  }

  static void showSuccess(String message) => showToast(message);
  static void showError(String message) => showToast(message, isError: true);

  static String formatDate(DateTime date) =>
      DateFormat('MMM dd, yyyy').format(date);

  static String formatTime(DateTime date) => DateFormat('hh:mm a').format(date);

  static String formatDateTime(DateTime date) =>
      DateFormat('MMM dd, yyyy • hh:mm a').format(date);

  static String formatCurrency(num amount) =>
      '${NumberFormat('#,##0').format(amount)} RWF';

  static String formatDistance(double km) => km < 1
      ? '${(km * 1000).toInt()}m away'
      : '${km.toStringAsFixed(1)}km away';

  static String extractError(dynamic error) {
    if (error is String) return error;
    try {
      return error.error?.toString() ?? 'Something went wrong';
    } catch (_) {
      return 'Something went wrong';
    }
  }

  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
