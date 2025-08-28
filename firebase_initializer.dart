// firebase_initializer.dart
import 'package:doobi/repositories/quiz_repository.dart';
import 'package:doobi/repositories/word_repository.dart';
import 'package:doobi/utils/logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart'; // 추가

/// Firebase 초기화 및 관리를 위한 유틸리티 클래스
class FirebaseInitializer {
  // 싱글톤 인스턴스
  static final FirebaseInitializer _instance = FirebaseInitializer._internal();

  factory FirebaseInitializer() => _instance;

  FirebaseInitializer._internal();

  // 저장소 인스턴스
  late final FirebaseQuizRepository quizRepository;
  late final FirebaseWordRepository wordRepository;

  // 초기화 여부
  bool _isInitialized = false;

  /// Firebase 초기화
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.info('Firebase가 이미 초기화되었습니다.');
      return;
    }

    try {
      AppLogger.info('Firebase 초기화 시작');

      // Firebase 코어 초기화
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 저장소 초기화
      quizRepository = FirebaseQuizRepository();
      wordRepository = FirebaseWordRepository();

      // 초기 데이터 설정
      await _seedInitialData();

      _isInitialized = true;
      AppLogger.info('Firebase 초기화 완료');
    } catch (e) {
      AppLogger.error('Firebase 초기화 오류', e);
      rethrow;
    }
  }

  /// 초기 데이터 설정
  Future<void> _seedInitialData() async {
    try {
      AppLogger.info('초기 데이터 설정 시작');

      // 퀴즈 데이터 설정
      await quizRepository.seedInitialQuizzes();

      // 단어 데이터 설정
      await wordRepository.seedInitialWords();

      AppLogger.info('초기 데이터 설정 완료');
    } catch (e) {
      AppLogger.error('초기 데이터 설정 오류', e);
      // 초기 데이터 설정 오류는 앱 실행에 치명적이지 않으므로 넘어감
    }
  }
}

// DefaultFirebaseOptions 클래스 제거 - firebase_options.dart에서 import

/// 의존성 주입을 위한 전역 상태 관리 위젯
class FirebaseProvider extends InheritedWidget {
  final FirebaseInitializer firebase;

  const FirebaseProvider({
    super.key,
    required this.firebase,
    required super.child,
  });

  static FirebaseProvider of(BuildContext context) {
    final FirebaseProvider? result =
        context.dependOnInheritedWidgetOfExactType<FirebaseProvider>();
    assert(result != null, 'FirebaseProvider를 찾을 수 없습니다.');
    return result!;
  }

  @override
  bool updateShouldNotify(FirebaseProvider oldWidget) {
    return false; // 상태가 변경되지 않으므로 항상 false
  }
}

// 전역에서 Firebase 인스턴스에 접근할 수 있는 getter
FirebaseInitializer get globalFirebaseInitializer => FirebaseInitializer();
