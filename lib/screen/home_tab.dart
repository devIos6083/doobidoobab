import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_life/models/attendant_model.dart';
import 'package:focus_life/models/lawtip_model.dart';
import 'package:focus_life/provider/attendence_provider.dart';
import 'package:focus_life/provider/lawtip_provider.dart';
import 'package:focus_life/provider/navigation_provider.dart';
import 'package:focus_life/provider/user_provider.dart';
import 'package:focus_life/utils/constant.dart';
import 'package:focus_life/widgets/attence_widget.dart';
import 'package:focus_life/widgets/attendant_calender_widget.dart'; // New import
import 'package:focus_life/widgets/guide_banner.dart';
import 'package:focus_life/widgets/labol_guide.dart';
import 'package:focus_life/widgets/salary_cacluater.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_life/widgets/user_info_card.dart';
import 'package:focus_life/widgets/law_tip_widget.dart';
import 'package:focus_life/widgets/quick_access_button.dart';

class HomeTabRiverpod extends ConsumerStatefulWidget {
  const HomeTabRiverpod({super.key});

  @override
  ConsumerState<HomeTabRiverpod> createState() => _HomeTabRiverpodState();
}

class _HomeTabRiverpodState extends ConsumerState<HomeTabRiverpod>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkAnimationController;
  bool _showCalendar = false; // 캘린더 표시 여부

  @override
  void initState() {
    super.initState();
    _checkAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _checkAnimationController.dispose();
    super.dispose();
  }

  void _checkAttendance() async {
    // SQLite DB를 사용하여 출석 체크
    final success =
        await ref.read(attendanceProvider.notifier).checkAttendance();

    if (success) {
      // Animate the check mark
      _checkAnimationController.forward(from: 0);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '오늘 하루도 화이팅하시기 바랍니다!',
            style: GoogleFonts.sora(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the user provider to get user data
    final user = ref.watch(userProvider);
    // Watch the attendance provider to get attendance state
    final AttendanceModel attendance = ref.watch(attendanceProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사용자 정보 카드
            UserInfoCard(),

            const SizedBox(height: 30),

            // 출석 체크 섹션
            AttendanceWidget(
              attendance: attendance,
              onCheckAttendance: _checkAttendance,
              animationController: _checkAnimationController,
            ),

            const SizedBox(height: 16),

            // 캘린더 표시 토글 버튼
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showCalendar = !_showCalendar;
                  });
                },
                icon: Icon(
                  _showCalendar
                      ? Icons.calendar_view_month
                      : Icons.calendar_month_outlined,
                  color: AppColors.primary,
                ),
                label: Text(
                  _showCalendar ? '캘린더 숨기기' : '출석 캘린더 보기',
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            // 캘린더 위젯 (토글 상태에 따라 표시)
            if (_showCalendar) ...[
              const SizedBox(height: 20),
              AttendanceCalendarWidget(),
            ],

            const SizedBox(height: 30),

            // 법률 정보 팁 섹션

// With this implementation:
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '오늘의 법률 정보',
                      style: GoogleFonts.sora(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, _) {
                    final dailyTip = ref.watch(dailyLawTipProvider);
                    return InteractiveLawTipWidget(
                      tipId: dailyTip.id,
                      onTapDetail: () {
                        // Any additional actions on tip detail view
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),

// 급여 계산기 섹션 - 사용자 정의 헤더와 함께
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '급여 계산기',
                  style: GoogleFonts.sora(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                // showTitle을 false로 설정하여 중복 제목 방지
                SalaryCalculatorWidget(showTitle: true),
              ],
            ),

            const SizedBox(height: 30),
            // 빠른 액세스 버튼 섹션
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '빠른 액세스',
                  style: GoogleFonts.sora(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: QuickAccessButton(
                        title: '법률 정보',
                        icon: Icons.book,
                        color: AppColors.primary,
                        onTap: () {
                          // 법률 정보 화면으로 이동
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: QuickAccessButton(
                        title: '상담하기',
                        icon: Icons.chat_bubble,
                        color: AppColors.accent,
                        onTap: () {
                          // Use the navigation provider to navigate to the chat tab
                          ref.read(navigationProvider.notifier).setTab(1);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: QuickAccessButton(
                        title: '문서 작성',
                        icon: Icons.description,
                        color: AppColors.error,
                        onTap: () {
                          // 문서 작성 화면으로 이동
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: QuickAccessButton(
                        title: '도움 요청',
                        icon: Icons.help,
                        color: AppColors.warning,
                        onTap: () {
                          // 도움 요청 화면으로 이동
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 알림 섹션
            GuideBannerWidget(
              title: '근로 계약서 작성 방법',
              description: '근로 계약서 작성 시 꼭 확인해야 할 사항들을 알려드립니다.',
              icon: Icons.description,
              onTapGuide: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => LaborContractGuideScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
