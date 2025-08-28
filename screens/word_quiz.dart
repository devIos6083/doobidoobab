// screens/word_quiz_screen.dart
import 'dart:math';
import 'dart:typed_data';
import 'package:confetti/confetti.dart';
import 'package:dio/dio.dart';
import 'package:doobi/models/words.dart';
import 'package:doobi/services/drawing_service.dart';
import 'package:doobi/utils/constants.dart';
import 'package:doobi/utils/logger.dart';
import 'package:doobi/widgets/color_palette.dart';
import 'package:doobi/widgets/complete_screen.dart';
import 'package:doobi/widgets/drawing_canvas.dart';
import 'package:doobi/widgets/quiz_result.dart';
import 'package:doobi/widgets/word_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http_parser/http_parser.dart';

class WordQuizScreen extends StatefulWidget {
  final String difficulty;
  final int quizCount;
  final Function(String)? onWordLearned;

  const WordQuizScreen({
    super.key,
    required this.difficulty,
    required this.quizCount,
    this.onWordLearned,
  });

  @override
  _WordQuizScreenState createState() => _WordQuizScreenState();
}

class _WordQuizScreenState extends State<WordQuizScreen>
    with TickerProviderStateMixin {
  // 선택된 난이도에 따른 단어 목록
  late List<Word> _words;
  Size? _canvasSize; // 캔버스 크기 변수 추가
  final DrawingService _drawingService = DrawingService(); // 서비스 인스턴스 추가

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
  bool _isDrawing = false;

  // 그림 그리기 관련 변수
  Color _selectedColor = Colors.black;
  final double _strokeWidth = 34.0;
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
      '단어 퀴즈 시작: 난이도=${widget.difficulty}, 문제수=${widget.quizCount}',
    );
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
      '새 단어 선택됨: ${_currentWord.word} (${_currentQuestionIndex + 1}/${widget.quizCount})',
    );
  }

  /// 그림 평가 및 결과 표시
  Future<void> _evaluateDrawing() async {
    print('=== 그림 평가 시작 ===');

    bool result = false;

    try {
      // 캔버스 크기가 없으면 화면 크기 사용
      final canvasSize = _canvasSize ?? MediaQuery.of(context).size;
      print('캔버스 크기: ${canvasSize.width}x${canvasSize.height}');
      print('그림 포인트 수: ${_drawingPoints.length}');

      // 서버용 최적화된 이미지 데이터 생성
      final Uint8List? serverImageData = await _drawingService
          .getDrawingImageDataForServer(_drawingPoints, canvasSize);

      // UI 표시용 일반 이미지 데이터 생성
      final Uint8List? uiImageData = await _drawingService.getDrawingImageData(
        _drawingPoints,
        canvasSize,
      );

      if (serverImageData != null && uiImageData != null) {
        print('서버용 이미지 생성 성공: ${serverImageData.length} 바이트');
        print('UI용 이미지 생성 성공: ${uiImageData.length} 바이트');

        // 1. 이미지를 파일로 저장해서 확인
        final String? serverFilePath = await _drawingService.saveDrawingToFile(
          '${_currentWord.word}_server',
          serverImageData,
        );

        final String? uiFilePath = await _drawingService.saveDrawingToFile(
          '${_currentWord.word}_ui',
          uiImageData,
        );

        if (serverFilePath != null) {
          print('서버용 이미지 파일: $serverFilePath');
        }
        if (uiFilePath != null) {
          print('UI용 이미지 파일: $uiFilePath');
        }

        // 2. Flask 서버에 서버용 이미지 보내고 결과 받기
        print('\n=== Flask 서버로 전송 시작 ===');
        result = await _sendImageForPrediction(
          serverImageData,
          _currentWord.word,
        );
        print('Flask 서버 예측 결과: $result');

        // 3. UI용 이미지로 그림 저장 (메모리에)
        await _drawingService.saveDrawing(
          _currentWord.word,
          _drawingPoints,
          canvasSize,
        );
      } else {
        print('이미지 데이터 생성 실패');
        // 개발 중에는 50% 확률로 성공
        result = Random().nextBool();
      }
    } catch (e) {
      print('그림 평가 중 오류 발생: $e');
      // 개발 중에는 오류시 성공으로 처리
      result = true;
    }

    // UI 업데이트
    setState(() {
      _isCorrect = result;
      _showResult = true;
      _currentQuestionIndex++;
    });

    if (_isCorrect) {
      _correctCount++;
      _confettiController.play();
    }

    _resultAnimationController.reset();
    _resultAnimationController.forward();

    // 3초 후 다음 단어로
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _selectCurrentWord();
      }
    });

    AppLogger.info('그림 평가 결과: ${_isCorrect ? "정답" : "오답"}');
  }

  /// Flask 서버에 이미지를 보내고 예측 결과를 받는 함수 (분석 추가)
  Future<bool> _sendImageForPrediction(Uint8List imageData, String word) async {
    try {
      const String apiUrl =
          'Your API Key Here';

      print('\n==== API 요청 시작 ====');
      print('URL: $apiUrl');
      print('전송할 단어: $word');
      print('이미지 크기: ${imageData.length} 바이트');
      print('이미지 첫 20바이트: ${imageData.take(20).toList()}');

      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 15);
      dio.options.receiveTimeout = const Duration(seconds: 15);

      // 디버깅용 인터셉터
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: false,
          responseHeader: true,
          responseBody: true,
          error: true,
          logPrint: (obj) => print(obj.toString()),
        ),
      );

      // FormData 생성
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          imageData,
          filename: '${word}_drawing.png',
          contentType: MediaType('image', 'png'),
        ),
        'word': word,
      });

      print('\nFormData 생성 완료');
      print('파일명: ${word}_drawing.png');
      print('Content-Type: image/png');

      // 요청 보내기
      print('\n요청 전송 중...');
      final stopwatch = Stopwatch()..start();

      final response = await dio.post(
        apiUrl,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {
            'Accept': 'application/json',
            'ngrok-skip-browser-warning': 'true',
          },
          validateStatus: (status) => status! < 500,
        ),
      );

      stopwatch.stop();
      print('\n응답 수신 완료 (${stopwatch.elapsedMilliseconds}ms)');
      print('상태 코드: ${response.statusCode}');
      print('응답 타입: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is Map) {
          final bool match = data['match'] ?? false;
          final String inputWord = data['input_word'] ?? '';

          print('\n╔════════════════════════════════════════════╗');
          print('║           예측 결과 분석                   ║');
          print('╠════════════════════════════════════════════╣');
          print('║ 제출한 단어: $word');
          print('║ 서버가 받은 단어: $inputWord');
          print('║ 매칭 결과: ${match ? "✅ 정답" : "❌ 오답"}');
          print('╠════════════════════════════════════════════╣');
          print('║           예측 상위 5개                    ║');
          print('╠════════════════════════════════════════════╣');

          if (data['top5'] != null) {
            for (int i = 0; i < data['top5'].length; i++) {
              var prediction = data['top5'][i];
              String className = prediction['class_name'] ?? 'unknown';
              double probability = prediction['probability'] ?? 0.0;
              int classIndex = prediction['class_index'] ?? -1;

              // 정답 단어와 일치하는지 표시
              String matchIndicator =
                  className.toLowerCase() == word.toLowerCase() ? ' 🎯' : '';

              print('║ ${i + 1}. $className (#$classIndex)$matchIndicator');
              print('║    확률: ${(probability * 100).toStringAsFixed(2)}%');
              print(
                '║    신뢰도: ${'█' * ((probability * 20).toInt())}${'░' * (20 - (probability * 20).toInt())}',
              );
              if (i < data['top5'].length - 1) {
                print('╟────────────────────────────────────────────╢');
              }
            }
          }

          print('╚════════════════════════════════════════════╝');

          // 추가 분석
          if (data['top5'] != null && data['top5'].isNotEmpty) {
            // 가장 높은 확률
            double highestProb = data['top5'][0]['probability'] ?? 0.0;
            String highestClass = data['top5'][0]['class_name'] ?? 'unknown';

            print('\n📊 분석 요약:');
            print(
              '   • 최고 예측: $highestClass (${(highestProb * 100).toStringAsFixed(1)}%)',
            );
            print('   • 정답 여부: ${match ? "맞음" : "틀림"}');

            // 정답이 아닌 경우 추가 정보
            if (!match) {
              // top5에 정답이 있는지 확인
              int correctIndex = -1;
              for (int i = 0; i < data['top5'].length; i++) {
                if (data['top5'][i]['class_name'].toLowerCase() ==
                    word.toLowerCase()) {
                  correctIndex = i;
                  break;
                }
              }

              if (correctIndex != -1) {
                print('   • 정답 "$word"는 ${correctIndex + 1}위에 있음');
                print(
                  '   • 정답 확률: ${(data['top5'][correctIndex]['probability'] * 100).toStringAsFixed(1)}%',
                );
              } else {
                print('   • 정답 "$word"는 상위 5개에 없음');
              }
            }

            // 확신도 분석
            if (highestProb > 0.8) {
              print('   • 매우 높은 확신도로 예측');
            } else if (highestProb > 0.5) {
              print('   • 중간 정도의 확신도로 예측');
            } else {
              print('   • 낮은 확신도로 예측 (불확실)');
            }
          }

          print('\n${'═' * 45}\n');

          return match;
        } else {
          print('응답 데이터가 Map이 아님: $data');
          return false;
        }
      } else {
        print('API 오류: ${response.statusCode}');
        print('응답 내용: ${response.data}');
        return false;
      }
    } catch (e) {
      print('\nAPI 요청 중 오류: $e');

      if (e is DioException) {
        print('Dio 오류 타입: ${e.type}');
        print('Dio 오류 메시지: ${e.message}');

        if (e.response != null) {
          print('응답 상태 코드: ${e.response?.statusCode}');
          print('응답 데이터: ${e.response?.data}');
        }

        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError) {
          print('네트워크 연결 문제입니다. ngrok URL이 유효한지 확인하세요.');
        }
      }

      // 개발 중에는 오류 시 true 반환
      return true;
    }
  }

  /// 새 경로 시작 - 펜이 화면에 닿았을 때
  void _handlePathStart(Offset position) {
    setState(() {
      _isDrawing = true;

      // 새 경로 시작 표시와 함께 점 추가
      _drawingPoints.add(
        DrawingPoint(
          offset: position,
          paint:
              Paint()
                ..color = _selectedColor
                ..isAntiAlias = true
                ..strokeWidth = _strokeWidth
                ..strokeCap = StrokeCap.round
                ..style = PaintingStyle.stroke, // 선 스타일로 명시적 설정
          isNewPath: true, // 새로운 경로 시작
        ),
      );
    });
  }

  /// 경로 업데이트 - 펜을 드래그할 때
  void _handlePathUpdate(Offset position) {
    if (!_isDrawing) return;

    setState(() {
      // 같은 경로 내 점 추가 (새 경로 표시 없음)
      _drawingPoints.add(
        DrawingPoint(
          offset: position,
          paint:
              Paint()
                ..color = _selectedColor
                ..isAntiAlias = true
                ..strokeWidth = _strokeWidth
                ..strokeCap = StrokeCap.round
                ..style = PaintingStyle.stroke,
          isNewPath: false, // 기존 경로 연장
        ),
      );
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
            colors: [AppColors.primaryLight, AppColors.secondaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child:
              _quizCompleted
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
                            child:
                                _showDrawingCanvas
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

  // 나머지 메서드들은 동일...
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            opacity: _showHint ? 0.0 : 1.0,
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
              // 그림판 - LayoutBuilder로 감싸서 크기 정보 저장
              LayoutBuilder(
                builder: (context, constraints) {
                  // 캔버스 크기 저장
                  _canvasSize = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );

                  return DrawingCanvas(
                    drawingPoints: _drawingPoints,
                    selectedColor: _selectedColor,
                    strokeWidth: _strokeWidth,
                    onPathStart: _handlePathStart,
                    onPathUpdate: _handlePathUpdate,
                    onPathEnd: _handlePathEnd,
                  );
                },
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
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.brush,
                            size: 24,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '최적화된 굵기로 그려보세요!',
                            style: GoogleFonts.quicksand(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
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
                    onPressed: _drawingPoints.isEmpty ? null : _evaluateDrawing,
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
