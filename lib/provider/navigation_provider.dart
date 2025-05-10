import 'package:flutter_riverpod/flutter_riverpod.dart';

// 내비게이션 상태
class NavigationState {
  final int selectedIndex;

  NavigationState({this.selectedIndex = 0});

  NavigationState copyWith({int? selectedIndex}) {
    return NavigationState(
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }
}

// 내비게이션 상태 관리 StateNotifier
class NavigationNotifier extends StateNotifier<NavigationState> {
  NavigationNotifier() : super(NavigationState());

  // 탭 인덱스 변경
  void setTab(int index) {
    state = state.copyWith(selectedIndex: index);
  }

  // 홈탭으로 이동
  void goToHome() {
    state = state.copyWith(selectedIndex: 0);
  }

  // 채팅탭으로 이동
  void goToChat() {
    state = state.copyWith(selectedIndex: 1);
  }

  // 설정탭으로 이동
  void goToSettings() {
    state = state.copyWith(selectedIndex: 2);
  }
}

// 내비게이션 Provider 정의
final navigationProvider =
    StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier();
});
