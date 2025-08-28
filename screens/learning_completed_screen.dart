// widgets/learning_completed_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'dart:typed_data';

import 'package:confetti/confetti.dart';
import 'package:doobi/models/words.dart';
import 'package:doobi/screens/story_generated_screen.dart';
import 'package:doobi/services/drawing_service.dart';
import 'package:doobi/utils/constants.dart';
import 'package:doobi/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class LearningCompletedScreen extends StatefulWidget {
  final int correctCount;
  final int totalAnswered;
  final List<Word> learnedWords;
  final Map<String, Uint8List> drawings;

  const LearningCompletedScreen({
    super.key,
    required this.correctCount,
    required this.totalAnswered,
    required this.learnedWords,
    required this.drawings,
  });

  @override
  State<LearningCompletedScreen> createState() =>
      _LearningCompletedScreenState();
}

class _LearningCompletedScreenState extends State<LearningCompletedScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    // 축하 효과 컨트롤러
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // 축하 효과 재생
    _confettiController.play();

    AppLogger.event(
      '학습 완료: 정답=${widget.correctCount}, 총문제=${widget.totalAnswered}',
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 성공률 계산
    final double successRate =
        widget.totalAnswered > 0
            ? widget.correctCount / widget.totalAnswered
            : 0.0;

    return Stack(
      children: [
        Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 뒤로가기 버튼
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: AppColors.accent,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),

                  // 제목
                  Text(
                    '학습 결과',
                    style: GoogleFonts.quicksand(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),

                  // 오른쪽 공간 균형용
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // 결과 내용
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 축하 애니메이션
                      Lottie.asset(
                        'lottie/correct.json',
                        width: 150,
                        height: 150,
                        repeat: true,
                        errorBuilder:
                            (context, error, stackTrace) => const Icon(
                              Icons.celebration,
                              size: 80,
                              color: Colors.amber,
                            ),
                      ),

                      const SizedBox(height: 16),

                      // 점수 표시
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 맞은 개수 / 총 문제수
                            Text(
                              '${widget.correctCount}/${widget.totalAnswered}',
                              style: GoogleFonts.quicksand(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),

                            // 성공률
                            Text(
                              '${(successRate * 100).toInt()}%',
                              style: GoogleFonts.quicksand(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 학습한 단어 표시
                      if (widget.learnedWords.isNotEmpty)
                        Column(
                          children: [
                            Text(
                              '학습한 단어',
                              style: GoogleFonts.quicksand(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Column(
                                children:
                                    widget.learnedWords.map((word) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              word.word,
                                              style: GoogleFonts.quicksand(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.accent,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              '- ${word.meaning}',
                                              style: GoogleFonts.quicksand(
                                                fontSize: 16,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 30),

                      // 버튼들
                      Column(
                        children: [
                          // 네컷 만화 그리러 가기 버튼 (메인 버튼)
                          ElevatedButton.icon(
                            onPressed:
                                widget.learnedWords.isNotEmpty &&
                                        widget.drawings.isNotEmpty
                                    ? () => _navigateToStoryGeneration(context)
                                    : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            icon: const Icon(Icons.auto_stories, size: 24),
                            label: Text(
                              '네컷 만화 그리러 가기',
                              style: GoogleFonts.quicksand(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // 메인 메뉴 버튼
                          TextButton.icon(
                            onPressed: () {
                              // 메인 화면으로 돌아가기
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              padding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                            icon: const Icon(Icons.home_outlined, size: 20),
                            label: Text(
                              '메인 메뉴로',
                              style: GoogleFonts.quicksand(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // 축하 효과
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            particleDrag: 0.05,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.2,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.pink,
              Colors.orange,
              Colors.purple,
              Colors.red,
              Colors.yellow,
            ],
          ),
        ),
      ],
    );
  }

  // 스토리 생성 화면으로 이동
  void _navigateToStoryGeneration(BuildContext context) {
    AppLogger.event('스토리 생성 화면으로 이동');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => StoryGenerationScreen(
              learnedWords: widget.learnedWords,
              drawings: widget.drawings,
            ),
      ),
    );
  }
}
