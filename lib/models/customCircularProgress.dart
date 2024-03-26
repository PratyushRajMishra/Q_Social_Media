import 'package:flutter/material.dart';

class CustomCircularProgressIndicator extends StatelessWidget {
  final double size;
  final double progressBarWidth;
  final String imagePath;
  final String darkModeImagePath; // Image path for dark mode

  const CustomCircularProgressIndicator({
    Key? key,
    this.size = 200.0,
    this.progressBarWidth = 0.5,
    required this.imagePath,
    required this.darkModeImagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final imageToShow = isDarkMode ? darkModeImagePath : imagePath;

    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          imageToShow,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
        SizedBox(
          width: size + 2 * progressBarWidth, // Adjusted size to leave room for progress indicator
          height: size + 2 * progressBarWidth, // Adjusted size to leave room for progress indicator
          child: CircularProgressIndicator(
            strokeWidth: progressBarWidth, // Set the width of the progress bar
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? Colors.white : Colors.black, // Change color based on theme
            ),
          ),
        ),
      ],
    );
  }
}
