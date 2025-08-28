// screens/word_learning_screen.dart
import 'package:doobi/screens/learning_completed_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:confetti/confetti.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'dart:typed_data';
import 'dart:math';
import 'dart:ui' show ImageByteFormat, PictureRecorder;

// 프로젝트 imports
import 'package:doobi/models/words.dart'; // Word 클래스와 filterWordsByDifficulty 함수
import 'package:doobi/services/drawing_service.dart';
import 'package:doobi/utils/constants.dart';
import 'package:doobi/utils/logger.dart';
import 'package:doobi/widgets/color_palette.dart';
import 'package:doobi/widgets/drawing_canvas.dart';
import 'package:doobi/widgets/word_connecting.dart';

/// 단어 학습 게임 화면
///
/// 하나의 단어당 여러 게임을 연속으로 진행하는 화면입니다.
/// 각 단어마다 이미지 선택, 의미 매칭, 연결하기 게임 중 2개와
/// 마지막 그림 그리기 게임을 순차적으로 진행합니다.
// ignore_for_file: deprecated_member_use

/// 단어 학습 게임 화면
///
/// 하나의 단어당 여러 게임을 연속으로 진행하는 화면입니다.
/// 각 단어마다 이미지 선택, 의미 매칭, 연결하기 게임 중 2개와
/// 마지막 그림 그리기 게임을 순차적으로 진행합니다.

// 게임 타입 정의
enum GameType {
  imageMatching, // 이미지-단어 매칭
  definitionMatching, // 뜻 매칭
  wordConnecting, // 단어 연결
  drawing, // 그림 그리기
}

class WordLearningScreen extends StatefulWidget {
  // 선택된 난이도와 문제 수를 받는 생성자
  final String difficulty;
  final int quizCount;
  final Function(String)? onWordLearned; // 단어 학습 완료 시 콜백 추가

  const WordLearningScreen({
    super.key,
    this.difficulty = '보통',
    this.quizCount = 1,
    this.onWordLearned, // 콜백 파라미터 추가
  });

  @override
  _WordLearningScreenState createState() => _WordLearningScreenState();
}

