// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 성취 및 정보 카드 위젯
///
/// 사용자의 성취 또는 정보를 카드 형태로 표시합니다.
class AchievementCard extends StatelessWidget {
  /// 카드 제목
  final String title;

  /// 표시할 값
  final String value;

  /// 아이콘
  final IconData icon;

  /// 카드 색상
  final Color color;

  /// 카드 높이
  final double height;

  const AchievementCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: height,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              color.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아이콘
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),

            const Spacer(),

            // 제목
            Text(
              title,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 4),

            // 값
            Text(
              value,
              style: GoogleFonts.quicksand(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
