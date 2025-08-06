import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // 1. Import the package
import 'package:provider/provider.dart';
import 'package:sentia_flow/services/onboarding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentia_flow/features/onboarding/onboarding_screen.dart';
import 'package:sentia_flow/features/shell/main_shell.dart';
import 'package:sentia_flow/services/gemma_service.dart';
import 'package:sentia_flow/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final sharedPreferences = await SharedPreferences.getInstance();
  final onboardingService = OnboardingService(
    sharedPreferences: sharedPreferences,
  );
  final gemmaService = GemmaService();

  runApp(
    Provider<GemmaService>(
      create: (_) => gemmaService,
      dispose: (_, service) => service.dispose(),
      child: MyApp(onboardingService: onboardingService),
    ),
  );
}

class MyApp extends StatelessWidget {
  final OnboardingService onboardingService;

  const MyApp({super.key, required this.onboardingService});

  @override
  Widget build(BuildContext context) {
    // 2. Wrap MaterialApp with ScreenUtilInit
    return ScreenUtilInit(
      // The design size of your Figma design or reference device
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      // Use the builder method to return your MaterialApp
      builder: (_, child) {
        return MaterialApp(
          title: 'SentiaFlow',
          debugShowCheckedModeBanner: false,
          // Utilisez lightTheme ici
          theme: AppTheme.lightTheme,
          themeMode: ThemeMode.light, // Forcer le mode clair
          // The child parameter from the builder is your home screen
          home: child,
        );
      },
      // Pass the initial screen as the child of ScreenUtilInit
      child: onboardingService.isFirstTime()
          ? OnboardingScreen(onboardingService: onboardingService)
          : const MainShell(),
    );
  }
}

//  For Dark theme 
// @override
//   Widget build(BuildContext context) {
//     // 2. Wrap MaterialApp with ScreenUtilInit
//     return ScreenUtilInit(
//       // The design size of your Figma design or reference device
//       designSize: const Size(375, 812),
//       minTextAdapt: true,
//       splitScreenMode: true,
//       // Use the builder method to return your MaterialApp
//       builder: (_, child) {
//         return MaterialApp(
//           title: 'SentiaFlow',
//           debugShowCheckedModeBanner: false,
//           // --- DÉBUT DE LA CORRECTION ---
//           theme: AppTheme.darkTheme,          // Thème par défaut
//           darkTheme: AppTheme.darkTheme,      // Spécifier explicitement le thème sombre
//           themeMode: ThemeMode.dark,          // CRUCIAL : Force l'application à TOUJOURS utiliser le mode sombre
//           // --- FIN DE LA CORRECTION ---
//           // The child parameter from the builder is your home screen
//           home: child,
//         );
//       },
//       // Pass the initial screen as the child of ScreenUtilInit
//       child: onboardingService.isFirstTime()
//           ? OnboardingScreen(onboardingService: onboardingService)
//           : const MainShell(),
//     );
//   }
// }