import 'package:flutter/material.dart';
import 'package:modizk_download/screens/onboarding_screen.dart';
import 'package:modizk_download/services/music_provider.dart';
import 'package:modizk_download/services/storage_service.dart';
import 'package:modizk_download/widgets/rating_dialog.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initToken();
    });
  }

  Future<void> _initToken() async {
    final provider = Provider.of<MusicProvider>(context, listen: false);
    final status = await provider.getUserToken();

    if (status == 2) {
      if (!mounted) return;
      
      // Increment login count
      await StorageService().incrementLoginCount();
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      // final isFirstLaunch = await StorageService().isFirstLaunch();
      // if (isFirstLaunch) {
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      //   );
      // } else {
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (context) => const HomeScreen()),
      //   );
        
      //   // Check if we should show rating prompt after navigation
      //   _checkAndShowRatingPrompt();
      // }

    } else {
      debugPrint("Token fetch failed: ${provider.tokenError}");
    }
  }

  Future<void> _checkAndShowRatingPrompt() async {
    // Wait a bit to ensure home screen is loaded
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (!mounted) return;
    
    final shouldShow = await StorageService().shouldShowRatingPrompt();
    if (shouldShow) {
      _showRatingDialog();
    }
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const RatingDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/logo.jpg',
                width: 150,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const Spacer(flex: 2),
          const Padding(
            padding: EdgeInsets.only(bottom: 32.0),
            child: CircularProgressIndicator(),
          ),
        ],
      ),
    );
  }
}
