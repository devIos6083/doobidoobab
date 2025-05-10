// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:focus_life/utils/constant.dart';
import 'package:google_fonts/google_fonts.dart';

class LaborContractGuideScreen extends StatelessWidget {
  const LaborContractGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '근로계약서 작성 가이드',
          style: GoogleFonts.sora(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 상단 배너 이미지
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '근로계약서 작성 방법',
                    style: GoogleFonts.sora(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '근로계약서 작성 시 필수 체크리스트',
                    style: GoogleFonts.sora(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            // 주요 내용 섹션
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('근로계약서 필수 기재사항'),
                  const SizedBox(height: 16),
                  _buildCheckItem(
                    '근로계약 기간',
                    '계약 시작일과 종료일을 명확히 기재 (기간의 정함이 없는 경우 그 사실을 기재)',
                    Icons.date_range,
                  ),
                  _buildCheckItem(
                    '근무 장소',
                    '실제 근무하게 될 장소를 명확히 기재',
                    Icons.location_on,
                  ),
                  _buildCheckItem(
                    '업무 내용',
                    '담당하게 될 업무를 구체적으로 기재',
                    Icons.work,
                  ),
                  _buildCheckItem(
                    '근로시간',
                    '근로 시작과 종료 시각, 휴게시간, 주당 근로시간 등 명시',
                    Icons.access_time,
                  ),
                  _buildCheckItem(
                    '임금',
                    '기본급, 각종 수당, 상여금 등의 항목별 금액과 지급 방법, 지급일 명시',
                    Icons.attach_money,
                  ),
                  _buildCheckItem(
                    '주휴일 및 휴가',
                    '주휴일과 연차유급휴가 등의 부여 방법 명시',
                    Icons.weekend,
                  ),
                  _buildCheckItem(
                    '사회보험 적용',
                    '4대 보험(국민연금, 건강보험, 고용보험, 산재보험) 가입 여부 명시',
                    Icons.health_and_safety,
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('계약서 작성 시 주의사항'),
                  const SizedBox(height: 16),
                  _buildWarningItem(
                    '서면 작성 및 교부',
                    '근로계약서는 반드시 서면으로 작성하고, 근로자에게 1부 교부해야 합니다.',
                  ),
                  _buildWarningItem(
                    '근로기준법 준수',
                    '최저임금, 근로시간, 휴일·휴가 등 근로기준법에서 정한 최저 기준 이상으로 작성되어야 합니다.',
                  ),
                  _buildWarningItem(
                    '불이익 변경 금지',
                    '이미 맺은 근로계약의 내용을 근로자에게 불리하게 변경할 때는 근로자의 동의가 필요합니다.',
                  ),
                  _buildWarningItem(
                    '명확한 용어 사용',
                    '모호한 표현이나 오해의 소지가 있는 용어 사용을 피하고 명확하게 작성합니다.',
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('근로계약서 작성 단계'),
                  const SizedBox(height: 16),
                  _buildStepItem(
                    1,
                    '근로계약서 양식 준비',
                    '고용노동부에서 제공하는 표준 근로계약서 양식을 활용하거나 회사에 맞게 수정하여 사용',
                  ),
                  _buildStepItem(
                    2,
                    '필수 기재사항 작성',
                    '위에서 언급한 필수 기재사항을 모두 포함하여 작성',
                  ),
                  _buildStepItem(
                    3,
                    '근로자와 내용 협의',
                    '작성된 계약 내용을 근로자와 함께 검토하고 필요시 협의하여 조정',
                  ),
                  _buildStepItem(
                    4,
                    '서명 및 날인',
                    '사용자와 근로자 모두 계약서에 서명 또는 날인',
                  ),
                  _buildStepItem(
                    5,
                    '계약서 교부',
                    '작성된 계약서 1부를 근로자에게 반드시 교부',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.sora(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCheckItem(String title, String description, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningItem(String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: AppColors.warning.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.sora(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(int step, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
