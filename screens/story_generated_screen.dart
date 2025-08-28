// screens/story_generation_screen.dart
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:doobi/models/story_model.dart';
import 'package:doobi/models/words.dart';
import 'package:doobi/screens/story_result_screen.dart';
import 'package:doobi/services/drawing_service.dart';
import 'package:doobi/services/story_service.dart';
import 'package:doobi/utils/constants.dart';
import 'package:doobi/utils/logger.dart';
import 'package:doobi/widgets/enhanced_loading_game.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class StoryGenerationScreen extends StatefulWidget {
  final List<Word> learnedWords;
  final Map<String, Uint8List> drawings;

  const StoryGenerationScreen({
    super.key,
    required this.learnedWords,
    required this.drawings,
  });

  @override
  State<StoryGenerationScreen> createState() => _StoryGenerationScreenState();
}

class _StoryGenerationScreenState extends State<StoryGenerationScreen> {
  // 선택된 단어들
  List<Word> _selectedWords = [];

  // 단어 선택 상태
  bool _wordSelected = false;

  // 로딩 관련 상태 변수
  bool _isLoading = false;
  String _loadingMessage = '스토리를 생성하는 중입니다...';
  String _selectedWord = '';
  Uint8List? _selectedDrawing;
  double _loadingProgress = 0.0;

  // 서비스 객체
  final DrawingService _drawingService = DrawingService();
  final StoryService _storyService = StoryService();

  // 스토리 생성 완료 여부
  bool _storyGenerated = false;
  Story? _generatedStory;

  // 로딩 상태를 위한 타이머
  Timer? _loadingTimer;
  Timer? _storyGenerationTimer;

  @override
  void initState() {
    super.initState();
    _selectRandomWordsForChoosing();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _storyGenerationTimer?.cancel();
    super.dispose();
  }

  // 선택할 랜덤 단어 5개 가져오기
  void _selectRandomWordsForChoosing() {
    if (widget.learnedWords.isEmpty) {
      AppLogger.error('학습한 단어가 없습니다.');
      return;
    }

    final random = Random();
    final List<Word> availableWords = List.from(widget.learnedWords);

    // 사용자가 선택할 수 있는 5개의 단어 선택 (또는 더 적은 수의 단어가 있는 경우 모두 선택)
    final int wordsToSelect = min(5, availableWords.length);
    final selectedWords = <Word>[];

    for (int i = 0; i < wordsToSelect; i++) {
      if (availableWords.isEmpty) break;
      final int randomIndex = random.nextInt(availableWords.length);
      final selectedWord = availableWords[randomIndex];

      // 선택한 단어가 그림을 가지고 있는지 확인
      if (widget.drawings.containsKey(selectedWord.word)) {
        selectedWords.add(selectedWord);
        availableWords.removeAt(randomIndex);
      }
    }

    setState(() {
      _selectedWords = selectedWords;
    });

    AppLogger.info('선택 가능한 단어: ${_selectedWords.map((w) => w.word).toList()}');
  }

