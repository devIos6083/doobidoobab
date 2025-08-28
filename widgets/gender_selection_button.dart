import 'package:doobi/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A custom button for gender selection
class GenderSelectionButton extends StatelessWidget {
  /// The gender text to display
  final String gender;

  /// The icon to display
  final IconData icon;

  /// Whether this gender is currently selected
  final bool isSelected;

  /// Callback when button is pressed
  final VoidCallback onPressed;

  const GenderSelectionButton({
    super.key,
    required this.gender,
    required this.icon,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.accent : AppColors.white,
        foregroundColor: isSelected ? AppColors.white : AppColors.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(icon),
          SizedBox(width: 5),
          Text(
            gender,
            style: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
