// ignore_for_file: deprecated_member_use

import 'package:doobi/models/words.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

/// 퀴즈 결과 오버레이 위젯
///
/// 정답/오답 결과를 애니메이션과 함께 표시하는 오버레이 위젯입니다.
class QuizResultOverlay extends StatelessWidget {
  /// 애니메이션 컨트롤러
  final Animation<double> animation;

  /// 정답 여부
  final bool isCorrect;

  /// 현재 단어 데이터
  final Word word;

  /// 마지막 문제 여부
  final bool isLastQuestion;

  const QuizResultOverlay({
    super.key,
    required this.animation,
    required this.isCorrect,
    required this.word,
    required this.isLastQuestion,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return FadeTransition(
          opacity: animation,
          child: Container(
            color: Colors.black.withOpacity(0.7),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 애니메이션
                  Lottie.asset(
                    isCorrect ? 'lottie/cake.json' : 'lottie/incorrect.json',
                    width: 200,
                    height: 200,
                    repeat: true,
                  ),

                  const SizedBox(height: 20),

                  // 결과 텍스트
                  Text(
                    isCorrect ? '정답입니다!' : '다시 도전해 보세요!',
                    style: GoogleFonts.quicksand(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 정답 단어 표시
                  Text(
                    '"${word.word}" (${word.meaning})',
                    style: GoogleFonts.quicksand(
                      fontSize: 22,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 다음 단어 표시
                  Text(
                    isLastQuestion ? '마지막 문제였습니다!' : '잠시 후 다음 단어가 나타납니다...',
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
