
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sentia_flow/features/nourish_flow/models/nourish_feature_model.dart';
import 'package:sentia_flow/features/nourish_flow/screens/nourish_input_screen.dart';
import 'package:sentia_flow/widgets/spacing_widget.dart';

class NourishHomeScreen extends StatelessWidget {
  const NourishHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Le Scaffold n'a plus besoin de son propre AppBar.
    // Il sera affiché dans le corps du Scaffold de MainShell.
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Hello!",
                style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface),
              ),
              const HeightSpace(8),
              Text(
                "What would you like to do today?",
                style: TextStyle(
                    fontSize: 18.sp,
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(179)),
              ),
              const HeightSpace(30),
              ...nourishFeatures.map((feature) {
                return Card(
                  elevation: 4,
                  margin: EdgeInsets.only(bottom: 16.h),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              NourishInputScreen(feature: feature),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10.r),
                            child: Image.asset(
                              feature.imagePath,
                              width: 70.w,
                              height: 70.h,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const WidthSpace(16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  feature.name,
                                  style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface),
                                ),
                                const HeightSpace(6),
                                Text(
                                  feature.description,
                                  style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Theme.of(context).colorScheme.onSurface.withAlpha(179)),
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}




