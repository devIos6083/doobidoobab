import 'dart:async';
import 'dart:math';

import 'package:doobi/models/words.dart';
import 'package:doobi/utils/constants.dart';
import 'package:doobi/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:just_audio/just_audio.dart';

class PronunciationSpeedGameScreen extends StatefulWidget {
  final String difficulty;
  final int quizCount;
  final Function(String) onWordLearned;

  const PronunciationSpeedGameScreen({
    required this.difficulty,
    required this.quizCount,
    required this.onWordLearned,
    super.key,
  });

  @override
  _PronunciationSpeedGameScreenState createState() =>
      _PronunciationSpeedGameScreenState();
}

class _PronunciationSpeedGameScreenState
    extends State<PronunciationSpeedGameScreen>
    with SingleTickerProviderStateMixin {
  // 타입 파라미터 제거
  // Game state variables
  late List<Word> gameWords;
  late List<Word> currentOptions;
  late Word currentWord;
  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  bool isAnswerSelected = false;
  bool isGameCompleted = false;
  int? selectedIndex;
  bool isCorrect = false;
  bool isLoading = true;

  // Sound play counter - 각 문제마다 소리 재생 횟수를 제한
  int remainingSoundPlays = 5;

  // Combo and scoring system
  int currentCombo = 0;
  int highestCombo = 0;
  int totalScore = 0;

  // 콤보 효과 - 소리 재생 시간 조정
  double soundPlaybackRate = 1.0; // 기본 재생 속도

  // Timer related variables
  late Timer _gameTimer;
  int _secondsRemaining = 60; // Default 60 seconds

  // Animation controller
  late AnimationController _animationController;

  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();

  // 오디오 재생 중인지 확인하는 변수
  bool isPlayingSound = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // 오디오 플레이어 상태 리스너 추가
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        setState(() {
          isPlayingSound = false;
        });
      }
    });

    // Start game setup
    _setupGame();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _audioPlayer.dispose();
    if (_gameTimer.isActive) {
      _gameTimer.cancel();
    }
    super.dispose();
  }

  Future<void> _setupGame() async {
    setState(() {
      isLoading = true;
      // 난이도에 따른 타이머 설정
      if (widget.difficulty == '쉬움') {
        _secondsRemaining = 60;
      } else if (widget.difficulty == '보통') {
        _secondsRemaining = 45;
      } else {
        _secondsRemaining = 30;
      }
    });

    try {
      // 난이도에 따른 단어 필터링
      List<Word> availableWords = filterWordsByDifficulty(widget.difficulty);

      // 셔플 및 설정된 문제 수만큼 단어 선택
      availableWords.shuffle();

      // 설정된 문제 수(widget.quizCount)만큼 단어 가져오기
      gameWords = availableWords.take(widget.quizCount).toList();

      AppLogger.info(
        '게임 시작: 난이도=${widget.difficulty}, 문제 수=${gameWords.length}',
      );

      // 첫 번째 문제 설정
      _setNextQuestion();

      // 게임 타이머 시작
      _startGameTimer();
    } catch (e) {
      AppLogger.error('게임 설정 오류', e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('게임 설정 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Start the game timer
  void _startGameTimer() {
    _gameTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining <= 0) {
          _gameTimer.cancel();
          _endGame();
        } else {
          _secondsRemaining--;
        }
      });
    });
  }

  // End the game when time runs out
  void _endGame() {
    setState(() {
      isGameCompleted = true;
    });
  }

  // Set up the next question with 4 options (1 correct, 3 distractors)
  void _setNextQuestion() {
    if (currentQuestionIndex >= gameWords.length) {
      setState(() {
        isGameCompleted = true;
      });
      return;
    }

    // 현재 문제 로그
    AppLogger.info('문제 ${currentQuestionIndex + 1}/${gameWords.length} 설정');

    // Get current word
    currentWord = gameWords[currentQuestionIndex];

    // 소리 재생 횟수 초기화
    remainingSoundPlays = 5;

    // 콤보에 따른 재생 속도 설정
    soundPlaybackRate = min(1.0 + (currentCombo * 0.2), 2.0); // 최대 2배속으로 제한

    // Collect all words except current for distractors
    List<Word> possibleDistractors =
        allWords.where((word) => word.word != currentWord.word).toList();

    // Shuffle and take 3 distractors
    possibleDistractors.shuffle();
    List<Word> distractors = possibleDistractors.take(3).toList();

    // Combine with correct answer and shuffle
    currentOptions = [...distractors, currentWord];
    currentOptions.shuffle();

    // Reset state for new question
    setState(() {
      isAnswerSelected = false;
      selectedIndex = null;
    });

    // 문제 설정 후 자동 재생하지 않음
    // 사용자가 버튼을 클릭해야 소리가 재생됨
  }

  // Play word pronunciation (사용자 버튼 클릭 시 호출)
  Future<void> _playWordPronunciation() async {
    // 소리 재생 횟수가 남아있는지 확인
    if (remainingSoundPlays <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('더 이상 들을 수 없습니다.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    // 이미 재생 중이면 중단
    if (isPlayingSound) {
      return;
    }

    setState(() {
      isPlayingSound = true;
      remainingSoundPlays--;
    });

    try {
      // 단어 발음 파일 경로 지정
      String audioPath = 'sound/${currentWord.word}.mp3';
      AppLogger.info('단어 발음 재생 시도: $audioPath, 남은 횟수: $remainingSoundPlays');

      try {
        // 오디오 플레이어 초기화 (중요!)
        await _audioPlayer.stop();

        // 오디오 파일 로드 및 재생
        await _audioPlayer.setAsset(audioPath);
        await _audioPlayer.setSpeed(soundPlaybackRate); // 콤보에 따른 재생 속도 설정
        await _audioPlayer.play();

        AppLogger.info(
          '발음 재생 성공: ${currentWord.word}, 속도: ${soundPlaybackRate}x',
        );
      } catch (audioError) {
        AppLogger.warning('오디오 파일 로드 실패: $audioError');
        setState(() {
          isPlayingSound = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('발음 재생 중 오류가 발생했습니다.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('발음 재생 오류', e);
      setState(() {
        isPlayingSound = false;
      });
    }
  }

  // Calculate score for a correct answer
  int _calculateScore(bool isCorrect) {
    if (!isCorrect) {
      return 0;
    }

    // Base score
    int baseScore = 100;

    // Sound plays bonus (less plays = more points)
    int soundPlaysBonus = (5 - remainingSoundPlays) * 10; // 덜 들을수록 보너스 점수

    // Combo multiplier (increases with consecutive correct answers)
    double comboMultiplier = 1.0 + (currentCombo * 0.1); // 10% bonus per combo

    // Difficulty multiplier
    double difficultyMultiplier = 1.0;
    if (widget.difficulty == '보통') {
      difficultyMultiplier = 1.5;
    } else if (widget.difficulty == '어려움') {
      difficultyMultiplier = 2.0;
    }

    // Calculate total
    int totalPoints =
        ((baseScore + soundPlaysBonus) * comboMultiplier * difficultyMultiplier)
            .round();

    return totalPoints;
  }

  // Handle user answer selection
  void _handleAnswer(int index) {
    if (isAnswerSelected) return;

    bool correct = currentOptions[index].word == currentWord.word;
    int scoreEarned = _calculateScore(correct);

    setState(() {
      isAnswerSelected = true;
      selectedIndex = index;
      isCorrect = correct;

      if (correct) {
        correctAnswers++;
        currentCombo++;
        highestCombo = max(highestCombo, currentCombo);
        totalScore += scoreEarned;
        widget.onWordLearned(currentWord.word);
      } else {
        currentCombo = 0;
      }
    });

    // Animate feedback
    _animationController.reset();
    _animationController.forward();

    // Move to next question after delay (shorter for speed game)
    Future.delayed(Duration(milliseconds: 800), () {
      if (mounted) {
        currentQuestionIndex++;
        _setNextQuestion();
      }
    });
  }

  // Play again button handler
  void _playAgain() {
    setState(() {
      currentQuestionIndex = 0;
      correctAnswers = 0;
      currentCombo = 0;
      highestCombo = 0;
      totalScore = 0;
      isGameCompleted = false;
    });

    _setupGame();
  }

  // Format time display (mm:ss)
  String _formatTime(int seconds) {
    int mins = seconds ~/ 60;
    int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // Build a word option item
  Widget _buildWordOption(int index) {
    final word = currentOptions[index];
    final bool isSelected = selectedIndex == index;
    final bool isThisCorrect = word.word == currentWord.word;

    // Determine color based on selection and correctness
    Color itemColor = Colors.grey.shade100;
    if (isAnswerSelected) {
      if (isSelected) {
        itemColor = isCorrect ? Colors.green.shade100 : Colors.red.shade100;
      } else if (isThisCorrect) {
        itemColor = Colors.green.shade100;
      }
    }

    return GestureDetector(
      onTap: isAnswerSelected ? null : () => _handleAnswer(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        margin: EdgeInsets.symmetric(vertical: 8),
        height: 120,
        decoration: BoxDecoration(
          color: itemColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(
            color:
                isSelected
                    ? (isCorrect ? Colors.green : Colors.red)
                    : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // 단어 이미지 표시 (기존 텍스트 대신 이미지 표시)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'img/${word.word}.png',
                    height: 80,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // 이미지 로드 실패 시 대체 UI
                      return Container(
                        height: 80,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // 정답 선택 후에만 단어 텍스트 표시
            if (isAnswerSelected)
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    word.word,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

            // Correct/incorrect indicator
            if (isAnswerSelected && (isSelected || isThisCorrect))
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isThisCorrect ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isThisCorrect ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Build game stats display
  Widget _buildGameStats() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Time remaining
          Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timer,
                    size: 18,
                    color:
                        _secondsRemaining <= 10 ? Colors.red : AppColors.accent,
                  ),
                  SizedBox(width: 4),
                  Text(
                    _formatTime(_secondsRemaining),
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          _secondsRemaining <= 10
                              ? Colors.red
                              : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '남은 시간',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          // Current score
          Column(
            children: [
              Text(
                totalScore.toString(),
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
              Text(
                '점수',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          // Current combo
          Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bolt,
                    size: 18,
                    color:
                        currentCombo >= 3
                            ? Colors.orange
                            : AppColors.textSecondary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'x$currentCombo',
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color:
                          currentCombo >= 3
                              ? Colors.orange
                              : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                '콤보',
                style: GoogleFonts.quicksand(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build the pronunciation button
  Widget _buildPronunciationButton() {
    return GestureDetector(
      onTap: _playWordPronunciation,
      child: Container(
        width: 80, // 크기 약간 키움
        height: 80, // 크기 약간 키움
        decoration: BoxDecoration(
          color: isPlayingSound ? AppColors.accent : AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 메인 아이콘
            Icon(
              isPlayingSound ? Icons.volume_up : Icons.play_arrow,
              color: Colors.white,
              size: 36, // 크기 키움
            ),

            // 남은 재생 횟수 표시
            Positioned(
              bottom: 10,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$remainingSoundPlays',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 콤보에 따른 정보 표시
  Widget _buildComboInfo() {
    // 콤보가 쌓일수록 재생 속도가 빨라진다는 안내
    if (currentCombo >= 3) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.speed, size: 16, color: Colors.orange),
              SizedBox(width: 4),
              Text(
                '콤보 적립! 발음 속도 ${soundPlaybackRate.toStringAsFixed(1)}x',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
        ],
      );
    }
    return SizedBox.shrink(); // 콤보가 적으면 표시하지 않음
  }

  // Build the game completion screen
  Widget _buildGameCompletionScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie animation based on score
          SizedBox(
            height: 150,
            child: Lottie.asset(
              totalScore >= 1000
                  ? 'lottie/celebration.json'
                  : (totalScore >= 500
                      ? 'lottie/good_job.json'
                      : 'lottie/try_again.json'),
              repeat: true,
            ),
          ),

          SizedBox(height: 24),

          // Score display
          Text(
            '게임 종료!',
            style: GoogleFonts.quicksand(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 16),

          // Stats container
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 32),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Total score
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '최종 점수:',
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      totalScore.toString(),
                      style: GoogleFonts.quicksand(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),

                Divider(height: 24),

                // Correct answers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '맞춘 단어:',
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$correctAnswers / ${gameWords.length}',
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 8),

                // Highest combo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '최대 콤보:',
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.bolt,
                          size: 18,
                          color:
                              highestCombo >= 5
                                  ? Colors.orange
                                  : AppColors.textPrimary,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'x$highestCombo',
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                highestCombo >= 5
                                    ? Colors.orange
                                    : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 32),

          // Play again button
          ElevatedButton.icon(
            onPressed: _playAgain,
            icon: Icon(Icons.replay),
            label: Text(
              '다시 하기',
              style: GoogleFonts.quicksand(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          SizedBox(height: 16),

          // Back to menu button
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.home),
            label: Text(
              '메뉴로 돌아가기',
              style: GoogleFonts.quicksand(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override // 여기에 @override 어노테이션 추가
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '발음 스피드 게임',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          isLoading
              ? Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              )
              : isGameCompleted
              ? _buildGameCompletionScreen()
              : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Game stats
                      _buildGameStats(),

                      SizedBox(height: 16),

                      // Game instructions and pronunciation button
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '발음을 듣고 맞는 이미지를 선택하세요',
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(height: 8),

                            // 콤보 정보 표시
                            _buildComboInfo(),

                            // Pronunciation button
                            _buildPronunciationButton(),
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // 현재 단어 진행 상황 표시
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '문제 ${currentQuestionIndex + 1}/${gameWords.length}',
                            style: GoogleFonts.quicksand(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Word options grid (2x2)
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.0,
                              ),
                          itemCount: currentOptions.length,
                          itemBuilder:
                              (context, index) => _buildWordOption(index),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
