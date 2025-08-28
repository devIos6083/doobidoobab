// ignore_for_file: deprecated_member_use

import 'package:doobi/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// 출석 달력 위젯
///
/// 최근 7일간의 출석 현황을 미니 달력 형태로 표시합니다.
class AttendanceCalendar extends StatelessWidget {
  /// 마지막 출석일
  final DateTime lastAttendanceDate;

  /// 연속 출석일
  final int consecutiveDays;

  /// 표시할 날짜 수
  final int daysToShow;

  const AttendanceCalendar({
    super.key,
    required this.lastAttendanceDate,
    required this.consecutiveDays,
    this.daysToShow = 7,
  });

  @override
  Widget build(BuildContext context) {
    try {
      // 오늘 날짜
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);

      // 표시할 날짜 생성 (오늘 포함 최근 7일)
      final List<DateTime> dates = List.generate(daysToShow, (index) {
        return today.subtract(Duration(days: daysToShow - 1 - index));
      });

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 달력 날짜 표시
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:
                  dates.map((date) => _buildDayColumn(date, today)).toList(),
            ),
          ),
        ],
      );
    } catch (e) {
      // 오류 발생 시 빈 컨테이너 반환
      debugPrint('출석 달력 생성 오류: $e');
      return Container(
        height: 70,
        alignment: Alignment.center,
        child: Text(
          '달력을 불러올 수 없습니다.',
          style: GoogleFonts.quicksand(color: Colors.grey, fontSize: 14),
        ),
      );
    }
  }

  /// 날짜 열 생성
  Widget _buildDayColumn(DateTime date, DateTime today) {
    try {
      // 요일 형식 지정
      final dayFormatter = DateFormat('E', 'ko_KR');
      final String dayName = dayFormatter.format(date);

      // 출석 상태 확인
      final bool isToday = date.isAtSameMomentAs(today);
      final bool hasAttended = _checkAttendance(date);

      // 색상 설정
      final Color textColor =
          isToday
              ? AppColors.accent
              : hasAttended
              ? AppColors.textPrimary
              : AppColors.textSecondary.withOpacity(0.5);

      final Color bgColor =
          isToday ? AppColors.accent.withOpacity(0.1) : Colors.transparent;

      return Container(
        width: 40,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 요일 표시
            Text(
              dayName,
              style: GoogleFonts.quicksand(
                fontSize: 12,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            // 날짜 표시
            Text(
              '${date.day}',
              style: GoogleFonts.quicksand(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            // 출석 여부 표시
            _buildAttendanceIndicator(hasAttended, isToday),
          ],
        ),
      );
    } catch (e) {
      // 오류 발생 시 빈 컨테이너 반환
      debugPrint('날짜 열 생성 오류: $e');
      return Container(width: 40);
    }
  }

  /// 출석 표시기 생성
  Widget _buildAttendanceIndicator(bool hasAttended, bool isToday) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            hasAttended
                ? isToday
                    ? AppColors.accent
                    : AppColors.primary
                : Colors.transparent,
        border: Border.all(
          color:
              hasAttended ? Colors.transparent : Colors.grey.withOpacity(0.3),
        ),
      ),
    );
  }

  /// 출석 여부 확인 (안전하게 처리)
  bool _checkAttendance(DateTime date) {
    try {
      // 오늘 이후의 날짜는 출석하지 않은 것으로 처리
      final DateTime now = DateTime.now();
      final DateTime today = DateTime(now.year, now.month, now.day);
      if (date.isAfter(today)) {
        return false;
      }

      // 마지막 출석일 기준으로 연속 출석일 확인
      final DateTime lastDate = DateTime(
        lastAttendanceDate.year,
        lastAttendanceDate.month,
        lastAttendanceDate.day,
      );

      // 마지막 출석일부터 거꾸로 연속 출석일 계산
      for (int i = 0; i < consecutiveDays; i++) {
        final DateTime checkDate = lastDate.subtract(Duration(days: i));
        if (date.year == checkDate.year &&
            date.month == checkDate.month &&
            date.day == checkDate.day) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('출석 확인 오류: $e');
      return false;
    }
  }
}
