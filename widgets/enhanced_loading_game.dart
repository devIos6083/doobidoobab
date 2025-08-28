// widgets/enhanced_loading_game.dart
import 'dart:math';
import 'package:doobi/models/words.dart';
import 'package:doobi/utils/constants.dart';
import 'package:doobi/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 향상된 로딩 미니게임 위젯
///
/// 로딩 중에 플레이할 수 있는 더 다양한 형태의 미니게임을 제공합니다.
class EnhancedLoadingGame extends StatefulWidget {
  final List<Word> learnedWords;
  final Function(int)? onGameCompleted;

  const EnhancedLoadingGame({
    super.key,
    required this.learnedWords,
    this.onGameCompleted,
  });

  @override
  _EnhancedLoadingGameState createState() => _EnhancedLoadingGameState();
}

class _EnhancedLoadingGameState extends State<EnhancedLoadingGame> {
  // 게임 상태 변수
  int _currentGameIndex = 0; // 현재 게임 인덱스
  int _score = 0; // 누적 점수
  bool _showNextGameButton = false; // 다음 게임 버튼 표시 여부

  // 게임 종류 정의
  static const List<String> _gameTypes = [
    'wordMatching', // 단어 의미 매칭
    'wordPuzzle', // 단어 퍼즐 (글자 섞기)
    'imageGuessing', // 이미지 퀴즈
  ];

  // 현재 게임 데이터
  late Map<String, dynamic> _currentGameData;

  @override
  void initState() {
    super.initState();
    _prepareNextGame();
  }

  /// 다음 게임 준비
  void _prepareNextGame() {
    // 무작위로 게임 타입 선택
    final random = Random();
    final gameType = _gameTypes[_currentGameIndex % _gameTypes.length];

    // 게임 데이터 초기화
    switch (gameType) {
      case 'wordMatching':
        _currentGameData = _prepareWordMatchingGame();
        break;
      case 'wordPuzzle':
        _currentGameData = _prepareWordPuzzleGame();
        break;
      case 'imageGuessing':
        _currentGameData = _prepareImageGuessingGame();
        break;
      default:
        _currentGameData = _prepareWordMatchingGame();
    }

    setState(() {
      _showNextGameButton = false;
    });

    AppLogger.info('새로운 미니게임 준비: $gameType');
  }

  /// 단어 매칭 게임 준비
  Map<String, dynamic> _prepareWordMatchingGame() {
    if (widget.learnedWords.isEmpty) {
      return {'type': 'wordMatching', 'error': true};
    }

    final random = Random();

    // 문제로 사용할 단어 선택
    final questionWord =
        widget.learnedWords[random.nextInt(widget.learnedWords.length)];

    // 선택지 생성 (정답 + 오답 3개)
    List<Word> options = [questionWord];
    List<Word> otherWords = List.from(widget.learnedWords)
      ..removeWhere((word) => word.word == questionWord.word);

    // 다른 단어가 충분하지 않을 경우 처리
    if (otherWords.length < 3) {
      // 더미 단어 추가
      otherWords.addAll([
        Word(word: '사과', meaning: '빨간색 과일', category: '음식', difficulty: '쉬움'),
        Word(
          word: '자동차',
          meaning: '바퀴가 달린 교통수단',
          category: '교통',
          difficulty: '쉬움',
        ),
        Word(word: '학교', meaning: '공부하는 곳', category: '장소', difficulty: '쉬움'),
      ]);
    }

    otherWords.shuffle();
    options.addAll(otherWords.take(3));
    options.shuffle();

    return {
      'type': 'wordMatching',
      'questionWord': questionWord,
      'options': options,
      'selectedIndex': null,
      'isCorrect': null,
    };
  }

  /// 단어 퍼즐 게임 준비
  Map<String, dynamic> _prepareWordPuzzleGame() {
    if (widget.learnedWords.isEmpty) {
      return {'type': 'wordPuzzle', 'error': true};
    }

    final random = Random();

    // 비교적 짧은 단어 선택
    List<Word> shortWords =
        widget.learnedWords
            .where((word) => word.word.length >= 2 && word.word.length <= 5)
            .toList();

    final Word puzzleWord =
        shortWords.isNotEmpty
            ? shortWords[random.nextInt(shortWords.length)]
            : widget.learnedWords[random.nextInt(widget.learnedWords.length)];

    // 글자 섞기
    final List<String> characters = puzzleWord.word.split('');
    characters.shuffle();

    return {
      'type': 'wordPuzzle',
      'word': puzzleWord,
      'shuffledChars': characters,
      'userAnswer': '',
      'isCorrect': null,
    };
  }

