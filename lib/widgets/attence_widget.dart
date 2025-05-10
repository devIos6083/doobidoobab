import 'package:flutter/material.dart';
import 'package:focus_life/models/attendant_model.dart';
import 'package:focus_life/utils/constant.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class AttendanceWidget extends StatefulWidget {
  final AttendanceModel attendance;
  final Function() onCheckAttendance;
  final AnimationController animationController;

  const AttendanceWidget({
    super.key,
    required this.attendance,
    required this.onCheckAttendance,
    required this.animationController,
  });

  @override
  State<AttendanceWidget> createState() => _AttendanceWidgetState();
}

class _AttendanceWidgetState extends State<AttendanceWidget> {
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();
    _checkAnimation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: widget.animationController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            '출석 체크',
            style: GoogleFonts.sora(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            '30일 출석 도전 중',
            style: GoogleFonts.sora(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 20),

          // 출석 진행 상황
          Column(
            children: [
              LinearProgressIndicator(
                value: widget.attendance.count / 30,
                backgroundColor: const Color(0xFFE6E7F2),
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 출석 카운트
                  Text(
                    '${widget.attendance.count} / 30',
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  // 출석 체크 버튼
                  GestureDetector(
                    onTap: widget.attendance.isTodayChecked
                        ? null
                        : widget.onCheckAttendance,
                    child: AnimatedBuilder(
                      animation: _checkAnimation,
                      builder: (context, child) {
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.attendance.isTodayChecked
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                          child: Center(
                            child: widget.attendance.isTodayChecked
                                ? Transform.rotate(
                                    angle: _checkAnimation.value * math.pi * 2,
                                    child: Transform.scale(
                                      scale:
                                          1.0 + (_checkAnimation.value * 0.3),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
