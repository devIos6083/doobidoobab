// ignore_for_file: deprecated_member_use

import 'package:doobi/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 연속 출석 일수를 시각적으로 표시하는 위젯
///
/// 불꽃 아이콘과 함께 연속 출석일을 시각화합니다.
class StreakIndicator extends StatelessWidget {
  /// 연속 출석 일수
  final int days;

  /// 한 번에 표시할 최대 일수
  final int maxDisplay;

  /// 완료된 날의 색상
  final Color completedColor;

  /// 미완료된 날의 색상
  final Color incompleteColor;

  const StreakIndicator({
    super.key,
    required this.days,
    this.maxDisplay = 7,
    this.completedColor = AppColors.accent,
    this.incompleteColor = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 스트릭 바
        Container(
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(maxDisplay, (index) {
              // 오늘까지 포함하여 계산
              final bool isCompleted = index < days;
              return _buildStreakDot(isCompleted, index);
            }),
          ),
        ),

        const SizedBox(height: 8),

        // 스트릭 통계 텍스트
        Text(
          _getStreakMessage(),
          style: GoogleFonts.quicksand(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 스트릭 점 하나를 생성하는 메소드
  Widget _buildStreakDot(bool isCompleted, int index) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 불꽃 아이콘
        Icon(
          Icons.local_fire_department,
          color:
              isCompleted
                  ? _getStreakColor(index)
                  : incompleteColor.withOpacity(0.3),
          size: 28,
        ),

        // 일수 텍스트
        Text(
          '${index + 1}일',
          style: GoogleFonts.quicksand(
            fontSize: 12,
            fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
            color:
                isCompleted
                    ? _getStreakColor(index)
                    : incompleteColor.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  /// 스트릭 메시지 생성 메소드
  String _getStreakMessage() {
    if (days <= 0) {
      return '첫 접속을 환영합니다!';
    } else if (days == 1) {
      return '오늘 처음 접속하셨네요! 내일도 만나요!';
    } else if (days < 3) {
      return '$days일 연속 접속 중입니다. 좋은 흐름이에요!';
    } else if (days < 7) {
      return '대단해요! $days일 연속으로 학습하고 계십니다!';
    } else if (days < 14) {
      return '놀라워요! $days일 연속 학습 중! 습관으로 만들어가고 있어요!';
    } else {
      return '믿을 수 없어요! $days일 연속 접속! 당신은 진정한 학습왕입니다!';
    }
  }

  /// 스트릭 일수에 따른 색상 변화 (색상 그라데이션 효과)
  Color _getStreakColor(int index) {
    // 일수가 증가할수록 더 강한 색상으로 변경
    if (index < 3) {
      return completedColor.withOpacity(0.7 + (index * 0.1));
    } else if (index < 5) {
      // 주황-빨강 계열로 변화
      return Color.lerp(completedColor, Colors.deepOrange, (index - 2) / 3)!;
    } else {
      // 빨강-보라 계열로 변화 (높은 스트릭)
      return Color.lerp(Colors.deepOrange, Colors.purple, (index - 4) / 3)!;
    }
  }
}
