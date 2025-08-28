// ignore_for_file: deprecated_member_use

import 'package:doobi/models/words.dart';
import 'package:doobi/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

/// 결과 오버레이 위젯
///
/// 사용자가 문제에 답변한 후 결과를 표시하는 오버레이 위젯입니다.
class ResultOverlay extends StatelessWidget {
  final Animation<double> animation;
  final bool isCorrect;
  final Word word;
  final bool isLastQuestion;

  const ResultOverlay({
    super.key,
    required this.animation,
    required this.isCorrect,
    required this.word,
    required this.isLastQuestion,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 결과 아이콘
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green : Colors.red,
                  size: 60,
                ),

                const SizedBox(height: 15),

                // 결과 텍스트
                Text(
                  isCorrect ? '정답입니다!' : '아쉽네요!',
                  style: GoogleFonts.quicksand(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isCorrect ? Colors.green : Colors.red,
                  ),
                ),

                const SizedBox(height: 20),

                // 단어 정보
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color:
                        isCorrect
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      // 단어
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            word.word,
                            style: GoogleFonts.quicksand(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            word.meaning,
                            style: GoogleFonts.quicksand(
                              fontSize: 20,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 카테고리
                      Text(
                        '카테고리: ${word.category}',
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // 힌트 또는 응원 메시지
                Text(
                  isCorrect
                      ? '잘 하고 있어요! ${isLastQuestion ? '마지막 문제입니다!' : '계속 진행해보세요!'}'
                      : '힌트: ${word.hint}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 완료 화면 위젯
///
/// 모든 학습을 완료했을 때 보여주는 결과 화면입니다.
class CompletionScreen extends StatelessWidget {
  final int correctCount;
  final int totalCount;

  const CompletionScreen({
    super.key,
    required this.correctCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
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
            errorBuilder:
                (context, error, stackTrace) => const Icon(
                  Icons.celebration,
                  size: 100,
                  color: Colors.amber,
                ),
          ),

          const SizedBox(height: 30),

          // 완료 텍스트
          Text(
            '학습 완료!',
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
}

/// 연결선 그리기 위한 CustomPainter
///
/// 연결 게임에서 단어와 뜻을 연결할 때 사용하는 선을 그리는 위젯입니다.
class ConnectionLinePainter extends CustomPainter {
  final List<int?> connections;
  final Color color;

  ConnectionLinePainter({required this.connections, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = color
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    // 왼쪽 카드의 세로 위치 계산 (각 카드의 중앙)
    List<double> leftPositions = [25, 85, 145, 205];
    // 오른쪽 카드의 세로 위치 계산 (각 카드의 중앙)
    List<double> rightPositions = [25, 85, 145, 205];

    // 각 연결선 그리기
    for (int i = 0; i < connections.length; i++) {
      if (connections[i] != null) {
        final Offset start = Offset(0, leftPositions[i]);
        final Offset end = Offset(size.width, rightPositions[connections[i]!]);

        // 곡선으로 연결선 그리기
        final Path path = Path();
        path.moveTo(start.dx, start.dy);

        // 베지어 곡선 제어점
        final double controlX1 = size.width * 0.3;
        final double controlX2 = size.width * 0.7;

        path.cubicTo(controlX1, start.dy, controlX2, end.dy, end.dx, end.dy);

        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
