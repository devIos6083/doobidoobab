// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:doobidoobab/data/models/words.dart';
import 'package:doobidoobab/presentation/widgets/complete_screen.dart';
import 'package:doobidoobab/presentation/widgets/quiz_result.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';

import 'package:doobidoobab/core/utils/constants.dart';
import 'package:doobidoobab/core/utils/logger.dart';
import 'package:doobidoobab/presentation/widgets/drawing_canvas.dart';
import 'package:doobidoobab/presentation/widgets/color_palette.dart';
import 'package:doobidoobab/presentation/widgets/word_card.dart';

class WordQuizScreen extends StatefulWidget {
  // 선택된 난이도와 문제 수를 받는 생성자
  final String difficulty;
  final int quizCount;
  final Function(String)? onWordLearned; 
  const WordQuizScreen({
    super.key,
    required this.difficulty,
    required this.quizCount,
     this.onWordLearned, // 콜백 파라미터 추가
  });

  @override
  _WordQuizScreenState createState() => _WordQuizScreenState();
}

class _WordQuizScreenState extends State<WordQuizScreen>
    with TickerProviderStateMixin {
  // 선택된 난이도에 따른 단어 목록
  late List<Word> _words;

  // 현재 문제 인덱스와 정답 개수
  int _currentQuestionIndex = 0;
  int _correctCount = 0;

  // 현재 단어
  late Word _currentWord;

  // 상태 플래그
  bool _showDrawingCanvas = false;
  bool _showResult = false;
  bool _isCorrect = false;
  bool _quizCompleted = false;
  bool _showHint = false;
  bool _isDrawing = false; // 현재 그리기 중인지 여부

  // 그림 그리기 관련 변수
  Color _selectedColor = Colors.black;
  double _strokeWidth = 5.0;
  List<DrawingPoint> _drawingPoints = [];

  // 애니메이션 컨트롤러
  late AnimationController _wordAnimationController;
  late AnimationController _resultAnimationController;
  late Animation<double> _wordAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    // 단어 필터링 및 섞기
    _words = filterWordsByDifficulty(widget.difficulty);
    _words.shuffle();

    // 총 문제 수 제한
    if (_words.length > widget.quizCount) {
      _words = _words.sublist(0, widget.quizCount);
    }

    // 단어 애니메이션 컨트롤러
    _wordAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _wordAnimation = CurvedAnimation(
      parent: _wordAnimationController,
      curve: Curves.elasticOut,
    );

    // 결과 애니메이션 컨트롤러
    _resultAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // 축하 효과 컨트롤러
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    _selectCurrentWord();

    // 로그 기록
    AppLogger.event(
        '단어 퀴즈 시작: 난이도=${widget.difficulty}, 문제수=${widget.quizCount}');
  }

  @override
  void dispose() {
    _wordAnimationController.dispose();
    _resultAnimationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  /// 현재 문제 단어 선택
  void _selectCurrentWord() {
    // 모든 문제를 다 풀었는지 확인
    if (_currentQuestionIndex >= widget.quizCount ||
        _currentQuestionIndex >= _words.length) {
      setState(() {
        _quizCompleted = true;
      });
      return;
    }

    setState(() {
      _currentWord = _words[_currentQuestionIndex];
      _showDrawingCanvas = false;
      _showResult = false;
      _showHint = false;
      _drawingPoints = [];
      _isDrawing = false;

      // 단어 애니메이션 재생
      _wordAnimationController.reset();
      _wordAnimationController.forward();
    });

    AppLogger.info(
        '새 단어 선택됨: ${_currentWord.word} (${_currentQuestionIndex + 1}/${widget.quizCount})');
  }

  /// 그림 평가 및 결과 표시
  void _evaluateDrawing() {
    // 간단한 랜덤 결과 (실제로는 그림 인식 AI 등으로 대체해야 함)
    final bool result = Random().nextBool();

    // 정답이면 정답 개수 증가
    if (result) {
      _correctCount++;
    }

    setState(() {
      _isCorrect = result;
      _showResult = true;
      _currentQuestionIndex++; // 다음 문제로 인덱스 증가
    });

    // 결과 애니메이션 재생
    _resultAnimationController.reset();
    _resultAnimationController.forward();

    // 정답일 경우 축하 효과
    if (_isCorrect) {
      _confettiController.play();
    }

    // 3초 후 다음 단어로 이동
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _selectCurrentWord();
      }
    });

    AppLogger.info('그림 평가 결과: ${_isCorrect ? "정답" : "오답"}');
  }

  /// 새 경로 시작 - 펜이 화면에 닿았을 때
  void _handlePathStart(Offset position) {
    setState(() {
      _isDrawing = true;

      // 새 경로 시작 표시와 함께 점 추가
      _drawingPoints.add(DrawingPoint(
        offset: position,
        paint: Paint()
          ..color = _selectedColor
          ..isAntiAlias = true
          ..strokeWidth = _strokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke, // 선 스타일로 명시적 설정
        isNewPath: true, // 새로운 경로 시작
      ));
    });
  }

  /// 경로 업데이트 - 펜을 드래그할 때
  void _handlePathUpdate(Offset position) {
    if (!_isDrawing) return;

    setState(() {
      // 같은 경로 내 점 추가 (새 경로 표시 없음)
      _drawingPoints.add(DrawingPoint(
        offset: position,
        paint: Paint()
          ..color = _selectedColor
          ..isAntiAlias = true
          ..strokeWidth = _strokeWidth
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke, // 선 스타일로 명시적 설정
        isNewPath: false, // 기존 경로 연장
      ));
    });
  }

  /// 경로 완료 - 펜을 화면에서 뗐을 때
  void _handlePathEnd() {
    setState(() {
      _isDrawing = false;
    });
  }

  /// 힌트 상태 토글 콜백
  void _toggleHint(bool show) {
    setState(() {
      _showHint = show;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryLight,
              AppColors.secondaryLight,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: _quizCompleted
              ? QuizCompletedScreen(
                  correctCount: _correctCount,
                  totalCount: widget.quizCount,
                )
              : Stack(
                  children: [
                    // 메인 콘텐츠
                    Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: _showDrawingCanvas
                              ? _buildDrawingCanvas()
                              : _buildWordDisplay(),
                        ),
                      ],
                    ),

                    // 결과 오버레이 (정답/오답 표시)
                    if (_showResult)
                      QuizResultOverlay(
                        animation: _resultAnimationController,
                        isCorrect: _isCorrect,
                        word: _currentWord,
                        isLastQuestion:
                            _currentQuestionIndex >= widget.quizCount,
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
                ),
        ),
      ),
    );
  }

  /// 헤더 섹션
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
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

              // 제목 및 진행 상황
              Column(
                children: [
                  Text(
                    '단어 퀴즈',
                    style: GoogleFonts.quicksand(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                  Text(
                    '${_currentQuestionIndex + 1}/${widget.quizCount}',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // 난이도 표시
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getDifficultyColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.difficulty,
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getDifficultyColor(),
                  ),
                ),
              ),
            ],
          ),

          // 카테고리 표시
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '카테고리: ${_currentWord.category}',
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 난이도에 따른 색상 반환
  Color _getDifficultyColor() {
    switch (widget.difficulty) {
      case '쉬움':
        return Colors.green;
      case '보통':
        return Colors.orange;
      case '어려움':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  /// 단어 표시 화면
  Widget _buildWordDisplay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 단어 카드
          WordCard(
            word: _currentWord,
            animation: _wordAnimation,
            onHintToggled: _toggleHint,
            showHint: _showHint,
          ),

          const SizedBox(height: 20),

          // 카드 뒤집기 안내
          AnimatedOpacity(
            opacity: _showHint ? 0.0 : 1.0, // 힌트가 보일 때는 숨김
            duration: Duration(milliseconds: 200),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, color: AppColors.accent, size: 18),
                  SizedBox(width: 8),
                  Text(
                    '카드를 탭하여 뒤집기',
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),

          // 그림 그리기 버튼
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showDrawingCanvas = true;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 8,
              shadowColor: AppColors.accent.withOpacity(0.4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.brush),
                const SizedBox(width: 8),
                Text(
                  '그림 그리기',
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 그림판 화면
  Widget _buildDrawingCanvas() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              // 그림판
              DrawingCanvas(
                drawingPoints: _drawingPoints,
                selectedColor: _selectedColor,
                strokeWidth: _strokeWidth,
                onPathStart: _handlePathStart,
                onPathUpdate: _handlePathUpdate,
                onPathEnd: _handlePathEnd,
              ),

              // 단어 안내 (반투명 오버레이)
              if (_drawingPoints.isEmpty)
                Positioned.fill(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '"${_currentWord.word}"',
                          style: GoogleFonts.quicksand(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '그림을 그려보세요!',
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Icon(
                          Icons.gesture,
                          size: 60,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 그림 그리기 도구 모음
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 색상 팔레트
              ColorPalette(
                selectedColor: _selectedColor,
                onColorSelected: (color) {
                  setState(() {
                    _selectedColor = color;
                  });
                },
              ),

              const SizedBox(height: 16),

              // 하단 컨트롤 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 선 굵기 조절
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.line_weight,
                          size: 24,
                          color: Colors.grey,
                        ),
                        Expanded(
                          child: Slider(
                            value: _strokeWidth,
                            min: 1.0,
                            max: 20.0,
                            activeColor: _selectedColor,
                            onChanged: (value) {
                              setState(() {
                                _strokeWidth = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 지우기 버튼
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: '모두 지우기',
                    color: Colors.red,
                    onPressed: () {
                      setState(() {
                        _drawingPoints = [];
                      });
                    },
                  ),

                  // 완료 버튼
                  ElevatedButton.icon(
                    onPressed: _drawingPoints.isEmpty
                        ? null // 그림이 없으면 비활성화
                        : _evaluateDrawing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(Icons.check),
                    label: const Text('제출하기'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
