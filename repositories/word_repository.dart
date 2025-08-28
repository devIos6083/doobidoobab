import 'package:doobi/models/words.dart';
import 'package:doobi/utils/logger.dart';
import 'package:firebase_database/firebase_database.dart';

/// Firebase 기반 단어 저장소 인터페이스
abstract class WordRepository {
  /// 난이도별로 단어 가져오기
  Future<List<Word>> getWordsByDifficulty(String difficulty);

  /// 카테고리별로 단어 가져오기
  Future<List<Word>> getWordsByCategory(String category);

  /// 오늘의 학습 단어 가져오기
  Future<List<Word>> getDailyWords(int count);

  /// 단어 학습 상태 업데이트
  Future<bool> markWordAsLearned(String word);

  /// 학습한 단어 목록 가져오기
  Future<List<String>> getLearnedWords();
}

/// Firebase 기반 단어 저장소 구현
class FirebaseWordRepository implements WordRepository {
  // Firebase 데이터베이스 참조
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // 경로 상수
  final String _wordsPath = 'words';
  final String _learnedWordsPath = 'learned_words';

  // 기본 사용자 ID (실제 인증 시스템 사용 시 변경 필요)
  final String _defaultUserId = 'default_user';

  /// 특정 난이도의 단어를 미리 로드
  ///
  /// 게임 성능 향상을 위해 특정 난이도의 단어를 미리 메모리에 로드합니다.
  Future<void> preloadWordsByDifficulty(String difficulty) async {
    try {
      AppLogger.info('난이도 $difficulty 단어 미리 로드 중');

      // 단어 데이터 로드 확인
      await ensureWordsLoaded();

      // 필요한 난이도의 단어 미리 가져오기
      final words = await getWordsByDifficulty(difficulty);

      AppLogger.info('난이도 $difficulty 단어 ${words.length}개 미리 로드 완료');
      return;
    } catch (e) {
      AppLogger.error('단어 미리 로드 오류', e);
      // 오류가 발생해도 게임은 계속 진행 가능하도록 예외를 다시 던지지 않음
    }
  }

  /// 단어 데이터가 로드되었는지 확인하고 필요시 로드
  Future<void> ensureWordsLoaded() async {
    try {
      AppLogger.info('단어 데이터 로드 상태 확인 중');

      // Firebase에 단어 데이터가 있는지 확인
      final snapshot = await _database.child(_wordsPath).get();

      if (!snapshot.exists || snapshot.children.isEmpty) {
        AppLogger.info('단어 데이터가 없습니다. 초기 데이터를 로드합니다.');
        await seedInitialWords();
      } else {
        AppLogger.info('단어 데이터가 이미 로드되어 있습니다. (${snapshot.children.length}개)');
      }

      return;
    } catch (e) {
      AppLogger.error('단어 데이터 로드 확인 중 오류 발생', e);

      // 오류 발생 시 초기 데이터 설정 시도
      await seedInitialWords();
    }
  }

  /// 초기 단어 데이터 설정
  Future<void> seedInitialWords() async {
    try {
      // 이미 단어가 있는지 확인
      final snapshot = await _database.child(_wordsPath).get();

      if (snapshot.exists) {
        AppLogger.info('기존 단어 데이터가 존재합니다. 초기 데이터 생성을 건너뜁니다.');
        return;
      }

      AppLogger.info('초기 단어 데이터 생성 시작 (${allWords.length}개)');

      // 단어 데이터 추가
      for (var word in allWords) {
        // Firebase에 저장할 키 생성 (영어 단어를 키로 사용)
        final wordKey = word.word.toLowerCase().trim();

        // 데이터 변환 및 저장
        await _database.child('$_wordsPath/$wordKey').set(word.toMap());
      }

      AppLogger.info('초기 단어 데이터 생성 완료: ${allWords.length}개');
    } catch (e) {
      AppLogger.error('초기 단어 데이터 생성 오류', e);
      rethrow;
    }
  }

  @override
  Future<List<Word>> getWordsByDifficulty(String difficulty) async {
    try {
      AppLogger.info('난이도별 단어 가져오기: $difficulty');

      // 모든 단어 가져오기
      final snapshot = await _database.child(_wordsPath).get();

      if (!snapshot.exists) {
        return [];
      }

      List<Word> filteredWords = [];

      // 난이도에 따라 필터링
      for (var child in snapshot.children) {
        final wordData = Map<String, dynamic>.from(child.value as Map);
        final word = Word.fromMap(wordData);

        // 난이도 필터링 로직
        if (difficulty == '어려움' ||
            difficulty == word.difficulty ||
            (difficulty == '보통' && word.difficulty == '쉬움')) {
          filteredWords.add(word);
        }
      }

      AppLogger.info('$difficulty 난이도 단어 ${filteredWords.length}개 가져옴');
      return filteredWords;
    } catch (e) {
      AppLogger.error('난이도별 단어 가져오기 오류', e);

      // 오류 발생 시 로컬 데이터에서 필터링 (백업 방법)
      return filterWordsByDifficulty(difficulty);
    }
  }

