// ignore_for_file: deprecated_member_use

import 'dart:io';

import 'package:doobidoobab/core/services/notifications_services.dart';
import 'package:doobidoobab/core/services/user_service.dart';
import 'package:doobidoobab/core/utils/constants.dart';
import 'package:doobidoobab/core/utils/logger.dart';
import 'package:doobidoobab/data/models/user.dart' as app_user;
import 'package:doobidoobab/presentation/screens/game_selection.dart';
import 'package:doobidoobab/presentation/screens/userinfo_screen.dart';
import 'package:doobidoobab/presentation/screens/word_learning.dart';
import 'package:doobidoobab/presentation/widgets/profile_avater.dart';
import 'package:doobidoobab/presentation/widgets/streak_indicator.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import 'package:confetti/confetti.dart';
import 'package:rive/components.dart';
// ignore_for_file: deprecated_member_use
import 'package:doobidoobab/core/firebase_initialized.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final UserService _userService = UserService();
  app_user.User? _currentUser;
  bool _isLoading = true;
  bool _isActionInProgress = false;
  final ImagePicker _picker = ImagePicker();

  // 오늘의 게임 완료 상태
  bool _isDailyGameCompleted = false;

  // 애니메이션 컨트롤러들
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _countUpController;
  late Animation<int> _countUpAnimation;

  @override
  void initState() {
    super.initState();

    // 애니메이션 컨트롤러 초기화
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // 바운스 효과가 있는 애니메이션 정의
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    // 컨페티 효과 컨트롤러 초기화
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    // 카운트업 애니메이션 컨트롤러 초기화
    _countUpController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // 데이터 로드 및 출석 체크
    _initData();
  }

  Future<void> _initData() async {
    try {
      // 사용자 데이터 로드
      await _loadUserData();

      // 출석 체크 및 기록 업데이트
      await _trackAttendance();

      // 오늘의 게임 완료 상태 확인
      await _checkDailyGameStatus();

      // 알림 서비스 설정
      NotificationService().setDailyStudyCompleted(_isDailyGameCompleted);

      AppLogger.event('메인 화면 초기화 완료');
    } catch (e) {
      AppLogger.error('메인 화면 초기화 오류', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('데이터 로드 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    _countUpController.dispose();
    super.dispose();
  }

  /// 사용자 데이터를 데이터베이스에서 불러오는 함수
  Future<void> _loadUserData() async {
    try {
      final user = await _userService.getUser();

      if (!mounted) return;

      if (user == null) {
        // 사용자 정보가 없는 경우 UserInfoScreen으로 이동
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => UserInfoScreen(
                firebase: FirebaseInitializer(),
              ),
            ),
          );
          return;
        }
      }

      setState(() {
        _currentUser = user;
        _isLoading = false;
      });

      if (user != null) {
        // 카운트업 애니메이션 설정
        _countUpAnimation = IntTween(
          begin: 0,
          end: user.consecutiveDays,
        ).animate(
          CurvedAnimation(
            parent: _countUpController,
            curve: Curves.easeOut,
          ),
        );

        // 연속 접속일이 3일 이상인 경우 축하 애니메이션 표시
        if (user.consecutiveDays >= 3) {
          _animationController.forward();
          _confettiController.play();
        } else {
          // 첫 방문 또는 낮은 연속 접속일에도 애니메이션은 표시 (축하효과 없이)
          _animationController.forward();
        }

        // 카운트업 애니메이션 시작
        _countUpController.forward();
      }

      AppLogger.info('사용자 데이터 로드 완료: ${user?.name}');
    } catch (e) {
      AppLogger.error('사용자 데이터 로드 오류', e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사용자 정보를 불러오는 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 출석 기록을 업데이트하는 함수
  Future<void> _trackAttendance() async {
    try {
      await _userService.trackAttendance();

      // 사용자 정보 다시 로드하여 업데이트된 연속 출석일 확인
      final updatedUser = await _userService.getUser();

      if (!mounted) return;

      if (updatedUser != null && _currentUser != null) {
        final bool newMilestone =
            updatedUser.consecutiveDays > _currentUser!.consecutiveDays &&
                (updatedUser.consecutiveDays == 3 ||
                    updatedUser.consecutiveDays == 7 ||
                    updatedUser.consecutiveDays == 30);

        // 마일스톤 달성시 축하 효과
        if (newMilestone) {
          _confettiController.play();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('${updatedUser.consecutiveDays}일 연속 출석 달성! 축하합니다! 🎉'),
            backgroundColor: Colors.green,
          ));
        }

        setState(() {
          _currentUser = updatedUser;
        });
      }

      AppLogger.info('출석 기록 업데이트 완료');
    } catch (e) {
      AppLogger.error('출석 기록 업데이트 오류', e);
    }
  }

  /// 오늘의 게임 완료 상태를 확인하는 함수
  Future<void> _checkDailyGameStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCompletedDate = prefs.getString('last_daily_game_date');
      final today = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD 형식

      if (lastCompletedDate == today) {
        setState(() {
          _isDailyGameCompleted = true;
        });
        AppLogger.info('오늘의 게임이 이미 완료되었습니다.');
      } else {
        setState(() {
          _isDailyGameCompleted = false;
        });
        AppLogger.info('오늘의 게임이 아직 완료되지 않았습니다.');
      }
    } catch (e) {
      AppLogger.error('게임 완료 상태 확인 오류', e);
      setState(() {
        _isDailyGameCompleted = false;
      });
    }
  }

  /// 오늘의 게임 완료 상태를 업데이트하는 함수
  Future<void> _updateDailyGameStatus(bool completed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD 형식

      if (completed) {
        await prefs.setString('last_daily_game_date', today);
      }

      setState(() {
        _isDailyGameCompleted = completed;
      });

      // 알림 서비스 업데이트
      NotificationService().setDailyStudyCompleted(completed);

      AppLogger.info('게임 완료 상태 업데이트: $completed');
    } catch (e) {
      AppLogger.error('게임 완료 상태 업데이트 오류', e);
    }
  }

  /// 프로필 이미지를 선택하고 저장하는 함수
  Future<void> _pickImage() async {
    if (_isActionInProgress) return;

    setState(() {
      _isActionInProgress = true;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null && _currentUser != null) {
        final File imageFile = File(image.path);
        final String? imagePath =
            await _userService.saveCharacterImage(imageFile);

        if (imagePath != null) {
          print('이미지 경로: $imagePath');
          print('이미지 경로 타입: ${imagePath.runtimeType}');
          // 사용자 정보 업데이트
          final updatedUser = await _userService.saveUser(
            _currentUser!,
            characterPath: imagePath,
          );

          setState(() {
            _currentUser = updatedUser;
          });

          print('업데이트된 사용자: ${updatedUser?.id}');
          print('캐릭터 경로: ${updatedUser?.characterPath}');
          AppLogger.info('프로필 이미지 업데이트 완료');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('프로필 이미지가 업데이트되었습니다.'),
              backgroundColor: Colors.green,
            ));
          }
        }
      }
    } catch (e) {
      AppLogger.error('이미지 선택 오류', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('이미지 선택 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isActionInProgress = false;
        });
      }
    }
  }

  /// 게임 선택 화면으로 이동하는 함수
  void _navigateToGameSelection() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const GameSelectionScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutQuint;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  // WordLearningScreen을 실행하는 부분 수정
  void _startDailyWordGame() {
    if (_isActionInProgress) return;

    setState(() {
      _isActionInProgress = true;
    });

    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WordLearningScreen(
            difficulty: '보통',
            quizCount: 5,
            onWordLearned: (String learnedWord) {
              print('단어 학습 콜백 호출: $learnedWord');

              // 단어를 학습할 때마다 호출될 콜백
              if (_currentUser != null) {
                setState(() {
                  // 현재 학습한 단어 목록 가져오기
                  List<String> currentLearnedWords =
                      _currentUser!.learnedWords?.toList() ?? [];

                  // 이미 학습한 단어가 아닌 경우에만 추가
                  if (!currentLearnedWords.contains(learnedWord)) {
                    currentLearnedWords.add(learnedWord);
                    print(
                        '새 단어 추가: $learnedWord, 총 ${currentLearnedWords.length}개');

                    try {
                      // 사용자 ID 형식 확인 및 안전하게 변환
                      if (_currentUser!.id != null) {
                        // ID가 int이든 String이든 안전하게 String으로 변환
                        String userId = _currentUser!.id.toString();
                        print(
                            '사용자 ID: $userId (${_currentUser!.id.runtimeType})');

                        // UserService를 통해 사용자 정보 업데이트
                        _userService
                            .updateLearnedWords(userId, currentLearnedWords)
                            .then((success) {
                          print('단어 목록 업데이트 ${success ? '성공' : '실패'}');
                        });
                      } else {
                        print('사용자 ID가 null입니다');
                      }

                      // 로컬 상태 업데이트
                      _currentUser = _currentUser!.copyWith(
                        learnedWords: currentLearnedWords,
                      );
                    } catch (e) {
                      print('단어 목록 업데이트 중 오류: $e');
                    }
                  }
                });
              }
            },
          ),
        ),
      ).then((result) {
        // 게임 완료 후 처리
        _updateDailyGameStatus(true);
        AppLogger.info('단어 학습 게임 완료');

        setState(() {
          _isActionInProgress = false;
        });
      });
    } catch (e) {
      AppLogger.error('단어 학습 화면 이동 오류', e);
      setState(() {
        _isActionInProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중인 경우 로딩 표시
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'lottie/welcome.json',
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 20),
              Text(
                '정보를 불러오는 중...',
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 사용자 정보가 없는 경우
    if (_currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'lottie/boom.json',
                width: 150,
                height: 150,
              ),
              const SizedBox(height: 20),
              Text(
                '사용자 정보를 찾을 수 없습니다',
                style: GoogleFonts.quicksand(
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context)
                      .pushReplacementNamed(AppRoutes.userInfo);
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text(
                  '사용자 정보 등록하기',
                  style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 메인 화면 구성 (사용자 정보가 있는 경우)
    return Scaffold(
      backgroundColor: AppColors.background,
      // 컨페티 효과를 위한 Stack
      body: Stack(
        children: [
          // 컨페티 위젯 (축하 효과)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
                Colors.red,
              ],
            ),
          ),

          // 메인 콘텐츠
          CustomScrollView(
            slivers: [
              // 앱바
              SliverAppBar(
                expandedHeight: 80.0,
                floating: false,
                pinned: true,
                backgroundColor: AppColors.primary,
                actions: [
                  // 로그아웃 버튼
                  // 로그아웃 버튼
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    onPressed: () async {
                      try {
                        // 로딩 상태 표시
                        setState(() {
                          _isActionInProgress = true;
                        });

                        // 디버깅 로그
                        print('로그아웃 버튼 클릭: 로그아웃 프로세스 시작');

                        // 사용자 데이터 삭제 시도
                        final userDeleted = await _userService.deleteUser();
                        print('사용자 데이터 삭제 ${userDeleted ? '성공' : '실패'}');

                        // Firebase 로그아웃
                        await FirebaseAuth.instance.signOut();
                        print('Firebase 로그아웃 완료');

                        // SharedPreferences 초기화
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        print('SharedPreferences 초기화 완료');

                        // UserInfoScreen으로 이동 (로그아웃에서 왔다는 표시와 함께)
                        if (mounted) {
                          print('UserInfoScreen으로 이동 준비');
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserInfoScreen(
                                firebase: FirebaseInitializer(),
                              ),
                              // 로그아웃에서 왔음을 표시
                              settings: RouteSettings(arguments: 'fromLogout'),
                            ),
                          );
                        }
                      } catch (e) {
                        AppLogger.error('로그아웃 오류', e);
                        print('로그아웃 오류 상세: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('로그아웃 중 오류가 발생했습니다.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        // 로딩 상태 해제
                        if (mounted) {
                          setState(() {
                            _isActionInProgress = false;
                          });
                        }
                      }
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    '안녕하세요, ${_currentUser!.name}님!',
                    style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary,
                          AppColors.accent.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // 메인 콘텐츠
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 프로필 섹션
                      _buildProfileSection(),

                      const SizedBox(height: 24),

                      // 오늘의 단어 학습 섹션
                      _buildDailyWordSection(),

                      const SizedBox(height: 24),

                      // 연속 출석 섹션
                      _buildStreakSection(),

                      const SizedBox(height: 24),

                      // 시작하기 버튼
                      _buildStartButton(),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // 진행 중 인디케이터
          if (_isActionInProgress)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.accent,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 프로필 섹션 위젯
  Widget _buildProfileSection() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // 프로필 이미지
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  ProfileAvatar(
                    radius: 50,
                    imagePath: _currentUser!.characterPath,
                    name: _currentUser!.name,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 20),

            // 사용자 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUser!.name,
                    style: GoogleFonts.quicksand(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_currentUser!.age}세 · ${_currentUser!.gender}',
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 추가 정보 - 학습 통계
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '총 학습 단어: ${_currentUser!.learnedWords?.length ?? 0}개',
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 오늘의 단어 학습 섹션
  Widget _buildDailyWordSection() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 오늘의 단어 학습 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.auto_stories,
                        color: AppColors.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '오늘의 단어 학습',
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

                // 완료 상태 표시
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _isDailyGameCompleted
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isDailyGameCompleted
                            ? Icons.check_circle
                            : Icons.pending,
                        size: 16,
                        color: _isDailyGameCompleted
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isDailyGameCompleted ? '완료' : '진행 중',
                        style: GoogleFonts.quicksand(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _isDailyGameCompleted
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 오늘의 단어 컨텐츠
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.wordQuizColor.withOpacity(0.1),
                    Colors.blue.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.wordQuizColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'img/book.png', // 이미지 경로 확인 필요
                        width: 40,
                        height: 40,
                        errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.book,
                            size: 40,
                            color: AppColors.wordQuizColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '영어 단어 퀴즈',
                              style: GoogleFonts.quicksand(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.wordQuizColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '재미있는 단어를 배우고 그림으로 표현해보세요!',
                              style: GoogleFonts.quicksand(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 시작 버튼
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isDailyGameCompleted || _isActionInProgress
                          ? null
                          : _startDailyWordGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.wordQuizColor,
                        disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        _isDailyGameCompleted ? '오늘 학습 완료!' : '학습 시작하기',
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 연속 출석 섹션 위젯 (간소화 버전)
  Widget _buildStreakSection() {
    // 첫 접속일 여부 확인
    bool isFirstVisit = _currentUser!.consecutiveDays <= 1;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 연속 출석일 정보 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 제목
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.local_fire_department,
                        color: AppColors.accent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '연속 출석',
                      style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

                // 연속 출석일 배지 (애니메이션 효과)
                AnimatedBuilder(
                  animation: _countUpAnimation,
                  builder: (context, child) {
                    return ScaleTransition(
                      scale: _animation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _currentUser!.consecutiveDays > 3
                                  ? Colors.deepOrange
                                  : AppColors.accent,
                              _currentUser!.consecutiveDays > 7
                                  ? Colors.purple
                                  : AppColors.accent.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.whatshot,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isFirstVisit
                                  ? '첫 방문!'
                                  : '${_countUpAnimation.value}일째',
                              style: GoogleFonts.quicksand(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 첫 방문 또는 연속 출석 시각화
            isFirstVisit
                ? _buildFirstVisitMessage()
                : _buildStreakVisualization(),
          ],
        ),
      ),
    );
  }

  /// 첫 방문 환영 메시지
  Widget _buildFirstVisitMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 환영 애니메이션
          Lottie.asset(
            'lottie/welcome.json', // 환영 애니메이션 파일 경로 확인 필요
            width: 80,
            height: 80,
            repeat: true,
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.waving_hand, size: 40, color: Colors.blue),
          ),

          const SizedBox(width: 16),

          // 환영 메시지
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '환영합니다!',
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '첫 방문을 축하합니다! 매일 접속하면 연속 출석 달성 효과가 나타납니다.',
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 연속 출석 시각화
  Widget _buildStreakVisualization() {
    // 연속 출석일에 따른 메시지
    String streakMessage;
    if (_currentUser!.consecutiveDays <= 2) {
      streakMessage = '출석을 시작했어요!';
    } else if (_currentUser!.consecutiveDays <= 5) {
      streakMessage = '꾸준히 하고 계시네요!';
    } else if (_currentUser!.consecutiveDays <= 10) {
      streakMessage = '대단해요! 계속 유지하세요!';
    } else {
      streakMessage = '놀라운 기록입니다!';
    }

    return Column(
      children: [
        // 연속 출석 애니메이션
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              // 애니메이션 및 메시지
              Row(
                children: [
                  Lottie.asset(
                    'lottie/study.json', // 불꽃 애니메이션 파일 경로 확인 필요
                    width: 60,
                    height: 60,
                    repeat: true,
                    errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.local_fire_department,
                        size: 40,
                        color: AppColors.accent),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_currentUser!.consecutiveDays}일 연속 출석 중!',
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          streakMessage,
                          style: GoogleFonts.quicksand(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 스트릭 표시
              StreakIndicator(
                days: _currentUser!.consecutiveDays,
                maxDisplay: 7,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 시작하기 버튼 위젯
  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: _isActionInProgress ? null : _navigateToGameSelection,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          disabledBackgroundColor: AppColors.accent.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 8,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '놀이터',
              style: GoogleFonts.quicksand(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
