// lib/screen/main_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:focus_life/provider/navigation_provider.dart';
import 'package:focus_life/provider/user_provider.dart';
import 'package:focus_life/screen/home_tab.dart';
import 'package:focus_life/screen/messenger_chat.dart';
import 'package:focus_life/screen/contacts_tab.dart'; // Import new contacts tab
import 'package:focus_life/utils/constant.dart';
import 'package:google_fonts/google_fonts.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 네비게이션 상태 가져오기
    final navigationState = ref.watch(navigationProvider);
    final selectedIndex = navigationState.selectedIndex;

    // 각 탭에 맞는 화면 리스트 (연락처 탭 추가)
    final List<Widget> pages = [
      const HomeTabRiverpod(),
      const MessengerChatScreenRiverpod(),
      const ContactsTabRiverpod(), // 설정 대신 연락처 탭으로 변경
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Safe',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.star,
              color: AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Work',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: '홈',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: '채팅',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.contacts), // 아이콘 변경
                label: '연락처', // 라벨 변경
              ),
            ],
            currentIndex: selectedIndex,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.grey,
            onTap: (index) =>
                ref.read(navigationProvider.notifier).setTab(index),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
