import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:modizk_download/theme.dart';
import 'package:modizk_download/services/storage_service.dart';
import 'package:modizk_download/screens/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      imageUrl: 'https://pixabay.com/get/gf58da6dcc8d1e1a6957b3d7329f88e73620684307f755ccf7faa8f54ac29864accd11e045524af331e5af5a7d9e97b1c32ee2dbca19b74d5782aa4b9d26f180d_1280.png',
      title: 'Download Your Favorite Music',
      description: 'Discover and download thousands of songs to enjoy offline, anytime and anywhere.',
    ),
    OnboardingPage(
      imageUrl: 'https://pixabay.com/get/g126e017a83ad74631020aed15cb4e301a881bd8bcdd93028675e081e9401419a51770aca5a50efdae6c5715439aaa91a15f85406559606f7b306ec7872876079_1280.jpg',
      title: 'Listen Offline, Anytime, Anywhere',
      description: 'No internet? No problem! Enjoy your music collection even when you\'re offline.',
    ),
    OnboardingPage(
      imageUrl: 'https://pixabay.com/get/g4445b365b2ee15a3292981cb341546b70afbc9d1663234b3940baea4ead8a349c6c1e6c0a0798639349e37300cd26f89cd79f6f16e2ec5d98512335e2133e3ee_1280.png',
      title: 'Smart Playlists for Every Mood',
      description: 'Create custom playlists and discover mood-based collections that match your vibe.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModizkColors.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Padding(
              padding: const EdgeInsets.only(top: 16, right: 16),
              child: Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    'Skip',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ModizkColors.secondaryText,
                    ),
                  ),
                ),
              ),
            ),

            // Page View - Made flexible to take available space
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_pages[index]);
                },
              ),
            ),

            // Page Indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                      (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPage == index
                          ? ModizkColors.primaryAccent
                          : ModizkColors.secondaryText,
                    ),
                  ),
                ),
              ),
            ),

            // Navigation Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  if (_currentPage < _pages.length - 1) ...[
                    // Next Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ModizkColors.primaryAccent,
                          foregroundColor: ModizkColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Next',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: ModizkColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Start Now Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _completeOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ModizkColors.primaryAccent,
                          foregroundColor: ModizkColors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Start Now',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: ModizkColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Continue as Guest Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: TextButton(
                        onPressed: _continueAsGuest,
                        style: TextButton.styleFrom(
                          foregroundColor: ModizkColors.secondaryText,
                        ),
                        child: Text(
                          'Continue as Guest',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: ModizkColors.secondaryText,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Use Flexible for responsive layout
          Flexible(
            flex: 3,
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: 280, // Reduced from 300
                minHeight: 200,
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: ModizkColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.music_note,
                    size: 100,
                    color: ModizkColors.primaryAccent,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32), // Reduced from 48

          // Title
          Flexible(
            child: Text(
              page.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: ModizkColors.primaryText,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 12), // Reduced from 16

          // Description
          Flexible(
            flex: 2,
            child: Text(
              page.description,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: ModizkColors.secondaryText,
                height: 1.4, // Reduced line height from 1.5
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 24), // Added bottom spacing
        ],
      ),
    );
  }

  void _completeOnboarding() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    await storageService.setFirstLaunchComplete();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  void _continueAsGuest() {
    // For now, just proceed to home screen
    // In a full implementation, you might set a guest flag
    _completeOnboarding();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPage {
  final String imageUrl;
  final String title;
  final String description;

  OnboardingPage({
    required this.imageUrl,
    required this.title,
    required this.description,
  });
}