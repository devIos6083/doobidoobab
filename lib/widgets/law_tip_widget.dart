// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:focus_life/models/lawtip_model.dart';
import 'package:focus_life/provider/lawtip_provider.dart';
import 'package:focus_life/utils/constant.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers
final lawTipsProvider =
    StateNotifierProvider<LawTipsNotifier, List<LawTip>>((ref) {
  return LawTipsNotifier();
});

final dailyLawTipProvider = Provider<LawTip>((ref) {
  return ref.watch(lawTipsProvider.notifier).getDailyTip();
});

// Interactive Law Tip Widget
class InteractiveLawTipWidget extends ConsumerStatefulWidget {
  final String tipId;
  final VoidCallback? onTapDetail;

  const InteractiveLawTipWidget({
    super.key,
    required this.tipId,
    this.onTapDetail,
  });

  @override
  ConsumerState<InteractiveLawTipWidget> createState() =>
      _InteractiveLawTipWidgetState();
}

class _InteractiveLawTipWidgetState
    extends ConsumerState<InteractiveLawTipWidget> {
  @override
  Widget build(BuildContext context) {
    // 여기서 팁을 가져올 때 null 체크 추가
    final tip = ref.watch(lawTipsProvider.notifier).getTipById(widget.tipId);

    if (tip == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.gavel,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  tip.title,
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              tip.category,
              style: GoogleFonts.sora(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tip.summary,
            style: GoogleFonts.sora(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 자세히 보기 버튼
              TextButton.icon(
                onPressed: () {
                  // 여기서 try-catch로 예외 처리 추가
                  try {
                    _showDetailedTip(context, tip);
                    if (widget.onTapDetail != null) {
                      widget.onTapDetail!();
                    }
                  } catch (e) {
                    // 오류 발생 시 사용자에게 알림
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('상세 정보를 불러오는 중 문제가 발생했습니다: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    print('상세 정보 로딩 오류: $e');
                  }
                },
                icon: Text(
                  '자세히 보기',
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
                label: Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetailedTip(BuildContext context, LawTip tip) {
    // 관련 팁을 가져올 때 null 체크와 예외 처리 추가
    List<LawTip> relatedTips = [];
    try {
      relatedTips = ref.read(lawTipsProvider.notifier).getRelatedTips(tip.id);
    } catch (e) {
      print('관련 팁 로딩 오류: $e');
      // 오류가 발생해도 UI는 계속 표시되도록 빈 리스트로 설정
      relatedTips = [];
    }

    // 모달 표시 전에 컨텍스트가 유효한지 확인
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // 모달이 닫힐 때 오류가 발생할 경우를 대비한 예외 처리
      builder: (BuildContext modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, controller) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 드래그 핸들
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 제목 및 북마크 아이콘
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          tip.title,
                          style: GoogleFonts.sora(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // 카테고리 표시
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      tip.category,
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 상세 내용 스크롤 뷰
                  Expanded(
                    child: ListView(
                      controller: controller,
                      children: [
                        // 상세 내용
                        Text(
                          tip.detailedContent,
                          style: GoogleFonts.sora(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // 출처 정보 (있는 경우에만 표시)
                        if (tip.source.isNotEmpty) ...[
                          Text(
                            '출처',
                            style: GoogleFonts.sora(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            tip.source,
                            style: GoogleFonts.sora(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                        // 관련 법률 정보 (있는 경우에만 표시)
                        if (relatedTips.isNotEmpty) ...[
                          Text(
                            '관련 법률 정보',
                            style: GoogleFonts.sora(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 15),
                          // 관련 팁 목록
                          ...relatedTips.map((relatedTip) => InkWell(
                                onTap: () {
                                  // 모달이 닫히고 새 모달이 열리는 과정에서 오류 가능성을 줄이기 위해 딜레이 추가
                                  Navigator.of(modalContext).pop();
                                  Future.delayed(
                                      const Duration(milliseconds: 300), () {
                                    // 새 모달을 열 때 컨텍스트가 유효한지 확인
                                    if (context.mounted) {
                                      try {
                                        _showDetailedTip(context, relatedTip);
                                      } catch (e) {
                                        print('관련 팁 상세 정보 로딩 오류: $e');
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                '관련 정보를 불러오는 중 문제가 발생했습니다'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              relatedTip.category,
                                              style: GoogleFonts.sora(
                                                fontSize: 10,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              relatedTip.title,
                                              style: GoogleFonts.sora(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 14,
                                            color: AppColors.textSecondary,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).catchError((error) {
      // 모달 표시 중 발생하는 오류 처리
      print('모달 표시 오류: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('정보를 표시하는 중 문제가 발생했습니다'),
          backgroundColor: Colors.red,
        ),
      );
    });
  }
}
