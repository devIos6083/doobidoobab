import 'dart:io';

import 'package:doobi/models/user.dart';
import 'package:doobi/utils/logger.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

/// 사용자 관련 데이터베이스 작업을 처리하는 서비스
///
/// 이 서비스는 사용자 정보의 저장, 조회, 수정 및 출석 관리 기능을 제공합니다.
/// 싱글톤 패턴으로 구현되어 애플리케이션 전체에서 하나의 인스턴스만 사용합니다.
class UserService {
  // 싱글톤 인스턴스
  static final UserService _instance = UserService._internal();

  /// 싱글톤 인스턴스를 반환하는 팩토리 생성자
  factory UserService() => _instance;

  /// 싱글톤 패턴을 위한 private 생성자
  UserService._internal();

  // Firebase 데이터베이스 참조
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Firebase Storage 참조
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 사용자 참조 경로
  final String _userPath = 'users';

  /// 현재 사용자 조회
  ///
  /// Firebase에서 사용자 정보를 가져옵니다.
  /// 사용자가 존재하면 User 객체를, 존재하지 않으면 null을 반환합니다.
  Future<User?> getUser() async {
    try {
      // 첫 번째 사용자 검색 (앱에서는 단일 사용자만 저장)
      final snapshot = await _database.child(_userPath).limitToFirst(1).get();

      if (snapshot.exists && snapshot.children.isNotEmpty) {
        final userSnapshot = snapshot.children.first;
        final userData = Map<String, dynamic>.from(userSnapshot.value as Map);

        // Firebase의 키를 사용자 ID로 설정
        userData['id'] = userSnapshot.key;

        // character_path가 있으면 전체 경로로 변환
        if (userData['character_path'] != null) {
          final fileName = userData['character_path'];
          if (!fileName.startsWith('/') && !fileName.startsWith('http')) {
            // 앱 문서 디렉토리 경로 가져오기
            final appDir = await getApplicationDocumentsDirectory();
            userData['character_path'] = '${appDir.path}/$fileName';
          }
        }

        AppLogger.info('Firebase에서 사용자 찾음: ${userData['name']}');
        return User.fromMap(userData);
      }

      AppLogger.info('Firebase에 사용자 없음');
      return null;
    } catch (e) {
      AppLogger.error('사용자 조회 오류', e);
      return null;
    }
  }

  /// 사용자 데이터 저장 또는 업데이트
  ///
  /// 사용자가 이미 존재하는 경우에는 정보를 업데이트하고,
  /// 존재하지 않는 경우에는 새 사용자 항목을 생성합니다.
  ///
  /// [user] 저장할 사용자 객체
  /// [characterPath] 선택적으로 지정할 캐릭터 이미지 경로
  /// [attendanceDate] 선택적으로 지정할 출석일
  ///
  /// 성공 시 저장된 사용자 객체를, 실패 시 null을 반환합니다.
  /// 학습한 단어 목록 업데이트
  ///
  /// 사용자의 학습한 단어 목록을 Firebase에 업데이트합니다.
  /// [userId] 사용자 ID (String 형식)
  /// [learnedWords] 학습한 단어 목록
  ///
  /// 성공 시 true, 실패 시 false를 반환합니다.
  Future<bool> updateLearnedWords(
    String userId,
    List<String> learnedWords,
  ) async {
    try {
      AppLogger.info(
        '학습한 단어 목록 업데이트: ${learnedWords.length}개, 사용자 ID: $userId',
      );

      // 파라미터 체크
      if (userId.isEmpty) {
        AppLogger.error('업데이트 실패: 사용자 ID가 비어있음');
        return false;
      }

      // 디버깅 로그 추가
      print('Firebase 경로: $_userPath/$userId');
      print('업데이트할 단어 목록: $learnedWords');

      // Firebase에 학습한 단어 목록 업데이트
      await _database.child('$_userPath/$userId').update({
        'learned_words': learnedWords,
      });

      // 업데이트 확인
      final snapshot =
          await _database.child('$_userPath/$userId/learned_words').get();
      if (snapshot.exists) {
        print('업데이트 확인: ${snapshot.value}');
      } else {
        print('업데이트 후 데이터가 없음');
      }

      AppLogger.info('학습한 단어 목록 업데이트 완료');
      return true;
    } catch (e) {
      AppLogger.error('학습한 단어 목록 업데이트 오류', e);
      print('오류 상세: $e');
      return false;
    }
  }

