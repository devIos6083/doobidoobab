import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_life/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// 사용자 상태를 관리하는 StateNotifier
class UserNotifier extends StateNotifier<UserModel> {
  UserNotifier()
      : super(UserModel(name: "", answers: [null, null, null, null])) {
    _loadUserData();
  }

  // 사용자 정보 불러오기
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');

    if (userData != null) {
      final Map<String, dynamic> userMap = jsonDecode(userData);
      state = UserModel.fromJson(userMap);
    }
  }

  // 사용자 정보 저장하기
  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = jsonEncode(state.toJson());
    await prefs.setString('user_data', userData);
  }

  // 사용자 정보 업데이트
  void updateUser(UserModel user) {
    state = user;
    _saveUserData();
  }

  // 사용자 이름 업데이트
  void updateName(String name) {
    state = UserModel(name: name, answers: state.answers);
    _saveUserData();
  }

  // 사용자 응답 업데이트
  void updateAnswers(List<int?> answers) {
    state = UserModel(name: state.name, answers: answers);
    _saveUserData();
  }
}

// 사용자 Provider 정의
final userProvider = StateNotifierProvider<UserNotifier, UserModel>((ref) {
  return UserNotifier();
});
