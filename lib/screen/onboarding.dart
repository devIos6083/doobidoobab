import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_life/provider/user_provider.dart';
import 'package:focus_life/screen/mainscreen.dart';
import 'package:google_fonts/google_fonts.dart';

// 현재 질문의 인덱스를 관리하는 Provider
final currentQuestionIndexProvider = StateProvider<int>((ref) => 0);

// 사용자가 선택한 답변을 저장하는 Provider
final selectedAnswersProvider =
    StateProvider<List<int?>>((ref) => [null, null, null]);

// 질문 리스트를 제공하는 Provider
final questionsProvider = Provider<List<Map<String, dynamic>>>((ref) => [
      {
        'question': '어떤 업종에서 일하고 계신가요?',
        'options': [
          '🚚 운수업 (택배, 배달, 트럭 운전 등)',
          '🏭 제조업 (공장, 생산직, 건설 등)',
          '🏢 사무직 (일반 회사원, 프리랜서 등)',
          '🍴 서비스업 (요식업, 판매직, 고객 서비스 등)',
          '⚙️ 기타'
        ]
      },
      {
        'question': '어떤 형태로 근무하고 계신가요?',
        'options': [
          '🕒 정규직 (풀타임 근무)',
          '⏳ 계약직 (단기 계약, 프로젝트 근무)',
          '🏃 프리랜서 / 자영업 (개인 사업, 자유 근무)',
          '🎯 파트타임 / 아르바이트'
        ]
      },
      {
        'question': '현재 어떤 문제로 고민 중이신가요?',
        'options': [
          '❌ 급여 미지급 / 임금 체불',
          '⏳ 초과 근무 / 연장 근무 문제',
          '⚖️ 부당 해고 / 계약 종료 문제',
          '🏥 산업재해 / 안전 문제',
          '🤷 아직 문제는 없고, 정보만 보고 싶어요!'
        ]
      },
    ]);

class OnboardingQuestionsRiverpod extends ConsumerWidget {
  const OnboardingQuestionsRiverpod({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 상태 값 읽기
    final currentQuestionIndex = ref.watch(currentQuestionIndexProvider);
    final selectedAnswers = ref.watch(selectedAnswersProvider);
    final questions = ref.watch(questionsProvider);

    // 다음 질문으로 이동
    void goToNextQuestion() {
      if (currentQuestionIndex < questions.length - 1 &&
          selectedAnswers[currentQuestionIndex] != null) {
        ref.read(currentQuestionIndexProvider.notifier).state++;
      } else if (currentQuestionIndex == questions.length - 1 &&
          selectedAnswers[currentQuestionIndex] != null) {
        // 🚀 사용자 데이터 업데이트 (UserProvider 반영)
        ref.read(userProvider.notifier).updateAnswers(selectedAnswers);

        // 🚀 안전한 네비게이션 처리
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainScreen(),
            ),
          );
        });
      }
    }

    // 사용자 답변 선택
    void selectAnswer(int answerIndex) {
      final newSelectedAnswers = [...selectedAnswers];
      newSelectedAnswers[currentQuestionIndex] = answerIndex;
      ref.read(selectedAnswersProvider.notifier).state = newSelectedAnswers;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '기본 정보',
          style: GoogleFonts.sora(
            color: const Color(0xFF3F414E),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ✅ 진행 바 (Progress Bar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(
                  questions.length,
                  (index) => Expanded(
                    child: Container(
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: index <= currentQuestionIndex
                            ? const Color(0xFF8E97FD)
                            : const Color(0xFFE6E7F2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ✅ 질문 및 선택지
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 질문 표시
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        questions[currentQuestionIndex]['question'],
                        style: GoogleFonts.sora(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3F414E),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 선택지 리스트
                    Expanded(
                      child: ListView.builder(
                        itemCount:
                            questions[currentQuestionIndex]['options'].length,
                        itemBuilder: (context, index) {
                          final bool isSelected =
                              selectedAnswers[currentQuestionIndex] == index;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GestureDetector(
                              onTap: () => selectAnswer(index),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFFE6F9E7)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFE6E7F2),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        questions[currentQuestionIndex]
                                            ['options'][index],
                                        style: GoogleFonts.sora(
                                          fontSize: 14,
                                          color: const Color(0xFF3F414E),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected
                                            ? const Color(0xFF4CAF50)
                                            : Colors.white,
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF4CAF50)
                                              : const Color(0xFFE6E7F2),
                                          width: 1,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ 다음 버튼
            Padding(
              padding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
              child: ElevatedButton(
                onPressed: selectedAnswers[currentQuestionIndex] != null
                    ? goToNextQuestion
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8E97FD),
                  disabledBackgroundColor: const Color(0xFFCCCEE5),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Next',
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
