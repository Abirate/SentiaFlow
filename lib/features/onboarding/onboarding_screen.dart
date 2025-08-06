import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; // 1. Import the package
import 'package:sentia_flow/constants.dart';
import 'package:sentia_flow/services/onboarding_service.dart';
import 'package:sentia_flow/features/shell/main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  final OnboardingService onboardingService;
  const OnboardingScreen({super.key, required this.onboardingService});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final CarouselSliderController _controller = CarouselSliderController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> onboardingData = [
    {
      "icon": Icons.auto_awesome_outlined,
      "title": "Welcome to SentiaFlow",
      "description":
          "Your personal AI wellness coach. Smart, private, and always available, right on your device."
    },
    {
      "icon": Icons.fitness_center_outlined,
      "title": "Perfect Your Form with ActiveFlow",
      "description":
          "Analyze your exercise posture with AI. Get instant feedback on your form to maximize results and prevent injuries."
    },
    {
      "icon": Icons.restaurant_menu_outlined,
      "title": "Eat Smarter with NourishFlow",
      "description":
          "Turn ingredients into healthy recipes or analyze any meal with a photo. Get personalized nutrition advice based on your health profile."
    }
  ];

  void _completeOnboarding() {
    if (!mounted) return;
    widget.onboardingService.setOnboardingCompleted();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration:  BoxDecoration(
              image: DecorationImage(
                image: AssetImage(onboardingImage),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            color: const Color.fromRGBO(0, 0, 0, 0.6),
          ),
          SafeArea(
            child: Padding(
              // 2. Use responsive padding
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(0, 0, 0, 0.5),
                      borderRadius: BorderRadius.circular(32.r), // Responsive radius
                    ),
                    child: Column(
                      children: [
                        CarouselSlider.builder(
                          carouselController: _controller,
                          itemCount: onboardingData.length,
                          itemBuilder: (context, index, realIndex) {
                            final item = onboardingData[index];
                            return SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    item['icon'],
                                    size: 80.sp, // Responsive icon size
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  SizedBox(height: 30.h), // Responsive height
                                  Text(
                                    item['title']!,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 22.sp, // Responsive font size
                                        ),
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    item['description']!,
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                          color: Colors.white70,
                                          height: 1.5,
                                          fontSize: 15.sp, // Responsive font size
                                        ),
                                  ),
                                ],
                              ),
                            );
                          },
                          options: CarouselOptions(
                            height: 300.h, // Responsive height
                            viewportFraction: 1.0,
                            enlargeCenterPage: false,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentIndex = index;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 20.h),
                        DotsIndicator(
                          dotsCount: onboardingData.length,
                          position: _currentIndex.toDouble(),
                          decorator: DotsDecorator(
                            color: Colors.grey[800]!,
                            activeColor: Theme.of(context).colorScheme.secondary,
                            size: Size.square(9.0.w), // Responsive size
                            activeSize: Size(18.0.w, 9.0.h),
                            activeShape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 30.h),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              if (_currentIndex == onboardingData.length - 1) {
                                _completeOnboarding();
                              } else {
                                _controller.nextPage();
                              }
                            },
                            child: Text(
                              _currentIndex == onboardingData.length - 1
                                  ? "Get Started"
                                  : "Next",
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 48.h,
                          child: _currentIndex != onboardingData.length - 1
                              ? TextButton(
                                  onPressed: _completeOnboarding,
                                  child: Text(
                                    "Skip",
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                )
                              : null,
                        ),
                      ],
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
