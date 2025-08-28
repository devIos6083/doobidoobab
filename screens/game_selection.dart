// ignore_for_file: deprecated_member_use

import 'package:doobi/screens/comic_gallery_screen.dart';
import 'package:doobi/screens/pronunciation_speed_game.dart';
import 'package:doobi/screens/word_quiz.dart';
import 'package:doobi/utils/constants.dart';
import 'package:doobi/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

/// 게임 선택 화면
///
/// 사용자가 플레이할 게임 유형을 선택하고 게임 설정(난이도, 문제 수)을 조정할 수 있는 화면입니다.
class GameSelectionScreen extends StatefulWidget {
  const GameSelectionScreen({super.key});

  @override
  _GameSelectionScreenState createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen>
    with SingleTickerProviderStateMixin {
  // 선택된 게임 설정을 위한 상태 변수들
  int _selectedQuizCount = 5; // 기본값 5문제
  String _selectedDifficulty = '쉬움';
  bool _isLoading = false;

  // 애니메이션 컨트롤러
  late AnimationController _animationController;

  // 선택된 게임 인덱스 (기본값: 아직 선택 안됨)
  int? _selectedGameIndex;

  // 난이도별 색상 맵
  final Map<String, Color> _difficultyColors = {
    '쉬움': Colors.green,
    '보통': Colors.orange,
    '어려움': Colors.red,
  };

  @override
  void initState() {
    super.initState();

    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    AppLogger.event('게임 선택 화면 초기화됨');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 게임 설정 다이얼로그를 표시하는 함수
  void _showGameSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            // StatefulBuilder 추가 - 바텀 시트 내에서 상태 변경을 가능하게 함
            builder: (BuildContext context, StateSetter setSheetState) {
              return _buildSettingsBottomSheet(setSheetState);
            },
          ),
    );
  }

  /// 게임 시작 함수

  void _startGame() async {
    if (_selectedGameIndex == null) {
      // 게임이 선택되지 않은 경우 에러 메시지 표시
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게임을 선택해주세요'), backgroundColor: Colors.red),
      );
      return;
    }

    // 로딩 상태 설정
    setState(() {
      _isLoading = true;
    });

    try {
      // 선택된 게임 타입에 따라 다른 화면으로 이동
      switch (_selectedGameIndex) {
        case 0: // 게임방 (단어 퀴즈 게임)
          AppLogger.event(
            '단어 퀴즈 게임 시작: 난이도=$_selectedDifficulty, 문제수=$_selectedQuizCount',
          );

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => WordQuizScreen(
                      difficulty: _selectedDifficulty,
                      quizCount: _selectedQuizCount,
                      onWordLearned: (String learnedWord) {
                        // 단어 학습 완료 콜백
                        AppLogger.info('단어 학습 완료: $learnedWord');
                      },
                    ),
              ),
            );
          }
          break;

        case 1: // 만화방 (갤러리 화면)
          AppLogger.event('만화방 화면으로 이동');

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ComicGalleryScreen()),
            );
          }
          break;
        case 2: // 발음 스피드 게임 - 수정: 인덱스를 3으로 변경
          AppLogger.event(
            '발음 스피드 게임 시작: 난이도=$_selectedDifficulty, 문제수=$_selectedQuizCount',
          );

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => PronunciationSpeedGameScreen(
                      difficulty: _selectedDifficulty,
                      quizCount: _selectedQuizCount,
                      onWordLearned: (String learnedWord) {
                        // 단어 학습 완료 콜백
                        AppLogger.info('단어 학습 완료: $learnedWord');
                      },
                    ),
              ),
            );
          }
          break;
      }
    } catch (e) {
      AppLogger.error('게임 시작 오류', e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게임을 시작하는 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // 로딩 상태 해제
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '게임 선택',
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
      body: Stack(
        children: [
          Column(
            children: [
              // 상단 타이틀 섹션
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      AppStrings.learningMode,
                      style: GoogleFonts.quicksand(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      AppStrings.learningModeSubtitle,
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        color: AppColors.textPrimary.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // 게임 목록 섹션
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 게임 선택 안내 텍스트
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Text(
                          '원하는 게임을 선택하세요',
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),

                      // 게임 카드 목록

                      // 리스트뷰의 게임 카드 인덱스도 수정
                      Expanded(
                        child: ListView(
                          children: [
                            // 단어 퀴즈 게임
                            _buildGameCard(
                              index: 0,
                              title: '게임방',
                              description: '그림을 보고 따라 그려보세요!',
                              iconData: Icons.brush_outlined,
                              color: AppColors.wordQuizColor,
                            ),

                            SizedBox(height: 16),

                            // 문장 만들기 게임
                            _buildGameCard(
                              index: 1,
                              title: '만화방',
                              description: '지금까지 그린 그림들을 만화처럼\n한눈에 감상해보세요!',
                              iconData: Icons.collections_bookmark,
                              color: AppColors.sentenceMakerColor,
                            ),

                            SizedBox(height: 16),

                            // 발음 스피드 게임 - 수정: 인덱스를 3으로 변경
                            _buildGameCard(
                              index: 2,
                              title: '발음 스피드 게임',
                              description: '제한 시간 내에 많은 단어의 발음을 맞추세요',
                              iconData: Icons.speed,
                              color: AppColors.pronunciationSpeedColor,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 하단 버튼 섹션
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // 게임 설정 버튼
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _showGameSettings,
                        icon: Icon(
                          Icons.settings,
                          color: AppColors.textPrimary,
                        ),
                        label: Text(
                          '설정',
                          style: GoogleFonts.quicksand(
                            color: AppColors.textPrimary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: Colors.grey.shade300,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(width: 12),

                    // 게임 시작 버튼
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _startGame,
                        icon:
                            _isLoading
                                ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                : Icon(Icons.play_arrow),
                        label: Text(
                          _isLoading ? '로딩 중...' : '시작하기',
                          style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          disabledBackgroundColor: AppColors.accent.withOpacity(
                            0.5,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 로딩 오버레이
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: Lottie.asset(
                            'lottie/dance.json',
                            fit: BoxFit.contain,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '게임을 준비하는 중...',
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 게임 카드 위젯 생성
  Widget _buildGameCard({
    required int index,
    required String title,
    required String description,
    required IconData iconData,
    required Color color,
  }) {
    final isSelected = _selectedGameIndex == index;

    return GestureDetector(
      onTap:
          _isLoading
              ? null
              : () {
                setState(() {
                  _selectedGameIndex = index;
                });
                // 선택 애니메이션 재생
                _animationController.reset();
                _animationController.forward();
              },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? color.withOpacity(0.3) : Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // 게임 아이콘
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: color, size: 30),
            ),

            SizedBox(width: 16),

            // 게임 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.quicksand(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // 선택 표시 아이콘
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: Icon(Icons.check_circle, color: color, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  /// 난이도 선택 버튼 위젯
  Widget _buildDifficultyButton(
    String difficulty,
    Color color,
    StateSetter setSheetState,
  ) {
    final bool isSelected = _selectedDifficulty == difficulty;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          // 두 setState를 함께 호출 - 바텀 시트와 메인 화면 모두 업데이트
          setSheetState(() {
            _selectedDifficulty = difficulty;
          });
          setState(() {
            _selectedDifficulty = difficulty;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              difficulty,
              style: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 문제 수 선택 위젯 (새로 추가)
  Widget _buildQuizCountSelector(StateSetter setSheetState) {
    return SizedBox(
      height: 180,
      child: Column(
        children: [
          // 슬라이더 제목과 현재 선택된 값 표시
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '문제 수',
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // 현재 문제 수 큰 표시
          Text(
            '$_selectedQuizCount',
            style: GoogleFonts.quicksand(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
            textAlign: TextAlign.center,
          ),

          // 1~10 범위의 슬라이더 (1단위로 변경)
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.primary.withOpacity(0.2),
              thumbColor: AppColors.accent,
              overlayColor: AppColors.accent.withOpacity(0.2),
              valueIndicatorColor: AppColors.accent,
              valueIndicatorTextStyle: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              trackHeight: 4.0,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.0),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 24.0),
            ),
            child: Slider(
              value: _selectedQuizCount.toDouble(),
              min: 1,
              max: 10,
              divisions: 9, // 1~10까지 10개 값, 9개 구간
              label: _selectedQuizCount.toString(),
              onChanged: (double value) {
                // 두 setState를 함께 호출 - 바텀 시트와 메인 화면 모두 업데이트
                setSheetState(() {
                  _selectedQuizCount = value.toInt();
                });
                setState(() {
                  _selectedQuizCount = value.toInt();
                });
              },
            ),
          ),

          // 값 설명
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1문제', style: TextStyle(color: AppColors.textSecondary)),
              Text('10문제', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  /// 설정 바텀 시트 위젯
  Widget _buildSettingsBottomSheet(StateSetter setSheetState) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          SizedBox(height: 20),

          // 타이틀
          Text(
            '게임 설정',
            style: GoogleFonts.quicksand(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 24),

          // 난이도 설정
          Text(
            '난이도 선택',
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 8),

          // 난이도 선택 버튼 그룹
          Row(
            children: [
              _buildDifficultyButton('쉬움', Colors.green, setSheetState),
              SizedBox(width: 10),
              _buildDifficultyButton('보통', Colors.orange, setSheetState),
              SizedBox(width: 10),
              _buildDifficultyButton('어려움', Colors.red, setSheetState),
            ],
          ),

          SizedBox(height: 24),

          // 문제 수 설정 (새로운 위젯 사용)
          _buildQuizCountSelector(setSheetState),

          SizedBox(height: 30),

          // 설정 완료 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                '설정 완료',
                style: GoogleFonts.quicksand(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // 여백 추가 (기기 하단 노치 등을 위한 안전 영역)
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
