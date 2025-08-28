// widgets/loading_quiz.dart
// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:doobi/models/words.dart';
import 'package:doobi/utils/constants.dart';
import 'package:doobi/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoadingQuiz extends StatefulWidget {
  final List<Word> learnedWords;

  const LoadingQuiz({super.key, required this.learnedWords});

  @override
  State<LoadingQuiz> createState() => _LoadingQuizState();
}

class _LoadingQuizState extends State<LoadingQuiz> {
  late Word _currentWord;
  late List<String> _options;
  String? _selectedOption;
  bool _showResult = false;
  bool _isCorrect = false;
  int _score = 0;
  int _questionCount = 0;

  @override
  void initState() {
    super.initState();
    _generateNewQuestion();
  }

  // 새로운 문제 생성
  void _generateNewQuestion() {
    if (widget.learnedWords.isEmpty) return;

    // 랜덤 단어 선택
    final random = Random();
    _currentWord =
        widget.learnedWords[random.nextInt(widget.learnedWords.length)];

    // 보기 생성 (정답 + 오답 3개)
    final List<String> allMeanings =
        widget.learnedWords.map((word) => word.meaning).toSet().toList();

    // 정답을 제외한 다른 보기들
    allMeanings.remove(_currentWord.meaning);
    allMeanings.shuffle();

    // 최종 보기 생성 (정답 + 랜덤 오답 3개)
    _options = [_currentWord.meaning];
    _options.addAll(allMeanings.take(3));
    _options.shuffle();

    setState(() {
      _selectedOption = null;
      _showResult = false;
    });

    AppLogger.info('로딩 퀴즈 문제 생성: ${_currentWord.word}');
  }

  // 보기 선택 처리
  void _selectOption(String option) {
    if (_showResult) return;

    setState(() {
      _selectedOption = option;
      _showResult = true;
      _isCorrect = option == _currentWord.meaning;

      if (_isCorrect) {
        _score++;
      }

      _questionCount++;
    });

    // 1.5초 후 다음 문제
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _generateNewQuestion();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.learnedWords.isEmpty) {
      return const Center(child: Text('학습한 단어가 없습니다.'));
    }

    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 퀴즈 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 퀴즈 제목
                Row(
                  children: [
                    const Icon(Icons.quiz, color: AppColors.accent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '미니 퀴즈',
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),

                // 점수
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '점수: $_score',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // 문제 설명
            Text(
              '스토리가 생성되는 동안 퀴즈를 풀어보세요!',
              style: GoogleFonts.quicksand(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // 문제 (영어 단어)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _currentWord.word,
                style: GoogleFonts.quicksand(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 8),

            // 힌트 표시 (단어 카테고리)
            Text(
              '카테고리: ${_currentWord.category}',
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // 보기 목록
            ...List.generate(_options.length, (index) {
              final option = _options[index];

              // 정답 여부에 따른 색상
              Color backgroundColor = Colors.white;
              Color textColor = AppColors.textPrimary;

              if (_showResult && option == _selectedOption) {
                backgroundColor = _isCorrect ? Colors.green : Colors.red;
                textColor = Colors.white;
              } else if (_showResult &&
                  option == _currentWord.meaning &&
                  !_isCorrect) {
                backgroundColor = Colors.green.withOpacity(0.7);
                textColor = Colors.white;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ElevatedButton(
                  onPressed: _showResult ? null : () => _selectOption(option),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: backgroundColor,
                    foregroundColor: textColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  child: Text(
                    option,
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight:
                          _showResult &&
                                  (option == _selectedOption ||
                                      option == _currentWord.meaning)
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),

            // 결과 메시지
            if (_showResult)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      _isCorrect
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isCorrect
                      ? '정답입니다! 👍'
                      : '오답입니다. 정답: ${_currentWord.meaning}',
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _isCorrect ? Colors.green : Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
