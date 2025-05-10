import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF8E97FD);
  static const Color secondary = Color(0xFF6E74CC);
  static const Color success = Color(0xFF4CAF50);
  static const Color accent = Color(0xFF6CB28E);
  static const Color warning = Color(0xFFFFCF86);
  static const Color error = Color(0xFFFA6E5A);
  static const Color textPrimary = Color(0xFF3F414E);
  static const Color textSecondary = Color(0xFFA1A4B2);
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFF5F5F9);
}

class UserInfoConstants {
  static const List<String> jobTypes = ['운수업', '제조업', '사무직', '서비스업', '기타'];

  static const List<String> employmentTypes = [
    '정규직',
    '계약직',
    '프리랜서/자영업',
    '파트타임/아르바이트'
  ];

  static const List<String> issueTypes = [
    '급여 미지급/임금 체불',
    '초과 근무/연장 근무 문제',
    '부당 해고/계약 종료 문제',
    '산업재해/안전 문제',
    '정보만 보고 싶음'
  ];

  static const List<String> attendanceFrequency = [
    '0 ~ 10회',
    '10 ~ 20회',
    '20 ~ 30회',
    '정해진 바 없음'
  ];
}

class Message {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  Message({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}
