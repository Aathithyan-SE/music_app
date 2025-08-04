import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme.dart';
import '../services/storage_service.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int selectedRating = 0;
  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: MyColors.secondaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Column(
        children: [
          Text(
            '🌟 You\'re awesome! 🙏',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: MyColors.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Thanks for using our app! 🎶',
            style: TextStyle(
              fontSize: 16,
              color: MyColors.primaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Love the music? ⭐',
            style: TextStyle(
              fontSize: 16,
              color: MyColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Give us ★★★★★ 💖',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: MyColors.primaryAccent,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final rating = index + 1;
              return GestureDetector(
                onTap: () => _selectRating(rating),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: selectedRating >= rating 
                        ? MyColors.primaryAccent 
                        : MyColors.primaryBackground,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: MyColors.primaryAccent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$rating',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: selectedRating >= rating 
                            ? Colors.white 
                            : MyColors.primaryAccent,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          if (selectedRating > 0) ...[
            const SizedBox(height: 16),
            Text(
              selectedRating == 5 
                  ? 'Awesome! This will take you to the store 🚀'
                  : 'Thanks for your feedback! 😊',
              style: TextStyle(
                fontSize: 12,
                color: MyColors.secondaryText,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _dismissDialog(),
          child: Text(
            'Maybe Later',
            style: TextStyle(
              color: MyColors.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (selectedRating > 0)
          ElevatedButton(
            onPressed: isSubmitting ? null : () => _submitRating(),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyColors.primaryAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Submit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
      ],
    );
  }

  void _selectRating(int rating) {
    setState(() {
      selectedRating = rating;
    });
  }

  void _dismissDialog() {
    Navigator.of(context).pop();
  }

  Future<void> _submitRating() async {
    if (selectedRating == 0) return;

    setState(() {
      isSubmitting = true;
    });

    // Mark rating prompt as shown
    await StorageService().setRatingPromptShown();

    if (selectedRating == 5) {
      // Open Google Play Store
      await _openPlayStore();
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _openPlayStore() async {
    const androidPackageName = 'com.mycompany.CounterApp'; // Replace with your actual package name
    final Uri playStoreUri = Uri.parse('https://play.google.com/store/apps/details?id=$androidPackageName');
    
    try {
      final bool canLaunch = await canLaunchUrl(playStoreUri);
      if (canLaunch) {
        await launchUrl(
          playStoreUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback to web version
        final Uri webUri = Uri.parse('https://play.google.com/store/apps/details?id=$androidPackageName');
        await launchUrl(webUri);
      }
    } catch (e) {
      debugPrint('Error opening Play Store: $e');
      // Show error message if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Unable to open Play Store'),
            backgroundColor: MyColors.secondaryBackground,
          ),
        );
      }
    }
  }
}