  /// 이미지 퀴즈 게임 준비
  Map<String, dynamic> _prepareImageGuessingGame() {
    if (widget.learnedWords.isEmpty) {
      return {'type': 'imageGuessing', 'error': true};
    }

    final random = Random();

    // 이미지가 있는 단어 선택
    final questionWord =
        widget.learnedWords[random.nextInt(widget.learnedWords.length)];

    // 선택지 생성 (정답 + 오답 3개)
    List<Word> options = [questionWord];
    List<Word> otherWords = List.from(widget.learnedWords)
      ..removeWhere((word) => word.word == questionWord.word);

    if (otherWords.length < 3) {
      otherWords.addAll([
        Word(word: '사과', meaning: '빨간색 과일', category: '음식', difficulty: '쉬움'),
        Word(
          word: '자동차',
          meaning: '바퀴가 달린 교통수단',
          category: '교통',
          difficulty: '쉬움',
        ),
        Word(word: '학교', meaning: '공부하는 곳', category: '장소', difficulty: '쉬움'),
      ]);
    }

    otherWords.shuffle();
    options.addAll(otherWords.take(3));
    options.shuffle();

    return {
      'type': 'imageGuessing',
      'questionWord': questionWord,
      'options': options,
      'selectedIndex': null,
      'isCorrect': null,
    };
  }

  /// 답변 처리 - 단어 매칭 게임
  void _handleWordMatchingAnswer(int selectedIndex) {
    if (_currentGameData['isCorrect'] != null) return; // 이미 답변한 경우

    final Word selectedWord = _currentGameData['options'][selectedIndex];
    final bool isCorrect =
        selectedWord.word == _currentGameData['questionWord'].word;

    setState(() {
      _currentGameData['selectedIndex'] = selectedIndex;
      _currentGameData['isCorrect'] = isCorrect;

      if (isCorrect) {
        _score += 5;
      }

      _showNextGameButton = true;
    });

    AppLogger.info('단어 매칭 답변: ${isCorrect ? "정답" : "오답"}');
  }

  /// 답변 제출 - 단어 퍼즐 게임
  void _submitPuzzleAnswer() {
    if (_currentGameData['isCorrect'] != null) return; // 이미 답변한 경우

    final String correctWord = _currentGameData['word'].word;
    final String userAnswer = _currentGameData['userAnswer'];
    final bool isCorrect =
        userAnswer.toLowerCase() == correctWord.toLowerCase();

    setState(() {
      _currentGameData['isCorrect'] = isCorrect;

      if (isCorrect) {
        _score += 10; // 퍼즐은 좀 더 어렵기 때문에 점수 높게
      }

      _showNextGameButton = true;
    });

    AppLogger.info('단어 퍼즐 답변: ${isCorrect ? "정답" : "오답"}');
  }

  /// 답변 처리 - 이미지 퀴즈 게임
  void _handleImageGuessingAnswer(int selectedIndex) {
    if (_currentGameData['isCorrect'] != null) return; // 이미 답변한 경우

    final Word selectedWord = _currentGameData['options'][selectedIndex];
    final bool isCorrect =
        selectedWord.word == _currentGameData['questionWord'].word;

    setState(() {
      _currentGameData['selectedIndex'] = selectedIndex;
      _currentGameData['isCorrect'] = isCorrect;

      if (isCorrect) {
        _score += 5;
      }

      _showNextGameButton = true;
    });

    AppLogger.info('이미지 퀴즈 답변: ${isCorrect ? "정답" : "오답"}');
  }

  /// 다음 게임으로 이동
  void _moveToNextGame() {
    setState(() {
      _currentGameIndex++;
    });

    _prepareNextGame();

    if (_currentGameIndex >= 3 && widget.onGameCompleted != null) {
      widget.onGameCompleted!(_score);
    }
  }

