// lib/screen/phone_call_screen.dart
import 'package:flutter/material.dart';
import 'package:focus_life/models/contact_model.dart';
import 'package:focus_life/utils/constant.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class PhoneCallScreen extends StatefulWidget {
  final Contact contact;

  const PhoneCallScreen({super.key, required this.contact});

  @override
  State<PhoneCallScreen> createState() => _PhoneCallScreenState();
}

class _PhoneCallScreenState extends State<PhoneCallScreen> {
  late Timer _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    // 통화 시간을 측정하기 위한 타이머
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String get callDuration {
    final minutes = _seconds ~/ 60;
    final seconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '연결중...',
          style: GoogleFonts.sora(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 연락처 프로필 이미지 (원형)
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: Text(
                widget.contact.name.substring(0, 1),
                style: GoogleFonts.sora(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 연락처 이름
            Text(
              widget.contact.name,
              style: GoogleFonts.sora(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // 연락처 직책/부서
            Text(
              '${widget.contact.department} / ${widget.contact.position}',
              style: GoogleFonts.sora(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),

            // 전화번호
            Text(
              widget.contact.phoneNumber,
              style: GoogleFonts.sora(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 40),

            // 통화 시간
            Text(
              callDuration,
              style: GoogleFonts.sora(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 80),

            // 통화 컨트롤 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 스피커 버튼
                _buildCallControlButton(
                  icon: Icons.volume_up,
                  color: Colors.grey,
                  onPressed: () {},
                ),
                const SizedBox(width: 40),

                // 통화 종료 버튼
                _buildCallControlButton(
                  icon: Icons.call_end,
                  color: Colors.red,
                  size: 70,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 40),

                // 마이크 음소거 버튼
                _buildCallControlButton(
                  icon: Icons.mic_off,
                  color: Colors.grey,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallControlButton({
    required IconData icon,
    required Color color,
    double size = 50,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(size),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.5,
        ),
      ),
    );
  }
}
