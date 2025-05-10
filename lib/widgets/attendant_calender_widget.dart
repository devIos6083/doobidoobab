import 'package:flutter/material.dart';
import 'package:focus_life/models/attendant_model.dart';
import 'package:focus_life/provider/attendence_provider.dart';
import 'package:focus_life/utils/constant.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AttendanceCalendarWidget extends ConsumerWidget {
  const AttendanceCalendarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendance = ref.watch(attendanceProvider);
    final now = DateTime.now();

    // 출석한 날짜를 DateTime으로 변환
    Set<DateTime> attendanceDates = attendance.checkedDates.map((dateStr) {
      return DateTime.parse(dateStr);
    }).toSet();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '출석 캘린더',
            style: GoogleFonts.sora(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          TableCalendar(
            firstDay: DateTime(now.year, now.month - 3, 1),
            lastDay: DateTime(now.year, now.month + 3, 0),
            focusedDay: now,
            calendarFormat: CalendarFormat.month,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: const TextStyle(color: Colors.red),
              holidayTextStyle: const TextStyle(color: Colors.red),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              weekendStyle: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                // 출석한 날짜에 마커 표시
                if (attendanceDates
                    .contains(DateTime(date.year, date.month, date.day))) {
                  return Positioned(
                    bottom: 1,
                    right: 1,
                    left: 1,
                    child: Container(
                      height: 35,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.check,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 16),

          // 출석 통계
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      icon: Icons.calendar_today,
                      title: '총 출석일',
                      value: '${attendance.count}일',
                    ),
                    _buildStatItem(
                      icon: Icons.rocket_launch,
                      title: '출석률',
                      value: '${attendance.attendanceRate.toStringAsFixed(1)}%',
                    ),
                    _buildStatItem(
                      icon: Icons.timer,
                      title: '연속 출석',
                      value: '${attendance.consecutiveDays}일',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 22,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.sora(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.sora(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