  // widgets/enhanced_loading_game.dart의 build 메서드 부분 수정
  // widgets/enhanced_loading_game.dart에서 전체적으로 사이즈 축소
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8.0), // 패딩 감소
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상단 게임 정보 표시
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '로딩 미니게임',
                  style: GoogleFonts.quicksand(
                    fontSize: 14, // 크기 축소
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),

                // 점수 표시
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ), // 패딩 축소
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '점수: $_score',
                    style: GoogleFonts.quicksand(
                      fontSize: 12, // 크기 축소
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4), // 여백 축소
            // 게임 진행 단계 표시
            LinearProgressIndicator(
              value:
                  (_currentGameIndex % _gameTypes.length) / _gameTypes.length,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 3, // 높이 제한
            ),

            const SizedBox(height: 6), // 여백 축소
            // 게임 내용 표시
            Expanded(
              child:
                  _currentGameData.containsKey('error')
                      ? _buildErrorWidget()
                      : _buildGameContent(),
            ),

            // 다음 게임 버튼
            if (_showNextGameButton)
              Container(
                height: 32, // 고정 높이
                margin: EdgeInsets.only(top: 4),
                child: ElevatedButton.icon(
                  onPressed: _moveToNextGame,
                  icon: Icon(Icons.arrow_forward, size: 14), // 아이콘 크기 축소
                  label: Text(
                    '다음 게임',
                    style: TextStyle(fontSize: 12), // 텍스트 크기 축소
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    padding: EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 10,
                    ), // 패딩 축소
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 게임 내용 위젯 빌드
  Widget _buildGameContent() {
    switch (_currentGameData['type']) {
      case 'wordMatching':
        return _buildWordMatchingGame();
      case 'wordPuzzle':
        return _buildWordPuzzleGame();
      case 'imageGuessing':
        return _buildImageGuessingGame();
      default:
        return _buildErrorWidget();
    }
  }

  /// 단어 매칭 게임 위젯
  Widget _buildWordMatchingGame() {
    final Word questionWord = _currentGameData['questionWord'];
    final List<Word> options = _currentGameData['options'];
    final int? selectedIndex = _currentGameData['selectedIndex'];
    final bool? isCorrect = _currentGameData['isCorrect'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 게임 제목
        Text(
          '단어 매칭',
          style: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // 문제 단어
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '"${questionWord.word}"의 뜻은 무엇일까요?',
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 16),

        // 선택지 목록
        Expanded(
          child: ListView.builder(
            itemCount: options.length,
            itemBuilder: (context, index) {
              final bool isSelected = selectedIndex == index;
              final bool isCorrectAnswer =
                  questionWord.word == options[index].word;

              // 결과에 따른 색상 설정
              Color cardColor = Colors.white;
              if (isCorrect != null) {
                if (isSelected && isCorrect) {
                  cardColor = Colors.green.shade100;
                } else if (isSelected && !isCorrect) {
                  cardColor = Colors.red.shade100;
                } else if (isCorrectAnswer) {
                  cardColor = Colors.green.shade50;
                }
              } else if (isSelected) {
                cardColor = AppColors.accent.withOpacity(0.1);
              }

              return GestureDetector(
                onTap:
                    isCorrect != null
                        ? null
                        : () => _handleWordMatchingAnswer(index),
                child: Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.accent : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    options[index].meaning,
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // 결과 메시지
        if (isCorrect != null)
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            margin: EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isCorrect
                  ? '정답입니다! +5점'
                  : '틀렸습니다. 정답은 "${questionWord.meaning}"입니다.',
              style: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  // 단어 퍼즐 게임 위젯 (수정)
  Widget _buildWordPuzzleGame() {
    final Word puzzleWord = _currentGameData['word'];
    final List<String> shuffledChars = _currentGameData['shuffledChars'];
    final String userAnswer = _currentGameData['userAnswer'];
    final bool? isCorrect = _currentGameData['isCorrect'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 게임 제목
        Text(
          '단어 퍼즐',
          style: GoogleFonts.quicksand(
            fontSize: 14, // 축소
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8), // 축소
        // 문제 설명
        Container(
          padding: EdgeInsets.all(8), // 축소
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8), // 축소
          ),
          child: Column(
            children: [
              Text(
                '다음 글자들을 올바른 순서로 배열하세요',
                style: GoogleFonts.quicksand(
                  fontSize: 12, // 축소
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 4), // 축소

              Text(
                '의미: ${puzzleWord.meaning}',
                style: GoogleFonts.quicksand(
                  fontSize: 11, // 축소
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2, // 최대 2줄
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const SizedBox(height: 8), // 축소
        // 섞인 글자 표시 - 스크롤 가능하게 변경
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children:
                shuffledChars.map((char) {
                  return Container(
                    width: 32, // 축소
                    height: 32, // 축소
                    margin: EdgeInsets.symmetric(horizontal: 3), // 축소
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6), // 축소
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      char,
                      style: GoogleFonts.quicksand(
                        fontSize: 16, // 축소
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),

        const SizedBox(height: 12), // 축소
        // 사용자 입력 필드
        if (isCorrect == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0), // 축소
            child: TextField(
              decoration: InputDecoration(
                hintText: '정답을 입력하세요',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8), // 축소
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ), // 축소
                isDense: true, // 텍스트필드 높이 축소
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                fontSize: 14, // 축소
                color: AppColors.textPrimary,
              ),
              onChanged: (value) {
                setState(() {
                  _currentGameData['userAnswer'] = value;
                });
              },
            ),
          ),

        const SizedBox(height: 8), // 축소
        // 제출 버튼
        if (isCorrect == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              onPressed: userAnswer.isEmpty ? null : _submitPuzzleAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                disabledBackgroundColor: Colors.grey.shade300,
                padding: EdgeInsets.symmetric(vertical: 8), // 축소
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // 축소
                ),
                minimumSize: Size(double.infinity, 32), // 고정 높이
              ),
              child: Text(
                '정답 제출',
                style: GoogleFonts.quicksand(
                  fontSize: 14, // 축소
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

        // 결과 메시지
        if (isCorrect != null)
          Container(
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12), // 축소
            margin: EdgeInsets.only(top: 8), // 축소
            decoration: BoxDecoration(
              color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(8), // 축소
            ),
            child: Column(
              children: [
                Text(
                  isCorrect ? '정답입니다! +10점' : '틀렸습니다.',
                  style: GoogleFonts.quicksand(
                    fontSize: 14, // 축소
                    fontWeight: FontWeight.bold,
                    color:
                        isCorrect ? Colors.green.shade800 : Colors.red.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4), // 축소

                Text(
                  '정답: ${puzzleWord.word}',
                  style: GoogleFonts.quicksand(
                    fontSize: 12, // 축소
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// 이미지 퀴즈 게임 위젯
  Widget _buildImageGuessingGame() {
    final Word questionWord = _currentGameData['questionWord'];
    final List<Word> options = _currentGameData['options'];
    final int? selectedIndex = _currentGameData['selectedIndex'];
    final bool? isCorrect = _currentGameData['isCorrect'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 게임 제목
        Text(
          '이미지 퀴즈',
          style: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // 문제 이미지
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'img/${questionWord.word}.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // 이미지가 없는 경우 플레이스홀더 표시
                  return Container(
                    color: Colors.grey.shade200,
                    child: Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 문제 설명
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '이 그림은 무엇을 나타내나요?',
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 16),

        // 선택지 목록
        Expanded(
          flex: 3,
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: options.length,
            itemBuilder: (context, index) {
              final bool isSelected = selectedIndex == index;
              final bool isCorrectAnswer =
                  questionWord.word == options[index].word;

              // 결과에 따른 색상 설정
              Color cardColor = Colors.white;
              if (isCorrect != null) {
                if (isSelected && isCorrect) {
                  cardColor = Colors.green.shade100;
                } else if (isSelected && !isCorrect) {
                  cardColor = Colors.red.shade100;
                } else if (isCorrectAnswer) {
                  cardColor = Colors.green.shade50;
                }
              } else if (isSelected) {
                cardColor = AppColors.accent.withOpacity(0.1);
              }

              return GestureDetector(
                onTap:
                    isCorrect != null
                        ? null
                        : () => _handleImageGuessingAnswer(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.accent : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    options[index].word,
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ),

        // 결과 메시지
        if (isCorrect != null)
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            margin: EdgeInsets.only(top: 16),
            decoration: BoxDecoration(
              color: isCorrect ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isCorrect
                  ? '정답입니다! +5점'
                  : '틀렸습니다. 정답은 "${questionWord.word}"입니다.',
              style: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  /// 오류 위젯
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            '게임을 불러올 수 없습니다.',
            style: GoogleFonts.quicksand(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _moveToNextGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('다른 게임 시도'),
          ),
        ],
      ),
    );
  }
}
