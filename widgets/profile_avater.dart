// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 사용자 프로필 아바타 위젯
///
/// 프로필 이미지가 있으면 표시하고, 없으면 이름의 첫 글자를 원 안에 표시합니다.
class ProfileAvatar extends StatelessWidget {
  /// 아바타 크기 (반지름)
  final double radius;

  /// 이미지 경로 (null이면 이니셜 아바타 표시)
  final String? imagePath;

  /// 사용자 이름 (이니셜 생성에 사용)
  final String name;

  /// 편집 가능 여부
  final bool isEditable;

  const ProfileAvatar({
    super.key,
    required this.radius,
    this.imagePath,
    required this.name,
    this.isEditable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 아바타 이미지 또는 이니셜
        _buildAvatarImage(),

        // 편집 버튼 (편집 가능한 경우에만 표시)
        if (isEditable)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAvatarImage() {
    if (imagePath != null && imagePath!.isNotEmpty) {
      print('이미지 경로: $imagePath');

      // 로컬 파일 경로인지 확인
      final isLocalPath = !imagePath!.startsWith('http');

      if (isLocalPath) {
        // 앱 문서 디렉토리에서 파일을 찾을 수 있는지 확인
        final file = File(imagePath!);

        if (file.existsSync()) {
          return Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.file(
                file,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  print('이미지 로드 오류: $error');
                  return _buildInitialAvatar();
                },
              ),
            ),
          );
        }
      }

      // 파일이 없는 경우 이니셜 아바타 표시
      return _buildInitialAvatar();
    } else {
      // 이미지 경로가 없는 경우 이니셜 표시
      return _buildInitialAvatar();
    }
  }

  /// 이니셜 아바타 생성
  Widget _buildInitialAvatar() {
    // 이름에서 첫 글자 추출
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    // 컬러 시드에서 고유 색상 생성
    final int colorSeed = name.isEmpty
        ? 0
        : name.codeUnits.reduce((value, element) => value + element);

    final Color avatarColor =
        Color((colorSeed * 0.2 % 1 * 0xFFFFFF).toInt()).withOpacity(1.0);

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            avatarColor,
            avatarColor.withOpacity(0.7),
          ],
        ),
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.quicksand(
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}