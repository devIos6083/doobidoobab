import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_life/models/attendant_model.dart';
import 'package:focus_life/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_life/models/attendant_model.dart';

// 출석 상태를 관리하는 StateNotifier
class AttendanceNotifier extends StateNotifier<AttendanceModel> {
  final AttendanceDatabase _database = AttendanceDatabase();

  AttendanceNotifier()
      : super(AttendanceModel(
            count: 0, isTodayChecked: false, checkedDates: [])) {
    _loadAttendanceData();
  }

  // 저장된 출석 정보 불러오기
  Future<void> _loadAttendanceData() async {
    // 출석 총 개수 가져오기
    final count = await _database.getTotalAttendanceCount();

    // 오늘 날짜와 출석 체크 여부 확인
    final today = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD 형식
    final isTodayChecked = await _database.isDateChecked(today);

    // 모든 출석 기록의 날짜 목록 가져오기
    final records = await _database.getAllAttendanceRecords();
    final checkedDates =
        records.map((record) => record['date'] as String).toList();

    state = AttendanceModel(
      count: count,
      isTodayChecked: isTodayChecked,
      checkedDates: checkedDates,
    );
  }

  // 출석 체크 실행
  Future<bool> checkAttendance() async {
    // 오늘 이미 체크했으면 중복 방지
    if (state.isTodayChecked) {
      return false;
    }

    // 오늘 날짜 가져오기
    final today = DateTime.now().toString().split(' ')[0]; // YYYY-MM-DD 형식

    // SQLite DB에 출석 기록 저장
    await _database.insertAttendanceRecord(today);

    // 상태 업데이트
    final newCount = state.count + 1;
    final newCheckedDates = [...state.checkedDates, today];

    state = AttendanceModel(
      count: newCount,
      isTodayChecked: true,
      checkedDates: newCheckedDates,
    );

    return true;
  }

  // 출석 횟수 직접 설정 (관리자용 또는 테스트용)
  Future<void> setAttendanceCount(int count) async {
    // SQLite DB 초기화
    await _database.clearAllAttendanceRecords();

    // 상태 업데이트
    state = AttendanceModel(
      count: count,
      isTodayChecked: state.isTodayChecked,
      checkedDates: state.checkedDates,
    );

    // 출석 기록이 있다면 DB에 다시 추가
    if (state.isTodayChecked) {
      final today = DateTime.now().toString().split(' ')[0];
      await _database.insertAttendanceRecord(today);
    }
  }

  // 특정 기간의 출석 기록 가져오기 (예: 이번 달)
  Future<List<String>> getMonthlyAttendance() async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    final startDate = firstDayOfMonth.toString().split(' ')[0];
    final endDate = lastDayOfMonth.toString().split(' ')[0];

    final records =
        await _database.getAttendanceRecordsByDateRange(startDate, endDate);
    return records.map((record) => record['date'] as String).toList();
  }
}

// 출석 Provider 정의
final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceModel>((ref) {
  return AttendanceNotifier();
});

// AttendanceModel 확장 - 필요한 추가 기능
extension AttendanceModelExtension on AttendanceModel {
  // 현재 출석 상태에 따른 텍스트 반환
  String get statusText =>
      isTodayChecked ? '오늘 출석을 완료했습니다!' : '오늘의 출석체크를 해주세요.';

  // 출석률 계산 (30일 기준)
  double get attendanceRate => (count / 30) * 100;

  // 연속 출석 일수 계산
  int get consecutiveDays {
    if (checkedDates.isEmpty) return 0;

    int consecutiveCount = 1;
    final sortedDates = [...checkedDates]..sort();

    for (int i = sortedDates.length - 1; i > 0; i--) {
      final current = DateTime.parse(sortedDates[i]);
      final previous = DateTime.parse(sortedDates[i - 1]);

      // 날짜 차이가 1일인지 확인
      final difference = current.difference(previous).inDays;
      if (difference == 1) {
        consecutiveCount++;
      } else {
        break;
      }
    }

    return consecutiveCount;
  }
}
