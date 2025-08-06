
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox.shrink()
          : Icon(icon, color: Colors.black),
      label: isLoading
          ? const CircularProgressIndicator(color: Colors.black)
          : Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
            ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.black,
        minimumSize: Size(double.infinity, 56.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
      ),
    );
  }
}