import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AppLoader extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLoader({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.teal),
        ),
      ),
    );
  }
}

class AppFullLoader extends StatelessWidget {
  const AppFullLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: AppLoader()));
  }
}
