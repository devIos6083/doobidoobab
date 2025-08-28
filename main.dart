import 'package:doobi/firebase_initializer.dart';
import 'package:doobi/screens/game_selection.dart';
import 'package:doobi/screens/main_screen.dart';
import 'package:doobi/screens/splash_screen.dart';
import 'package:doobi/screens/userinfo_screen.dart';
import 'package:doobi/screens/word_quiz.dart';
import 'package:doobi/services/navigation_service.dart';
import 'package:doobi/services/notification_services.dart';
import 'package:doobi/utils/constants.dart';
import 'package:doobi/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  final firebaseInitializer = FirebaseInitializer();
  await firebaseInitializer.initialize();


  // 알림 서비스 초기화
  await NotificationService().init();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([

    
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Enable debug logs in development mode
  AppLogger.enableDebugLogs = true;

  AppLogger.info('App starting up');

  runApp(
    // FirebaseProvider로 앱 전체를 감싸기
    FirebaseProvider(
      firebase: firebaseInitializer,
      child: const DoobiDoobabApp(),
    ),
  );
}

class DoobiDoobabApp extends StatelessWidget {
  const DoobiDoobabApp({super.key});

  @override
  Widget build(BuildContext context) {
    final NavigationService navigationService = NavigationService();
    final firebase = FirebaseProvider.of(context).firebase;

    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      navigatorKey: navigationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.splash,

      routes: {
        AppRoutes.splash: (context) => SplashScreen(),
        AppRoutes.userInfo: (context) => UserInfoScreen(firebase: firebase),
        AppRoutes.main: (context) => const MainScreen(),
        AppRoutes.gameSelection: (context) => const GameSelectionScreen(),
      },

      // 인자가 필요한 화면 처리
      onGenerateRoute: (settings) {
        // 단어 퀴즈 화면으로 이동하는 경우
        if (settings.name == AppRoutes.wordQuiz) {
          // 인자 추출
          final Map<String, dynamic> args =
              settings.arguments as Map<String, dynamic>;

          // WordQuizScreen으로 인자 전달하며 이동
          return MaterialPageRoute(
            builder:
                (context) => WordQuizScreen(
                  difficulty: args['difficulty'],
                  quizCount: args['quizCount'],
                ),
          );
        }

        // 인식할 수 없는 라우트인 경우 메인 화면으로 리다이렉트
        AppLogger.warning('알 수 없는 라우트: ${settings.name}');
        return MaterialPageRoute(builder: (context) => const MainScreen());
      },
    );
  }
}
