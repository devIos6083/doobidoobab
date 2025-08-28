// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 게임 선택 카드 위젯
///
/// 각 게임 옵션을 시각적인 카드로 표시합니다.
class GameCard extends StatelessWidget {
  /// 게임 제목
  final String title;

  /// 게임 설명
  final String description;

  /// 게임 아이콘
  final IconData icon;

  /// 게임 카드 색상
  final Color color;

  /// 게임 이미지 경로
  final String image;

  /// 게임 사용 가능 여부
  final bool isAvailable;

  /// 카드 클릭 시 콜백
  final VoidCallback onTap;

  const GameCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.image,
    required this.isAvailable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // 준비 중 배지 (사용 불가능한 경우)
                if (!isAvailable)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                      child: Text(
                        '준비 중',
                        style: GoogleFonts.quicksand(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // 카드 내용
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 이미지
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(
                        image,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // 이미지 로드 실패 시 아이콘 표시
                          return Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, size: 40, color: Colors.white),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 게임 제목
                    Text(
                      title,
                      style: GoogleFonts.quicksand(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    // 게임 설명
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        description,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),

                    // 사용 불가능한 경우 흐리게 표시
                    if (!isAvailable)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