  Future<User?> saveUser(
    User user, {
    String? characterPath,
    DateTime? attendanceDate,
  }) async {
    try {
      // 디버깅 로그 추가
      AppLogger.info(
        '사용자 저장 시작: 이름=${user.name}, 나이=${user.age}, 성별=${user.gender}',
      );

      // 사용자 맵 준비
      var userMap = user.toMap();
      print('사용자 맵 생성: $userMap'); // 디버깅용 로그

      // UserService의 saveUser 함수 내부에서:
      if (characterPath != null) {
        // 전체 경로 대신 파일명만 저장
        final fileName = characterPath.split('/').last;
        userMap['character_path'] = fileName;
      }

      // 출석일 관련 처리
      if (attendanceDate != null) {
        try {
          userMap['last_attendance_date'] = attendanceDate.toIso8601String();
          int consecutiveDays = await _calculateConsecutiveDays(
            user,
            attendanceDate,
          );
          userMap['consecutive_days'] = consecutiveDays;
        } catch (e) {
          AppLogger.error('출석일 저장 오류', e);
          userMap['last_attendance_date'] = DateTime.now().toIso8601String();
          userMap['consecutive_days'] = userMap['consecutive_days'] ?? 1;
        }
      }

      // ID 처리 수정
      String userId = user.id?.toString() ?? '';

      // 이미 사용자가 존재하는지 확인
      final existingUser = await getUser();
      print('기존 사용자 확인: ${existingUser != null ? '있음' : '없음'}'); // 디버깅용 로그

      try {
        if (existingUser != null && user.id != null) {
          // 기존 사용자 업데이트
          userId = existingUser.id.toString();
          print('기존 사용자 업데이트: userId=$userId'); // 디버깅용 로그

          // 참조 경로 직접 확인
          final userRef = _database.child('$_userPath/$userId');
          print('업데이트 참조 경로: ${userRef.path}'); // 디버깅용 로그

          await userRef.update(userMap);
          print('사용자 업데이트 완료'); // 디버깅용 로그
        } else {
          // 로그아웃 후 새 사용자 생성 - 로직 변경
          print('새 사용자 생성 시작'); // 디버깅용 로그

          // 새 사용자 생성을 위한 참조 생성
          final newUserRef = _database.child(_userPath).push();
          userId = newUserRef.key ?? '';
          print('새 사용자 ID 생성: $userId'); // 디버깅용 로그

          if (userId.isEmpty) {
            throw Exception('Firebase에서 새 ID 생성 실패');
          }

          // set 메소드로 데이터 저장
          await newUserRef.set(userMap);
          print('새 사용자 저장 완료: ID=$userId'); // 디버깅용 로그
        }

        // 성공적으로 저장된 사용자 객체 반환
        final savedUser = user.copyWith(id: int.tryParse(userId) ?? 0);
        AppLogger.info('사용자 저장 성공: ${savedUser.toString()}');
        return savedUser;
      } catch (e) {
        AppLogger.error('Firebase 데이터 저장 오류', e);
        print('Firebase 오류 상세: ${e.toString()}'); // 디버깅용 로그
        return null;
      }
    } catch (e) {
      AppLogger.error('사용자 저장 오류', e);
      print('전체 오류 상세: ${e.toString()}'); // 디버깅용 로그
      return null;
    }
  }

  /// 캐릭터 이미지를 Firebase Storage에 저장
  ///
  /// 사용자가 선택한 프로필 이미지를 Firebase Storage에 저장하고
  /// 저장된 파일 URL을 반환합니다.
  Future<String?> saveCharacterImage(File imageFile) async {
    try {
      // 앱 문서 디렉토리 가져오기
      final appDir = await getApplicationDocumentsDirectory();

      // 고유한 파일명 생성
      final fileName = 'character_${DateTime.now().millisecondsSinceEpoch}.png';

      // 저장 경로 생성
      final localPath = '${appDir.path}/$fileName';
      print('로컬 저장 경로: $localPath');

      // 이미지 파일 복사
      final savedImage = await imageFile.copy(localPath);
      print('이미지 저장 완료: ${savedImage.path}');

      // 경로 반환
      return localPath;
    } catch (e) {
      print('이미지 저장 오류: $e');
      return null;
    }
  }

