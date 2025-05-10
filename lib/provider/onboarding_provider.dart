import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_life/models/user_model.dart';
import 'package:focus_life/provider/user_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 온보딩 질문 모델
class OnboardingQuestion {
  final String question;
  final List<String> options;

  OnboardingQuestion({
    required this.question,
    required this.options,
  });
}

// 온보딩 상태 클래스
class OnboardingState {
  final List<OnboardingQuestion> questions;
  final int currentQuestionIndex;
  final List<int?> selectedAnswers;
  final bool isCompleted;

  OnboardingState({
    required this.questions,
    this.currentQuestionIndex = 0,
    required this.selectedAnswers,
    this.isCompleted = false,
  });

  OnboardingState copyWith({
    List<OnboardingQuestion>? questions,
    int? currentQuestionIndex,
    List<int?>? selectedAnswers,
    bool? isCompleted,
  }) {
    return OnboardingState(
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

// 온보딩 상태 관리 StateNotifier
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier()
      : super(OnboardingState(
          questions: [
            OnboardingQuestion(
              question: '어떤 업종에서 일하고 계신가요?',
              options: [
                '🚚 운수업 (택배, 배달, 트럭 운전 등)',
                '🏭 제조업 (공장, 생산직, 건설 등)',
                '🏢 사무직 (일반 회사원, 프리랜서 등)',
                '🍴 서비스업 (요식업, 판매직, 고객 서비스 등)',
                '⚙️ 기타'
              ],
            ),
            OnboardingQuestion(
              question: '어떤 형태로 근무하고 계신가요?',
              options: [
                '🕒 정규직 (풀타임 근무)',
                '⏳ 계약직 (단기 계약, 프로젝트 근무)',
                '🏃 프리랜서 / 자영업 (개인 사업, 자유 근무)',
                '🎯 파트타임 / 아르바이트'
              ],
            ),
            OnboardingQuestion(
              question: '현재 어떤 문제로 고민 중이신가요?',
              options: [
                '❌ 급여 미지급 / 임금 체불',
                '⏳ 초과 근무 / 연장 근무 문제',
                '⚖️ 부당 해고 / 계약 종료 문제',
                '🏥 산업재해 / 안전 문제',
                '🤷 아직 문제는 없고, 정보만 보고 싶어요!'
              ],
            ),
          ],
          selectedAnswers: [null, null, null],
        )) {
    _loadOnboardingStatus();
  }

  // 온보딩 상태 로드
  Future<void> _loadOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isCompleted = prefs.getBool('onboarding_completed') ?? false;

      if (isCompleted) {
        // 저장된 답변 로드
        final List<String> answerStrings =
            prefs.getStringList('onboarding_answers') ?? [];
        final List<int?> answers = answerStrings
            .map((s) => s == 'null' ? null : int.parse(s))
            .toList();

        // 답변이 모두 있다면 완료 상태로 설정
        if (answers.length == state.questions.length &&
            !answers.contains(null)) {
          state = state.copyWith(
            selectedAnswers: answers,
            isCompleted: true,
            currentQuestionIndex: state.questions.length - 1,
          );
        }
      }
    } catch (e) {
      print('온보딩 상태 로드 오류: $e');
    }
  }

  // 온보딩 상태 저장
  Future<void> _saveOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 답변을 문자열 리스트로 변환
      final List<String> answerStrings = state.selectedAnswers
          .map((answer) => answer?.toString() ?? 'null')
          .toList();

      await prefs.setStringList('onboarding_answers', answerStrings);
      await prefs.setBool('onboarding_completed', state.isCompleted);
    } catch (e) {
      print('온보딩 상태 저장 오류: $e');
    }
  }

  // 질문에 답변 설정
  void selectAnswer(int questionIndex, int answerIndex) {
    if (questionIndex >= state.questions.length) return;

    final newAnswers = List<int?>.from(state.selectedAnswers);
    newAnswers[questionIndex] = answerIndex;

    state = state.copyWith(selectedAnswers: newAnswers);
    _saveOnboardingStatus();
  }

  // 다음 질문으로 이동
  bool goToNextQuestion() {
    // 현재 질문에 답변이 없으면 이동 불가
    if (state.selectedAnswers[state.currentQuestionIndex] == null) {
      return false;
    }

    // 마지막 질문이면 완료 처리
    if (state.currentQuestionIndex >= state.questions.length - 1) {
      state = state.copyWith(isCompleted: true);
      _saveOnboardingStatus();
      return true;
    }

    // 다음 질문으로 이동
    state =
        state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1);
    return true;
  }

  // 이전 질문으로 이동
  bool goToPreviousQuestion() {
    if (state.currentQuestionIndex <= 0) {
      return false;
    }

    state =
        state.copyWith(currentQuestionIndex: state.currentQuestionIndex - 1);
    return true;
  }

  // 온보딩 완료 시 사용자 데이터를 UserProvider에 업데이트
  void completeOnboarding(WidgetRef ref) {
    final userNotifier = ref.read(userProvider.notifier);
    final onboardingState = ref.read(onboardingProvider);

    // 사용자 데이터를 업데이트
    userNotifier.updateUser(
      UserModel(
        name: "사용자", // 기본값 (이름 입력 로직이 추가될 경우 변경 가능)
        answers: onboardingState.selectedAnswers,
      ),
    );
  }

  // 온보딩 재시작
  void resetOnboarding() {
    state = OnboardingState(
      questions: state.questions,
      currentQuestionIndex: 0,
      selectedAnswers: List.filled(state.questions.length, null),
      isCompleted: false,
    );
    _saveOnboardingStatus();
  }
}

// 온보딩 Provider 정의
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});

// 온보딩 완료 여부 Provider (다른 화면에서 온보딩 완료 여부만 필요할 때 사용)
final isOnboardingCompletedProvider = Provider<bool>((ref) {
  return ref.watch(onboardingProvider).isCompleted;
});
