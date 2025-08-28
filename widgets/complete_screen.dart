import 'package:doobi/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

/// 퀴즈 완료 화면 위젯
///
/// 모든 문제를 풀었을 때 보여주는 결과 화면입니다.
class QuizCompletedScreen extends StatelessWidget {
  /// 맞춘 문제 수
  final int correctCount;

  /// 총 문제 수
  final int totalCount;

  /// 획득한 포인트 (없으면 기본값 0)
  final int earnedPoints;

  const QuizCompletedScreen({
    super.key,
    required this.correctCount,
    required this.totalCount,
    this.earnedPoints = 0, // 기본값 설정하여 기존 호출 코드와의 호환성 유지
  });

  @override
  Widget build(BuildContext context) {
    // 정답률 계산
    final double correctRate =
        totalCount > 0 ? (correctCount / totalCount * 100) : 0;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 축하 애니메이션
          Lottie.asset(
            'lottie/correct.json',
            width: 200,
            height: 200,
            repeat: true,
          ),

          const SizedBox(height: 30),

          // 퀴즈 완료 텍스트
          Text(
            '퀴즈 완료!',
            style: GoogleFonts.quicksand(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),

          const SizedBox(height: 16),

          // 결과 텍스트
          Text(
            '총 $correctCount/$totalCount문제 정답',
            style: GoogleFonts.quicksand(
              fontSize: 24,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 10),

          // 정답률 표시
          Text(
            '정답률: ${correctRate.toStringAsFixed(1)}%',
            style: GoogleFonts.quicksand(
              fontSize: 18,
              color: _getScoreColor(correctRate),
              fontWeight: FontWeight.bold,
            ),
          ),

          // 획득한 포인트 표시 (추가)
          if (earnedPoints > 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(
                    '+$earnedPoints 별 획득!',
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),

          // 돌아가기 버튼
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            icon: const Icon(Icons.arrow_back),
            label: Text(
              '돌아가기',
              style: GoogleFonts.quicksand(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 정답률에 따른 색상 반환
  Color _getScoreColor(double rate) {
    if (rate >= 80) {
      return Colors.green;
    } else if (rate >= 60) {
      return Colors.blue;
    } else if (rate >= 40) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}
