// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// 애플리케이션 라우트 이름
class AppRoutes {
  static const String splash = '/';
  static const String userInfo = '/user-info';
  static const String main = '/main';
  static const String gameSelection = '/game-selection';
  static const String wordQuiz = '/word-quiz';
}

/// 애플리케이션 문자열 상수
class AppStrings {
  // 앱 일반
  static const String appName = 'Doobi Dooba';
  static const String appTagline = '배우는 즐거움, 그림의 마법!';
  static const String loading = 'LOADING';

  // 사용자 정보 화면
  static const String userInfoTitle = '사용자 정보 입력';
  static const String startButton = '시작하기';
  static const String nameHint = '이름을 입력해주세요';
  static const String ageSelection = '나이를 선택해주세요';
  static const String genderSelection = '성별을 선택해주세요';
  static const String quizCountLabel = '퀴즈 문제 수:';
  static const String difficultySelection = '난이도를 선택해주세요';
  static const String male = '남자';
  static const String female = '여자';
  static const String validationError = '모든 정보를 입력해주세요';
  static const String ageConfirm = '확인';
  static const String ageSuffix = '세';

  // 메인 화면
  static const String userNotFound = '사용자 정보를 찾을 수 없습니다';
  static const String registerUser = '사용자 정보 등록하기';
  static const String greeting = '안녕하세요, %s님!';
  static const String consecutiveDays = '%d일째 접속 중입니다';
  static const String selectedDifficulty = '선택한 난이도: %s';
  static const String quizCount = '퀴즈 문제 수: %d';
  static const String startLearning = '학습 시작하기';
  static const String loadingData = '정보를 불러오는 중...';

  // 게임 선택 화면
  static const String learningMode = '학습 모드';
  static const String learningModeSubtitle = '오늘도 즐겁게 언어를 배워볼까요?';

  // 에러 메시지
  static const String savingError = '저장 중 오류가 발생했습니다';
  static const String loadingError = '데이터 로드 중 오류가 발생했습니다';
}

/// 애플리케이션 에셋 경로
class AppAssets {
  static const String studyLottie = 'lottie/cake.json';
  static const String avatarLottie = 'lottie/cut1.json';
  static const String loadingLottie = 'lottie/dance.json';
  static const String errorLottie = 'lottie/boom.json';
  static const String successLottie = 'lottie/welcome.json';
}

/// 애플리케이션 색상 정의
class AppColors {
  static const Color primary = Color(0xFFFFD54F);
  static const Color primaryLight = Color(0xFFFFECB3);
  static const Color secondaryLight = Color(0xFFFFF9C4);
  static const Color accent = Color(0xFFFF8F00);
  static const Color textPrimary = Color(0xFF424242);
  static const Color textSecondary = Color(0xFF757575);
  static const Color background = Color(0xFFFFF9C4);
  static const Color white = Colors.white;

  // 게임별 색상
  static const Color wordQuizColor = Color(0xFFFF6D00);
  static const Color sentenceMakerColor = Color(0xFF00B0FF);
  static const Color pronunciationColor = Color(0xFF00C853);
  static const Color wordShadowColor = Color(0xFF8E44AD); // Purple
  static const Color pronunciationSpeedColor = Color(0xFFE74C3C); // Red
}

/// 애플리케이션 크기 상수
class AppDimensions {
  static const double defaultPadding = 20.0;
  static const double defaultRadius = 15.0;
  static const double buttonRadius = 30.0;
  static const double iconSize = 24.0;
  static const double avatarSize = 250.0;
  static const double loadingBarWidth = 300.0;
  static const double loadingBarHeight = 15.0;
  static const double cardRadius = 16.0;
}

/// 애플리케이션 테마
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
      ),
      scaffoldBackgroundColor: AppColors.background,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.defaultRadius),
        ),
        filled: true,
        fillColor: AppColors.white.withOpacity(0.7),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        ),
        elevation: 4,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
    );
  }
}
