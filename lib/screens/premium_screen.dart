import 'package:flutter/material.dart';
import 'package:modizk_download/theme.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModizkColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true, // Add this line to center the title
        title: const Text(
          'Premium',
          textAlign: TextAlign.center,
        ),
      ),

      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // Lock Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: ModizkColors.secondaryBackground,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: ModizkColors.primaryAccent.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          size: 40,
                          color: ModizkColors.primaryAccent,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Premium Title
                      Text(
                        '🔒 Premium – Coming Soon',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: ModizkColors.primaryText,
                          height: 1.2,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Music Note
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ModizkColors.secondaryBackground,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          '🎵',
                          style: TextStyle(fontSize: 24),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Description Text
                      Text(
                        'We\'re working on\nsomething special.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: ModizkColors.primaryText,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Text(
                        'You\'re already enjoying the music – and soon, there\'ll be even more to explore.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: ModizkColors.secondaryText,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'A new experience is on the way. Stay with us – it\'s worth it. 😊',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: ModizkColors.secondaryText,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String text) {
    return Row(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 18),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            color: ModizkColors.primaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showNotifyDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: ModizkColors.secondaryBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            '🔔 Get Notified',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ModizkColors.primaryText,
            ),
          ),
          content: Text(
            'We\'ll let you know as soon as Premium features are ready! Stay tuned for an amazing music experience.',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: ModizkColors.secondaryText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got it!',
                style: TextStyle(
                  color: ModizkColors.primaryAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}