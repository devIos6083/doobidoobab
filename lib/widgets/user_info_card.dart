// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:focus_life/utils/constant.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_life/models/user_model.dart';
import 'package:focus_life/widgets/info_item_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_life/provider/user_provider.dart';

class UserInfoCard extends ConsumerWidget {
  const UserInfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userModel = ref.watch(userProvider); // 🔹 사용자 정보 가져오기

    // 사용자가 선택한 항목 가져오기
    final String jobType = (userModel.jobTypeIndex != null &&
            userModel.jobTypeIndex! < UserInfoConstants.jobTypes.length)
        ? UserInfoConstants.jobTypes[userModel.jobTypeIndex!]
        : '정보 없음';

    final String employmentType = (userModel.employmentTypeIndex != null &&
            userModel.employmentTypeIndex! <
                UserInfoConstants.employmentTypes.length)
        ? UserInfoConstants.employmentTypes[userModel.employmentTypeIndex!]
        : '정보 없음';

    final String issueType = (userModel.issueTypeIndex != null &&
            userModel.issueTypeIndex! < UserInfoConstants.issueTypes.length)
        ? UserInfoConstants.issueTypes[userModel.issueTypeIndex!]
        : '정보 없음';

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
        children: [
          // 🔹 사용자 이미지 (원형 컨테이너)
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                'img/work.png', // 🔹 사용자 이미지 추가
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 🔹 사용자 이름 (고정: 강홍규님)
          Text(
            "강홍규님",
            style: GoogleFonts.sora(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 20),

          // 🔹 사용자 정보 그리드
          Row(
            children: [
              Expanded(
                child: InfoItemWidget(
                  title: '직종',
                  value: jobType,
                  icon: Icons.work,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InfoItemWidget(
                  title: '고용 형태',
                  value: employmentType,
                  icon: Icons.business_center,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: InfoItemWidget(
                  title: '관심 문제',
                  value: issueType,
                  icon: Icons.help_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
