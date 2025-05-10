// lib/provider/contact_auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContactAuthState {
  final bool isAuthenticated;

  ContactAuthState({this.isAuthenticated = false});

  ContactAuthState copyWith({bool? isAuthenticated}) {
    return ContactAuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class ContactAuthNotifier extends StateNotifier<ContactAuthState> {
  ContactAuthNotifier() : super(ContactAuthState());

  void authenticate(String password) {
    // Check if password is correct
    if (password == 'asdf1234') {
      state = state.copyWith(isAuthenticated: true);
    }
  }

  void resetAuthentication() {
    state = state.copyWith(isAuthenticated: false);
  }
}

final contactAuthProvider =
    StateNotifierProvider<ContactAuthNotifier, ContactAuthState>((ref) {
  return ContactAuthNotifier();
});