class _WordLearningScreenState extends State<WordLearningScreen>
    with TickerProviderStateMixin {
  // 상수 정의
  static const int TOTAL_GAMES = 3; // 한 단어당 게임 수

  // 선택된 난이도에 따른 단어 목록
  late List<Word> _words; // 전체 단어 목록
  late List<Word> _selectedWords; // 퀴즈에 사용될 단어 목록
  late List<List<GameType>> _gameSequence; // 각 단어별 게임 순서

  // 그림 서비스 추가
  final DrawingService _drawingService = DrawingService();
  Size? _canvasSize;

  // 현재 상태 변수 - final 제거
  int _currentWordIndex = 0; // 현재 단어 인덱스
  int _currentGameIndex = 0; // 현재 게임 인덱스 (한 단어 내에서)
  int _correctCount = 0; // 정답 개수
  int _totalAnswered = 0; // 총 답변 개수

  // 현재 게임 관련 변수
  late Word _currentWord;
  late GameType _currentGameType;
  List<Word> _optionWords = []; // 선택지로 사용될 단어들
  int? _selectedOptionIndex; // 사용자가 선택한 옵션 인덱스
  List<int?> _connectionPairs = [null, null, null, null]; // 연결 게임 페어
  List<int?> _rightIndices = [null, null, null, null]; // 오른쪽 단어 인덱스 매핑
  bool _showResult = false;
  bool _isCorrect = false;
  bool _quizCompleted = false;

  // 그림 그리기 관련 변수
  Color _selectedColor = Colors.black;
  final double _strokeWidth = 34.0;
  List<DrawingPoint> _drawingPoints = [];
  bool _isDrawing = false;

  // 애니메이션 컨트롤러
  late AnimationController _cardAnimationController;
  late AnimationController _resultAnimationController;
  late Animation<double> _cardAnimation;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    print('WordLearningScreen 초기화 시작');

    // 단어 필터링 및 섞기
    _words = filterWordsByDifficulty(widget.difficulty);
    _words.shuffle();

    // 퀴즈에 사용될 단어 선택
    _selectedWords =
        _words.length > widget.quizCount
            ? _words.sublist(0, widget.quizCount)
            : List.from(_words);
    // 수정된 코드:
    // _selectedWords = _words.isNotEmpty ? [_words.first] : [];

    // 각 단어별 게임 순서 결정 (마지막은 항상 그림 그리기)
    _gameSequence = _generateGameSequences();

    // 애니메이션 컨트롤러 초기화
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardAnimation = CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOutBack,
    );

    _resultAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // 첫 번째 게임 설정
    _setupCurrentGame();

    // 로그 기록
    AppLogger.event(
      '단어 학습 시작: 난이도=${widget.difficulty}, 단어수=${widget.quizCount}',
    );
    print('WordLearningScreen 초기화 완료: 단어수=${_selectedWords.length}');
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    _resultAnimationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  /// 각 단어별 게임 시퀀스 생성
  ///
  /// 각 단어마다 진행할 게임 타입의 순서를 생성합니다.
  /// 처음 두 게임은 이미지 매칭, 뜻 매칭, 단어 연결 중 2개를 랜덤으로 선택하고,
  /// 마지막 게임은 항상 그림 그리기로 설정합니다.
  List<List<GameType>> _generateGameSequences() {
    final List<List<GameType>> sequences = [];
    final Random random = Random();

    // 가능한 게임 타입 (그림 그리기 제외)
    final List<GameType> gameTypes = [
      GameType.imageMatching,
      GameType.definitionMatching,
      GameType.wordConnecting,
    ];

    // 각 단어마다 게임 시퀀스 생성
    for (int i = 0; i < _selectedWords.length; i++) {
      // 게임 타입 섞기
      gameTypes.shuffle();

      // 처음 두 게임은 랜덤 선택, 마지막은 그림 그리기
      final List<GameType> sequence = [
        gameTypes[0],
        gameTypes[1],
        GameType.drawing,
      ];

      sequences.add(sequence);
    }

    print('게임 시퀀스 생성 완료: ${sequences.length}개 단어');
    return sequences;
  }

  /// 현재 게임 설정
  ///
  /// 현재 단어와 게임 타입에 맞게 게임 환경을 설정합니다.
  void _setupCurrentGame() {
    // 디버깅 로그 추가
    print(
      '_setupCurrentGame 호출됨: 단어 인덱스=$_currentWordIndex, 게임 인덱스=$_currentGameIndex',
    );

    // 모든 게임 완료 확인
    if (_currentWordIndex >= _selectedWords.length) {
      print('모든 단어 게임 완료됨: $_currentWordIndex >= ${_selectedWords.length}');
      setState(() {
        _quizCompleted = true;
      });
      AppLogger.info('모든 게임 완료됨');
      return;
    }

    try {
      // 현재 단어와 게임 타입 설정
      _currentWord = _selectedWords[_currentWordIndex];
      _currentGameType = _gameSequence[_currentWordIndex][_currentGameIndex];

      print(
        '새 게임 설정: 단어=${_currentWord.word}, 게임=${_currentGameType.toString()}',
      );

      // 게임 타입에 따른 초기화
      switch (_currentGameType) {
        case GameType.imageMatching:
        case GameType.definitionMatching:
          print('선택형 게임 초기화');
          _setupMultipleChoiceGame();
          break;

        case GameType.wordConnecting:
          print('연결 게임 초기화');
          _setupConnectingGame();
          break;

        case GameType.drawing:
          print('그림 그리기 게임 초기화');
          _drawingPoints = [];
          _isDrawing = false;
          break;
      }

      // 상태 초기화
      setState(() {
        _selectedOptionIndex = null;
        _showResult = false;
      });

      // 카드 애니메이션 재생
      _cardAnimationController.reset();
      _cardAnimationController.forward();

      AppLogger.info(
        '새 게임 설정: 단어=${_currentWord.word}, 게임=${_currentGameType.toString()}, (${_currentWordIndex + 1}/${_selectedWords.length})',
      );
    } catch (e) {
      print('게임 설정 중 오류 발생: $e');
      // 오류 복구 시도
      if (mounted) {
        setState(() {
          // 오류 발생 시 다음 단어로 건너뛰기
          _currentWordIndex++;
          _currentGameIndex = 0;
          _showResult = false;
        });

        // 재귀적으로 다시 시도 (단, 무한 루프 방지)
        if (_currentWordIndex < _selectedWords.length) {
          print('오류 복구: 다음 단어로 이동하여 다시 시도');
          Future.microtask(() => _setupCurrentGame());
        } else {
          print('오류 복구: 더 이상 단어가 없어 완료 화면으로 전환');
          setState(() {
            _quizCompleted = true;
          });
        }
      }
    }
  }

  /// 선택형 게임(이미지 매칭, 뜻 매칭) 설정
  void _setupMultipleChoiceGame() {
    // 선택지 생성 (현재 단어 + 랜덤 단어 3개)
    _optionWords = [_currentWord];

    // 현재 단어 외의 다른 단어들로 리스트 생성
    final List<Word> otherWords =
        _words.where((word) => word.word != _currentWord.word).toList();
    otherWords.shuffle();

    // 3개의 다른 단어 추가 (최대 가능한만큼)
    final int addCount = min(3, otherWords.length);
    _optionWords.addAll(otherWords.sublist(0, addCount));

    // 선택지 섞기
    _optionWords.shuffle();

    print('선택형 게임 설정 완료: ${_optionWords.length}개 선택지');
  }

  /// 연결 게임 설정
  void _setupConnectingGame() {
    // 연결 게임용 단어 선택 (현재 단어 + 랜덤 단어 3개)
    _optionWords = [_currentWord];

    // 현재 단어 외의 다른 단어들로 리스트 생성
    final List<Word> otherWords =
        _words.where((word) => word.word != _currentWord.word).toList();
    otherWords.shuffle();

    // 3개의 다른 단어 추가
    _optionWords.addAll(otherWords.sublist(0, 3));

    // 선택지 섞기
    _optionWords.shuffle();

    // 연결 상태 초기화
    _connectionPairs = [null, null, null, null];

    // 오른쪽 단어 순서 셔플
    List<int> indices = [0, 1, 2, 3];
    indices.shuffle();
    _rightIndices = indices;

    print('연결 게임 설정 완료');
  }

  /// 선택형 게임 답변 처리
  void _handleMultipleChoiceAnswer(int selectedIndex) {
    print('_handleMultipleChoiceAnswer 호출됨: 선택된 인덱스=$selectedIndex');

    final bool isCorrect =
        _optionWords[selectedIndex].word == _currentWord.word;

    setState(() {
      _selectedOptionIndex = selectedIndex;
      _isCorrect = isCorrect;
      _showResult = true;
    });

    // 정답이면 정답 개수 증가
    if (isCorrect) {
      _correctCount++;
      _confettiController.play();
    }

    _totalAnswered++;

    // 결과 애니메이션 재생
    _resultAnimationController.reset();
    _resultAnimationController.forward();

    print('2초 후 다음 게임으로 이동 예약');

    // 2초 후 다음 게임 진행
    _scheduleNextGame(2);

    AppLogger.info('선택형 게임 답변: ${isCorrect ? "정답" : "오답"}');
  }

  /// 연결 게임 답변 처리
  void _checkConnectionGame() {
    // 디버깅용 로그
    print("_checkConnectionGame 호출됨");

    // 모든 단어가 연결되었는지 확인
    if (_connectionPairs.contains(null)) {
      print("아직 모든 단어가 연결되지 않음");
      return; // 아직 모든 단어가 연결되지 않음
    }

    // 디버깅용 로그
    print("모든 단어 연결 완료: $_connectionPairs, rightIndices: $_rightIndices");

    // 정답 확인 로직 수정
    bool isCorrect = true;

    // 각 연결에 대해 왼쪽과 오른쪽 단어가 일치하는지 확인
    for (int i = 0; i < _optionWords.length; i++) {
      if (_connectionPairs[i] == null) {
        print("연결 없음: $i");
        isCorrect = false;
        break;
      }

      int rightIndex = _rightIndices[_connectionPairs[i]!]!;
      String leftWord = _optionWords[i].word; // 왼쪽에 있는 단어
      String rightWord = _optionWords[rightIndex].word; // 오른쪽에 있는 단어

      print("비교: 왼쪽($i)=$leftWord, 오른쪽(${_connectionPairs[i]})=$rightWord");

      // 현재 단어와 맞는 연결인지 확인 (왼쪽 단어와 오른쪽 단어가 같아야 함)
      if (leftWord != rightWord) {
        isCorrect = false;
        print("불일치: $leftWord != $rightWord");
        break;
      }
    }

    print("정답 여부: $isCorrect");

    // 상태 업데이트
    setState(() {
      _isCorrect = isCorrect;
      _showResult = true; // 결과 표시 활성화
    });

    // 정답이면 정답 개수 증가 및 축하 효과 표시
    if (isCorrect) {
      _correctCount++;
      _confettiController.play();
    }

    _totalAnswered++;

    // 결과 애니메이션 재생
    _resultAnimationController.reset();
    _resultAnimationController.forward();

    // *** 중요: 반드시 2초 후 다음 게임으로 이동하도록 보장 ***
    print("다음 게임 이동 예약");
    _scheduleNextGame(2);

    AppLogger.info('연결 게임 답변: ${isCorrect ? "정답" : "오답"}');
  }

  // word_learning_screen.dart의 _evaluateDrawing 메서드도 동일하게 수정

  /// 그림 평가 및 결과 표시
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
          print('=== 중요: 이 파일을 열어서 그림이 제대로 저장됐는지 확인하세요! ===');
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
      print('스택 트레이스: ${StackTrace.current}');
      // 개발 중에는 오류시 성공으로 처리
      result = true;
    }

    // UI 업데이트
    setState(() {
      _isCorrect = result;
      _showResult = true;
    });

    if (result) {
      _correctCount++;
      _confettiController.play();

      // 콜백 호출
      if (widget.onWordLearned != null) {
        widget.onWordLearned!(_currentWord.word);
        print('단어 학습 콜백 호출: ${_currentWord.word}');
      }
    }

    _totalAnswered++;

    _resultAnimationController.reset();
    _resultAnimationController.forward();

    print('3초 후 다음 게임으로 이동 예약');
    _scheduleNextGame(3);

    AppLogger.info('그림 평가 결과: ${_isCorrect ? "정답" : "오답"}');
  }

  /// Flask 서버에 이미지를 보내고 예측 결과를 받는 함수
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

      print('FormData 생성 완료');
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

        // response.data가 이미 파싱된 Map인지 확인
        if (data is Map) {
          final bool match = data['match'] ?? false;
          final String inputWord = data['input_word'] ?? '';

          print('\n=== 예측 결과 ===');
          print('서버가 받은 단어: $inputWord');
          print('매칭 결과: $match');
          print('예측 상위 5개:');

          if (data['top5'] != null) {
            for (var prediction in data['top5']) {
              print(
                '  - ${prediction['class_name']}: ${(prediction['probability'] * 100).toStringAsFixed(2)}%',
              );
            }
          }

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

        // 네트워크 오류인 경우
        if (e.type == DioErrorType.connectionTimeout ||
            e.type == DioErrorType.receiveTimeout ||
            e.type == DioErrorType.connectionError) {
          print('네트워크 연결 문제입니다. ngrok URL이 유효한지 확인하세요.');
        }
      }

      // 개발 중에는 오류 시 true 반환
      return true;
    }
  }

  /// 다음 게임으로 이동 스케줄링 (새로 추가)
  void _scheduleNextGame(int delaySeconds) {
    print('다음 게임 스케줄링: $delaySeconds초 후 실행');
    Future.delayed(Duration(seconds: delaySeconds), () {
      print('지연 시간 후 다음 게임 이동 시도');
      // mounted 체크 전에 로그
      print('mounted 상태: $mounted');

      if (mounted) {
        print('_moveToNextGame 호출 직전');
        _moveToNextGame();
      } else {
        print('경고: 위젯이 이미 해제됨');
      }
    });
  }

  /// 다음 게임으로 이동
  void _moveToNextGame() {
    print(
      '_moveToNextGame 호출됨: 현재 단어=$_currentWordIndex, 현재 게임=$_currentGameIndex',
    );

    // 현재 단어의 모든 게임을 완료했는지 확인
    if (_currentGameIndex >= TOTAL_GAMES - 1) {
      print('현재 단어의 모든 게임 완료, 다음 단어로 이동');
      setState(() {
        // 다음 단어로 이동, 게임 인덱스 초기화
        _currentWordIndex++;
        _currentGameIndex = 0;

        // 결과 화면 숨기기
        _showResult = false;
      });
    } else {
      print('같은 단어의 다음 게임으로 이동');
      setState(() {
        // 같은 단어의 다음 게임으로 이동
        _currentGameIndex++;

        // 결과 화면 숨기기
        _showResult = false;
      });
    }

    print('상태 업데이트 후: 단어=$_currentWordIndex, 게임=$_currentGameIndex');

    // 강제로 UI 갱신을 위해 Future 마이크로태스크 큐에 넣기
    Future.microtask(() {
      print('마이크로태스크에서 _setupCurrentGame 호출');
      _setupCurrentGame();
    });
  }

  /// 뜻 매칭 게임 답변 처리
  void _handleDefinitionMatchingAnswer(int selectedIndex) {
    print('_handleDefinitionMatchingAnswer 호출됨: 선택된 인덱스=$selectedIndex');

    final bool isCorrect =
        _optionWords[selectedIndex].meaning == _currentWord.meaning;

    setState(() {
      _selectedOptionIndex = selectedIndex;
      _isCorrect = isCorrect;
      _showResult = true;
    });

    if (isCorrect) {
      _correctCount++;
      _confettiController.play();
    }
    _totalAnswered++;

    _resultAnimationController.reset();
    _resultAnimationController.forward();

    // 2초 후 자동으로 다음 게임 진행
    print('2초 후 다음 게임으로 이동 예약');
    _scheduleNextGame(2);

    AppLogger.info('정의 매칭 게임 답변: ${isCorrect ? "정답" : "오답"}');
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
                ..style = PaintingStyle.stroke, // 선 스타일로 명시적 설정
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
                  ? _buildCompletionScreen()
                  : Stack(
                    children: [
                      // 메인 콘텐츠
                      Column(
                        children: [
                          _buildHeader(),
                          Expanded(child: _buildGameContent()),
                        ],
                      ),

                      // 결과 오버레이 (정답/오답 표시)
                      if (_showResult) _buildResultOverlay(),

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
                    '단어 학습',
                    style: GoogleFonts.quicksand(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                  Text(
                    '${_currentWordIndex + 1}/${_selectedWords.length} · '
                    '게임 ${_currentGameIndex + 1}/$TOTAL_GAMES',
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

  Widget _buildGameContent() {
    // 게임 타입에 따라 다른 UI 표시
    switch (_currentGameType) {
      case GameType.imageMatching:
        return _buildImageMatchingGame();
      case GameType.definitionMatching:
        return _buildDefinitionMatchingGame();
      case GameType.wordConnecting:
        return WordConnectingGameWidget(
          optionWords: _optionWords,
          currentWord: _currentWord,
          cardAnimation: _cardAnimation,
          rightIndices: _rightIndices,
          onConnectionComplete: () {
            // 여기서 반드시 _checkConnectionGame 함수를 직접 호출해야 함
            _checkConnectionGame();
          },
          initialConnectionPairs: _connectionPairs,
          onConnectionUpdate: (pairs) {
            setState(() {
              _connectionPairs = List.from(pairs);
            });
          },
        );
      case GameType.drawing:
        return _buildDrawingGame();
    }
  }

  /// 이미지 매칭 게임 UI
  Widget _buildImageMatchingGame() {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // AI 문제 출제 애니메이션
            SizedBox(
              height: 100, // 높이 조정
              child: Lottie.asset('lottie/ai.json', fit: BoxFit.contain),
            ),

            const SizedBox(height: 16), // 간격 조정
            // 문제 텍스트
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '"${_currentWord.word}"의 이미지를 고르세요',
                style: GoogleFonts.quicksand(
                  fontSize: 20, // 폰트 크기 조정
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24), // 간격 조정
            // 이미지 선택지
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9, // 카드 비율 조정
                ),
                itemCount: _optionWords.length,
                itemBuilder: (context, index) {
                  return ScaleTransition(
                    scale: _cardAnimation,
                    child: _buildImageCard(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 이미지 카드 위젯
  Widget _buildImageCard(int index) {
    final bool isSelected = _selectedOptionIndex == index;
    final bool showResult = _showResult;
    final bool isCorrect = _optionWords[index].word == _currentWord.word;

    // 결과에 따른 카드 색상
    Color cardColor = Colors.white;
    if (showResult) {
      if (isSelected && isCorrect) {
        cardColor = Colors.green.shade100;
      } else if (isSelected && !isCorrect) {
        cardColor = Colors.red.shade100;
      } else if (isCorrect) {
        cardColor = Colors.green.shade50;
      }
    } else if (isSelected) {
      cardColor = AppColors.accent.withOpacity(0.1);
    }

    return GestureDetector(
      onTap: _showResult ? null : () => _handleMultipleChoiceAnswer(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              // 이미지
              Positioned.fill(
                child: Image.asset(
                  'img/${_optionWords[index].word}.png',
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 32,
                          color: Colors.grey,
                        ),
                      ),
                ),
              ),

              // 단어 표시 (하단에 표시)

              // 선택 표시
              if (isSelected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color:
                          showResult
                              ? (isCorrect ? Colors.green : Colors.red)
                              : AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      showResult
                          ? (isCorrect ? Icons.check : Icons.close)
                          : Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),

              // 정답 표시 (오답 선택 시)
              if (showResult && !isSelected && isCorrect)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 뜻 매칭 게임 UI
  Widget _buildDefinitionMatchingGame() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // AI 문제 출제 애니메이션
          SizedBox(
            height: 120,
            child: Lottie.asset('lottie/ai.json', fit: BoxFit.contain),
          ),
          const SizedBox(height: 20),
          // 문제 텍스트
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '"${_currentWord.word}"의 뜻을 고르세요',
              style: GoogleFonts.quicksand(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 30),
          // 선택지 그리드 (각 카드에 단어의 뜻 표시)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.0,
              ),
              itemCount: _optionWords.length,
              itemBuilder: (context, index) {
                return ScaleTransition(
                  scale: _cardAnimation,
                  child: _buildDefinitionCard(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 정의 매칭 게임 카드 위젯
  Widget _buildDefinitionCard(int index) {
    final bool isSelected = _selectedOptionIndex == index;
    final bool showResult = _showResult;
    final bool isCorrect = _optionWords[index].meaning == _currentWord.meaning;

    // **중요:** 결과에 따른 카드 색상 설정
    Color cardColor = Colors.white;
    if (showResult) {
      if (isSelected && isCorrect) {
        cardColor = Colors.green.shade100;
      } else if (isSelected && !isCorrect) {
        cardColor = Colors.red.shade100;
      } else if (isCorrect) {
        cardColor = Colors.green.shade50;
      }
    } else if (isSelected) {
      cardColor = AppColors.accent.withOpacity(0.1);
    }

    return GestureDetector(
      onTap: _showResult ? null : () => _handleDefinitionMatchingAnswer(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : Colors.grey.withOpacity(0.3),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _optionWords[index].meaning,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color:
                          showResult
                              ? (isCorrect ? Colors.green : Colors.red)
                              : AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      showResult
                          ? (isCorrect ? Icons.check : Icons.close)
                          : Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              if (showResult && !isSelected && isCorrect)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 그림 그리기 게임 UI
  /// 그림 그리기 게임 UI
  Widget _buildDrawingGame() {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              // 그림판 - 크기 정보 저장 기능 추가
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
                        SizedBox(
                          height: 100,
                          child: Lottie.asset(
                            'lottie/ai.json',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 20),
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
                  // 안내 텍스트
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

  /// 결과 오버레이
  Widget _buildResultOverlay() {
    return FadeTransition(
      opacity: _resultAnimationController,
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
                  _isCorrect ? Icons.check_circle : Icons.cancel,
                  color: _isCorrect ? Colors.green : Colors.red,
                  size: 60,
                ),

                const SizedBox(height: 15),

                // 결과 텍스트
                Text(
                  _isCorrect ? '정답입니다!' : '아쉽네요!',
                  style: GoogleFonts.quicksand(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _isCorrect ? Colors.green : Colors.red,
                  ),
                ),

                const SizedBox(height: 20),

                // 단어 정보
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color:
                        _isCorrect
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
                            _currentWord.word,
                            style: GoogleFonts.quicksand(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _currentWord.meaning,
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
                        '카테고리: ${_currentWord.category}',
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
                  _isCorrect
                      ? '잘 하고 있어요! ${_currentWordIndex >= _selectedWords.length - 1 && _currentGameIndex >= TOTAL_GAMES - 1 ? '마지막 문제입니다!' : '계속 진행해보세요!'}'
                      : '힌트: ${_currentWord.hint}',
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

  // _buildCompletionScreen에서 StoryGenerationScreen으로 이동하는 버튼이 필요합니다
  Widget _buildCompletionScreen() {
    // 학습한 단어 목록 추출
    final learnedWords = _selectedWords.sublist(
      0,
      min(_currentWordIndex, _selectedWords.length),
    );

    // 저장된 그림 가져오기
    final Map<String, Uint8List> drawings = _drawingService.getAllDrawings();

    return LearningCompletedScreen(
      correctCount: _correctCount,
      totalAnswered: _totalAnswered,
      learnedWords: learnedWords,
      drawings: drawings,
    );
  }

  /// 그림 타일 위젯
  Widget _buildDrawingTile(String word, Uint8List imageData) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 그림 이미지
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.memory(imageData, fit: BoxFit.contain),
            ),
          ),

          // 단어 텍스트
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Text(
              word,
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
