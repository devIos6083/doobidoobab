// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:focus_life/screen/onboarding.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:focus_life/provider/onboarding_provider.dart';

class SplashRiverpod extends ConsumerWidget {
  const SplashRiverpod({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 화면 크기 가져오기
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // 제목 (Safe Work)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Safe 텍스트
                  Text(
                    'Safe',
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3F414E),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // SVG 아이콘
                  SvgPicture.asset(
                    'img/star.svg',
                    width: 30,
                    height: 30,
                    color: const Color(0xFF8589EB),
                  ),
                  const SizedBox(width: 10),
                  // Work 텍스트
                  Text(
                    'Work',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3F414E),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 70),

              // 메인 이미지
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Image.asset(
                  'img/worker.jpg',
                  width: size.width * 0.8,
                  height: 300,
                ),
              ),

              const SizedBox(height: 30),

              // 핵심 문장 (Bold)
              Text(
                "Know Your Rights, Work Smarter",
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3F414E),
                ),
              ),

              const SizedBox(height: 20),

              // 부가 설명 (Light)
              Text(
                'Find laws and regulations instantly.\nWork with confidence.',
                textAlign: TextAlign.center,
                style: GoogleFonts.sora(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: const Color(0xFFA1A4B2),
                ),
              ),

              const SizedBox(height: 50),

              // Get Started 버튼
              Padding(
                padding: const EdgeInsets.only(bottom: 30, left: 30, right: 30),
                child: ElevatedButton(
                  onPressed: () {
                    // Riverpod을 사용한 Navigation (기본 Navigator 사용)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => OnboardingQuestionsRiverpod()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E97FD),
                    foregroundColor: Colors.white,
                    minimumSize: Size(size.width * 0.8, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
