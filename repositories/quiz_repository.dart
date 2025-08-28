import 'package:doobi/models/quiz_model.dart';
import 'package:doobi/utils/logger.dart';

import 'package:firebase_database/firebase_database.dart';

/// Firebase 기반 퀴즈 저장소 인터페이스
abstract class QuizRepository {
  Future<List<QuizModel>> getQuizzes(String difficulty, int count);
  Future<bool> saveQuiz(QuizModel quiz);
}

/// Firebase 기반 퀴즈 저장소 구현체
class FirebaseQuizRepository implements QuizRepository {
  // Firebase 데이터베이스 참조
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // 퀴즈 참조 경로
  final String _quizPath = 'quizzes';

  @override
  Future<List<QuizModel>> getQuizzes(String difficulty, int count) async {
    try {
      AppLogger.info('Firebase에서 퀴즈 가져오기: 난이도=$difficulty, 개수=$count');

      // 지정된 난이도와 일치하는 쿼리
      final snapshot =
          await _database
              .child(_quizPath)
              .orderByChild('difficulty')
              .equalTo(difficulty)
              .get();

      if (!snapshot.exists) {
        AppLogger.info('지정된 난이도의 퀴즈가 없습니다: $difficulty');
        return [];
      }

      // 퀴즈 목록 구성
      List<QuizModel> quizzes = [];

      // 모든 퀴즈 데이터 변환
      for (var child in snapshot.children) {
        final quizData = Map<String, dynamic>.from(child.value as Map);

        // options 배열 변환
        List<String> options = [];
        if (quizData['options'] is List) {
          options = List<String>.from(quizData['options']);
        } else if (quizData['options'] is Map) {
          // Firebase는 배열을 맵으로 변환할 수 있음
          final optionsMap = Map<String, dynamic>.from(
            quizData['options'] as Map,
          );
          options = optionsMap.values.map((v) => v.toString()).toList();
        }

        // QuizModel 생성
        final quiz = QuizModel(
          question: quizData['question'] as String,
          options: options,
          correctAnswer: quizData['correctAnswer'] as String,
          difficulty: quizData['difficulty'] as String,
        );

        quizzes.add(quiz);
      }

      // 요청 개수만큼 랜덤 선택 (또는 가능한 최대)
      quizzes.shuffle();
      final resultCount = count < quizzes.length ? count : quizzes.length;

      AppLogger.info('퀴즈 ${quizzes.length}개 중 $resultCount개 반환');
      return quizzes.take(resultCount).toList();
    } catch (e) {
      AppLogger.error('퀴즈 가져오기 오류', e);
      return [];
    }
  }

  @override
  Future<bool> saveQuiz(QuizModel quiz) async {
    try {
      // 퀴즈 데이터 변환
      final quizData = {
        'question': quiz.question,
        'options': quiz.options,
        'correctAnswer': quiz.correctAnswer,
        'difficulty': quiz.difficulty,
      };

      // Firebase에 저장
      await _database.child(_quizPath).push().set(quizData);

      AppLogger.info('퀴즈 저장 완료: ${quiz.question}');
      return true;
    } catch (e) {
      AppLogger.error('퀴즈 저장 오류', e);
      return false;
    }
  }

  /// 초기 퀴즈 데이터 설정 (앱 초기화 시 호출)
  Future<void> seedInitialQuizzes() async {
    try {
      // 이미 퀴즈가 있는지 확인
      final snapshot = await _database.child(_quizPath).get();

      if (snapshot.exists) {
        AppLogger.info('기존 퀴즈 데이터가 존재합니다. 초기 데이터 생성을 건너뜁니다.');
        return;
      }

      AppLogger.info('초기 퀴즈 데이터 생성 시작');

      // 샘플 퀴즈 데이터 (실제 앱에서는 더 많은 데이터 추가)
      final sampleQuizzes = [
        QuizModel(
          question: '사과는 영어로 무엇인가요?',
          options: ['Apple', 'Banana', 'Orange', 'Grape'],
          correctAnswer: 'Apple',
          difficulty: '쉬움',
        ),
        QuizModel(
          question: '바나나는 영어로 무엇인가요?',
          options: ['Apple', 'Banana', 'Orange', 'Grape'],
          correctAnswer: 'Banana',
          difficulty: '쉬움',
        ),
        QuizModel(
          question: '오렌지는 영어로 무엇인가요?',
          options: ['Apple', 'Banana', 'Orange', 'Grape'],
          correctAnswer: 'Orange',
          difficulty: '쉬움',
        ),
        QuizModel(
          question: '포도는 영어로 무엇인가요?',
          options: ['Apple', 'Banana', 'Orange', 'Grape'],
          correctAnswer: 'Grape',
          difficulty: '쉬움',
        ),
        QuizModel(
          question: '딸기는 영어로 무엇인가요?',
          options: ['Strawberry', 'Blueberry', 'Cherry', 'Raspberry'],
          correctAnswer: 'Strawberry',
          difficulty: '보통',
        ),
        QuizModel(
          question: '블루베리는 영어로 무엇인가요?',
          options: ['Strawberry', 'Blueberry', 'Cherry', 'Raspberry'],
          correctAnswer: 'Blueberry',
          difficulty: '보통',
        ),
        QuizModel(
          question: '체리는 영어로 무엇인가요?',
          options: ['Strawberry', 'Blueberry', 'Cherry', 'Raspberry'],
          correctAnswer: 'Cherry',
          difficulty: '보통',
        ),
        QuizModel(
          question: '라즈베리는 영어로 무엇인가요?',
          options: ['Strawberry', 'Blueberry', 'Cherry', 'Raspberry'],
          correctAnswer: 'Raspberry',
          difficulty: '보통',
        ),
        QuizModel(
          question: '파인애플은 영어로 무엇인가요?',
          options: ['Pineapple', 'Watermelon', 'Melon', 'Kiwi'],
          correctAnswer: 'Pineapple',
          difficulty: '어려움',
        ),
        QuizModel(
          question: '수박은 영어로 무엇인가요?',
          options: ['Pineapple', 'Watermelon', 'Melon', 'Kiwi'],
          correctAnswer: 'Watermelon',
          difficulty: '어려움',
        ),
        QuizModel(
          question: '멜론은 영어로 무엇인가요?',
          options: ['Pineapple', 'Watermelon', 'Melon', 'Kiwi'],
          correctAnswer: 'Melon',
          difficulty: '어려움',
        ),
        QuizModel(
          question: '키위는 영어로 무엇인가요?',
          options: ['Pineapple', 'Watermelon', 'Melon', 'Kiwi'],
          correctAnswer: 'Kiwi',
          difficulty: '어려움',
        ),
      ];

      // 모든 샘플 퀴즈 저장
      for (var quiz in sampleQuizzes) {
        await saveQuiz(quiz);
      }

      AppLogger.info('초기 퀴즈 데이터 생성 완료: ${sampleQuizzes.length}개');
    } catch (e) {
      AppLogger.error('초기 퀴즈 데이터 생성 오류', e);
    }
  }
}