  @override
  Future<List<Word>> getWordsByCategory(String category) async {
    try {
      AppLogger.info('카테고리별 단어 가져오기: $category');

      // 카테고리로 필터링된 쿼리 실행
      final snapshot =
          await _database
              .child(_wordsPath)
              .orderByChild('category')
              .equalTo(category)
              .get();

      if (!snapshot.exists) {
        return [];
      }

      List<Word> categoryWords = [];

      // 데이터 변환
      for (var child in snapshot.children) {
        final wordData = Map<String, dynamic>.from(child.value as Map);
        categoryWords.add(Word.fromMap(wordData));
      }

      AppLogger.info('$category 카테고리 단어 ${categoryWords.length}개 가져옴');
      return categoryWords;
    } catch (e) {
      AppLogger.error('카테고리별 단어 가져오기 오류', e);

      // 오류 발생 시 로컬 데이터에서 필터링 (백업 방법)
      return allWords.where((word) => word.category == category).toList();
    }
  }

  @override
  Future<List<Word>> getDailyWords(int count) async {
    try {
      AppLogger.info('오늘의 단어 가져오기: $count개');

      // 학습한 단어 목록 가져오기
      final learnedWords = await getLearnedWords();

      // 모든 단어 가져오기
      final snapshot = await _database.child(_wordsPath).get();

      if (!snapshot.exists) {
        return [];
      }

      List<Word> availableWords = [];

      // 아직 학습하지 않은 단어만 필터링
      for (var child in snapshot.children) {
        final wordKey = child.key as String;

        if (!learnedWords.contains(wordKey)) {
          final wordData = Map<String, dynamic>.from(child.value as Map);
          availableWords.add(Word.fromMap(wordData));
        }
      }

      // 랜덤으로 섞기
      availableWords.shuffle();

      // 요청한 개수만큼 반환 (또는 가능한 최대)
      int resultCount =
          count < availableWords.length ? count : availableWords.length;

      if (availableWords.isEmpty) {
        // 모든 단어를 학습했다면 전체 단어에서 랜덤으로 선택
        final allWordsList = allWords.toList()..shuffle();
        resultCount = count < allWordsList.length ? count : allWordsList.length;

        AppLogger.info('모든 단어를 학습했습니다. 전체 단어에서 랜덤으로 선택합니다.');
        return allWordsList.take(resultCount).toList();
      }

      final result = availableWords.take(resultCount).toList();
      AppLogger.info('오늘의 단어 ${result.length}개 가져옴');
      return result;
    } catch (e) {
      AppLogger.error('오늘의 단어 가져오기 오류', e);

      // 오류 발생 시 로컬 데이터에서 랜덤 선택 (백업 방법)
      final shuffledWords = allWords.toList()..shuffle();
      final resultCount =
          count < shuffledWords.length ? count : shuffledWords.length;
      return shuffledWords.take(resultCount).toList();
    }
  }

  @override
  Future<bool> markWordAsLearned(String word) async {
    try {
      AppLogger.info('단어 학습 완료 표시: $word');

      // 단어 키 정규화
      final wordKey = word.toLowerCase().trim();

      // 학습 완료 정보 저장
      await _database.child('$_learnedWordsPath/$_defaultUserId/$wordKey').set({
        'timestamp': ServerValue.timestamp,
        'word': wordKey,
      });

      AppLogger.info('단어 학습 완료 표시 성공: $word');
      return true;
    } catch (e) {
      AppLogger.error('단어 학습 완료 표시 오류', e);
      return false;
    }
  }

  @override
  Future<List<String>> getLearnedWords() async {
    try {
      // 학습 완료된 단어 목록 가져오기
      final snapshot =
          await _database.child('$_learnedWordsPath/$_defaultUserId').get();

      if (!snapshot.exists) {
        return [];
      }

      List<String> learnedWords = [];

      // 학습한 단어 키만 추출
      for (var child in snapshot.children) {
        learnedWords.add(child.key as String);
      }

      return learnedWords;
    } catch (e) {
      AppLogger.error('학습한 단어 목록 가져오기 오류', e);
      return [];
    }
  }

  /// 현재 사용자의 학습 통계 가져오기
  Future<Map<String, dynamic>> getLearningStatistics() async {
    try {
      // 학습한 단어 목록
      final learnedWords = await getLearnedWords();

      // 카테고리별 학습 통계
      Map<String, int> categoryStats = {};

      // 학습한 단어에 대한 상세 정보 가져오기
      for (var wordKey in learnedWords) {
        final snapshot = await _database.child('$_wordsPath/$wordKey').get();

        if (snapshot.exists) {
          final wordData = Map<String, dynamic>.from(snapshot.value as Map);
          final word = Word.fromMap(wordData);

          // 카테고리 통계 업데이트
          categoryStats[word.category] =
              (categoryStats[word.category] ?? 0) + 1;
        }
      }

      // 결과 통계 생성
      return {
        'totalLearned': learnedWords.length,
        'totalWords': allWords.length,
        'progress': learnedWords.length / allWords.length,
        'categoryStats': categoryStats,
      };
    } catch (e) {
      AppLogger.error('학습 통계 가져오기 오류', e);
      return {
        'totalLearned': 0,
        'totalWords': allWords.length,
        'progress': 0.0,
        'categoryStats': {},
      };
    }
  }
}