  /// 모든 사용자 데이터 삭제
  ///
  /// Firebase에서 모든 사용자 정보를 삭제합니다.
  /// 성공 시 true를, 실패 시 false를 반환합니다.
  Future<bool> deleteUser() async {
    try {
      // 로그 추가
      AppLogger.info('사용자 삭제 시작');

      final user = await getUser();

      if (user != null && user.id != null) {
        final userRef = _database.child('$_userPath/${user.id}');

        // 참조 경로 로그
        print('삭제할 사용자 참조 경로: ${userRef.path}');

        // 데이터 확인
        final snapshot = await userRef.get();
        if (snapshot.exists) {
          print('삭제할 사용자 데이터 존재함: ${snapshot.value}');
        } else {
          print('경고: 삭제할 사용자 데이터가 이미 존재하지 않음');
        }

        // 삭제 시도
        await userRef.remove();

        // 삭제 확인
        final checkSnapshot = await userRef.get();
        if (!checkSnapshot.exists) {
          AppLogger.info('Firebase에서 사용자 삭제 완료: ID=${user.id}');
          return true;
        } else {
          AppLogger.error('사용자 삭제 실패: 데이터가 여전히 존재함');
          return false;
        }
      } else {
        // 모든 사용자 데이터 삭제 시도 (비상 대책)
        print('특정 사용자 ID가 없어 전체 users 노드 삭제 시도');
        await _database.child(_userPath).remove();
        AppLogger.info('Firebase에서 모든 사용자 데이터 삭제 시도 완료');
        return true;
      }
    } catch (e) {
      AppLogger.error('사용자 삭제 오류', e);
      print('삭제 오류 상세: ${e.toString()}');
      return false;
    }
  }

  /// 사용자 출석 기록
  ///
  /// 연속 출석일 계산을 위해 사용자의 출석을 기록합니다.
  /// 성공 시 업데이트된 사용자 객체를, 실패 시 null을 반환합니다.
  Future<User?> trackAttendance() async {
    try {
      final user = await getUser();
      if (user == null) return null;

      final today = DateTime.now();
      return await saveUser(user, attendanceDate: today);
    } catch (e) {
      AppLogger.error('출석 기록 오류', e);
      return null;
    }
  }

  /// 연속 출석일 계산
  ///
  /// 마지막 출석일과 오늘 날짜를 비교하여 연속 출석일을 계산합니다.
  /// 오류가 발생하거나 데이터가 없는 경우 안전하게 처리합니다.
  ///
  /// [user] 현재 사용자 객체
  /// [today] 현재 출석일
  ///
  /// 계산된 연속 출석일 수를 반환합니다.
  Future<int> _calculateConsecutiveDays(User user, DateTime today) async {
    try {
      // 마지막 출석일이 없는 경우 첫 출석으로 간주
      if (user.consecutiveDays == 0 || user.lastAttendanceDate == null) {
        return 1;
      }

      DateTime lastAttendanceDate;
      try {
        // 문자열 파싱 시도
        lastAttendanceDate = DateTime.parse(user.lastAttendanceDate!);
      } catch (e) {
        AppLogger.error('마지막 출석일 파싱 오류', e);
        // 파싱 실패 시 첫 출석으로 간주
        return 1;
      }

      // 날짜만 비교하기 위해 시간 정보 제거
      final lastDate = DateTime(
        lastAttendanceDate.year,
        lastAttendanceDate.month,
        lastAttendanceDate.day,
      );

      final currentDate = DateTime(today.year, today.month, today.day);

      // 날짜 차이 계산
      final difference = _daysBetween(lastDate, currentDate);

      // 연속 출석 여부 판단
      if (difference == 1) {
        // 어제 출석함 - 연속 출석일 증가
        return user.consecutiveDays + 1;
      } else if (difference == 0) {
        // 오늘 이미 출석함 - 현재 값 유지
        return user.consecutiveDays;
      } else {
        // 연속 출석 끊김 - 첫 출석으로 초기화
        return 1;
      }
    } catch (e) {
      AppLogger.error('연속 출석일 계산 오류', e);
      return 1; // 오류 발생 시 기본값 반환
    }
  }

  /// 두 날짜 사이의 일수 계산
  ///
  /// 시간 정보를 무시하고 순수하게 날짜 차이만 계산합니다.
  ///
  /// [from] 시작 날짜
  /// [to] 종료 날짜
  ///
  /// 두 날짜 사이의 일수를 반환합니다.
  int _daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }
}
