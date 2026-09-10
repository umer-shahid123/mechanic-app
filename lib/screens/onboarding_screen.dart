import 'package:flutter/material.dart';
import 'package:mechanic_app/screens/login_screen.dart';
import 'package:mechanic_app/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                child: Text('Skip', style: TextStyle(color: isDark ? AppColors.darkGrey : AppColors.grey, fontWeight: FontWeight.w600)),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildPage(
                    context,
                    'Car Trouble?\nWe\'ve Got You!',
                    'Get best mechanics, best offers and fast tracking at your doorstep.',
                    'https://img.freepik.com/free-vector/car-service-abstract-concept-vector-illustration-car-maintenance-repair-service-auto-diagnostic-center-tire-inflation-break-fix-engine-inspection-scheduled-maintenance-abstract-metaphor_335657-2877.jpg',
                    isDark,
                  ),
                  _buildPage(
                    context,
                    'Fast & Reliable\nService',
                    'Our verified mechanics ensure high quality service for your vehicle.',
                    'https://img.freepik.com/free-vector/auto-service-abstract-concept-illustration_335657-1842.jpg',
                    isDark,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(2, (index) => _buildDot(index, isDark)),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < 1) {
                        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeIn);
                      } else {
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
                      }
                    },
                    child: Text(_currentPage < 1 ? 'Next' : 'Get Started'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: _currentPage == index ? (isDark ? AppColors.neonGreen : AppColors.primary) : (isDark ? Colors.white10 : Colors.grey[200]),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildPage(BuildContext context, String title, String desc, String img, bool isDark) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              height: MediaQuery.of(context).size.height * 0.35,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Image.network(img, fit: BoxFit.contain),
            ),
            const SizedBox(height: 40),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 24,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              desc,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.darkGrey : AppColors.grey,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