  // 사용자가 단어를 선택했을 때 호출되는 메서드
  void _onWordSelected(Word word) {
    setState(() {
      _selectedWord = word.word;
      _selectedDrawing = widget.drawings[_selectedWord];
      _wordSelected = true;
      _isLoading = true;
    });

    AppLogger.info('사용자가 선택한 단어: $_selectedWord');

    // 스토리 생성 시작
    _startActualStoryGeneration();

    // 로딩 애니메이션을 위한 타이머 (의도적으로 더 느리게 설정)
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_loadingProgress < 0.95) {
        setState(() {
          // 진행 속도를 단계별로 다르게 설정
          double increment = 0.005; // 기본 증가량

          // 중간 구간에서 더 느리게 진행
          if (_loadingProgress > 0.3 && _loadingProgress < 0.5) {
            increment = 0.003;
          } else if (_loadingProgress > 0.5 && _loadingProgress < 0.8) {
            increment = 0.002;
          } else if (_loadingProgress > 0.8) {
            increment = 0.001;
          }

          _loadingProgress += increment;

          // 메시지 변경
          if (_loadingProgress > 0.2 && _loadingProgress < 0.3) {
            _loadingMessage = '단어를 분석하고 있어요...';
          } else if (_loadingProgress > 0.4 && _loadingProgress < 0.5) {
            _loadingMessage = '재미있는 스토리를 구상 중이에요...';
          } else if (_loadingProgress > 0.6 && _loadingProgress < 0.7) {
            _loadingMessage = '스토리를 작성하고 있어요...';
          } else if (_loadingProgress > 0.8) {
            _loadingMessage = '이미지를 그리는 중입니다...';
          }
        });
      } else if (_storyGenerated) {
        // 스토리 생성이 완료되었고 로딩 애니메이션도 거의 끝났을 때
        // 100%로 설정하고 결과 화면으로 이동
        setState(() {
          _loadingProgress = 1.0;
        });

        timer.cancel();
        _loadingTimer = null;

        // 잠시 후 결과 화면으로 이동
        Future.delayed(const Duration(milliseconds: 1000), () {
          _navigateToResultScreen();
        });
      }
    });
  }

  // 실제 스토리 생성 프로세스 (로딩 애니메이션과 별도로 진행)
  Future<void> _startActualStoryGeneration() async {
    try {
      AppLogger.info('스토리 생성 시작: $_selectedWord');

      if (_selectedDrawing == null) {
        _showErrorAndNavigateBack('선택된 그림이 없습니다.');
        return;
      }

      // StoryService를 통해 전체 스토리 생성 (텍스트 + 이미지)
      final story = await _storyService.generateFullStory(
        _selectedWord,
        _selectedDrawing!,
      );

      if (story == null) {
        _showErrorAndNavigateBack('스토리 생성에 실패했습니다.');
        return;
      }

      // 스토리 생성 완료 상태 저장
      setState(() {
        _generatedStory = story;
        _storyGenerated = true;
      });

      AppLogger.info('스토리 생성 완료');

      // 로딩 UI가 충분히 진행될 때까지 기다리기 위해
      // _loadingTimer에서 결과 화면 이동 처리
    } catch (e) {
      AppLogger.error('스토리 생성 중 오류 발생', e);
      _showErrorAndNavigateBack('스토리 생성 중 오류가 발생했습니다.');
    }
  }

  // 결과 화면으로 이동
  void _navigateToResultScreen() {
    if (_generatedStory != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder:
              (context) => StoryResultScreen(
                word: _generatedStory!.word,
                story: _generatedStory!.storyText,
                storyImage: _generatedStory!.imageUrl,
                storyImages: _generatedStory!.imageUrls,
                userDrawing: _generatedStory!.userDrawing,
              ),
        ),
      );
    }
  }

  // 오류 표시 및 뒤로 가기
  void _showErrorAndNavigateBack(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  // 선택 화면 위젯
  Widget _buildWordSelectionScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            '스토리에 사용할 단어를 선택하세요',
            style: GoogleFonts.quicksand(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '선택한 단어와 그림을 기반으로 스토리가 생성됩니다.',
            style: GoogleFonts.quicksand(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child:
                _selectedWords.isEmpty
                    ? Center(
                      child: Text(
                        '학습한 단어가 없습니다.',
                        style: GoogleFonts.quicksand(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                    : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.0,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                      itemCount: _selectedWords.length,
                      itemBuilder: (context, index) {
                        final word = _selectedWords[index];
                        final drawing = widget.drawings[word.word];

                        return _buildWordCard(word, drawing);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  // 단어 카드 위젯
  Widget _buildWordCard(Word word, Uint8List? drawing) {
    return GestureDetector(
      onTap: () => _onWordSelected(word),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 그림 표시
            if (drawing != null)
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(drawing, fit: BoxFit.contain),
                  ),
                ),
              ),

            // 단어 표시
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  word.word,
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 로딩 화면 위젯
  Widget _buildLoadingScreen(BuildContext context) {
    // 화면 크기 가져오기
    final screenSize = MediaQuery.of(context).size;
    final availableHeight =
        screenSize.height -
        MediaQuery.of(context).padding.top -
        MediaQuery.of(context).padding.bottom -
        kToolbarHeight -
        16; // AppBar 높이 + 약간의 여유

    return Column(
      children: [
        // 로딩 섹션 - 고정 크기로 제한
        SizedBox(
          height: availableHeight * 0.35, // 화면의 35%
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 선택된 단어 표시
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    '"$_selectedWord" 스토리 만들기',
                    style: GoogleFonts.quicksand(
                      fontSize: 20, // 약간 축소
                      fontWeight: FontWeight.bold,
                      color: AppColors.accent,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 로티 애니메이션과 프로그레스 표시기
                SizedBox(
                  width: 110, // 축소
                  height: 110, // 축소
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 로티 애니메이션
                      Lottie.asset(
                        'lottie/ror.json',
                        width: 120, // 축소
                        height: 120, // 축소
                        fit: BoxFit.contain,
                      ),

                      // 원형 진행 표시기
                      CircularProgressIndicator(
                        value: _loadingProgress,
                        strokeWidth: 5, // 더 얇게
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12), // 축소
                // 로딩 메시지 - 최대 2줄로 제한
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  constraints: BoxConstraints(maxWidth: screenSize.width * 0.8),
                  child: Text(
                    _loadingMessage,
                    style: GoogleFonts.quicksand(
                      fontSize: 16, // 축소
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2, // 최대 2줄로 제한
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 8), // 축소
                // 로딩 진행률
                Text(
                  '${(_loadingProgress * 100).toInt()}%',
                  style: GoogleFonts.quicksand(
                    fontSize: 14, // 축소
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 로딩 중 미니 게임 - 개선된 버전 사용, 남은 공간으로 제한
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              12,
              0,
              12,
              8,
            ), // 좌우 여백 축소, 아래쪽 여백 추가
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: screenSize.width - 24, // 좌우 패딩 고려
                height: availableHeight * 0.65 - 8, // 화면의 65%, 아래쪽 여백 고려
                child: EnhancedLoadingGame(
                  learnedWords: widget.learnedWords,
                  onGameCompleted: (score) {
                    AppLogger.info('미니게임 완료: 점수=$score');
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryLight, AppColors.secondaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 헤더
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: AppColors.accent,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        _wordSelected ? '스토리 생성 중' : '단어 선택',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.quicksand(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // 균형을 위한 공간
                  ],
                ),
              ),

              // 내용 - 단어 선택 화면 또는 로딩 화면
              Expanded(
                child:
                    _wordSelected
                        ? _buildLoadingScreen(context)
                        : _buildWordSelectionScreen(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
