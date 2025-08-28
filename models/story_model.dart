// models/story_model.dart
import 'dart:typed_data';

/// 스토리 모델 클래스
class Story {
  final String word;
  final String storyText;
  final List<String> panels;
  final List<String>? imageUrls;
  final String? imageUrl; // 단일 이미지 URL 필드 추가
  final Uint8List? userDrawing;
  final DateTime createdAt;

  Story({
    required this.word,
    required this.storyText,
    required this.panels,
    this.imageUrls,
    this.imageUrl, // 단일 이미지 URL 파라미터 추가
    this.userDrawing,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// 스토리 텍스트를 패널 별로 분리
  static List<String> parsePanels(String storyText) {
    return storyText.split('\n').where((line) => line.trim().isNotEmpty).map((
      line,
    ) {
      // "1. " 형태의 번호 제거
      final RegExp regExp = RegExp(r'^\d+\.\s*');
      return line.replaceFirst(regExp, '');
    }).toList();
  }

  /// Map 형식으로 변환 (데이터 저장용)
  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'storyText': storyText,
      'panels': panels,
      'imageUrls': imageUrls,
      'imageUrl': imageUrl, // 단일 이미지 URL 저장
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Map에서 객체 생성 (데이터 로드용)
  factory Story.fromMap(Map<String, dynamic> map, {Uint8List? userDrawing}) {
    return Story(
      word: map['word'] ?? '',
      storyText: map['storyText'] ?? '',
      panels: List<String>.from(map['panels'] ?? []),
      imageUrls:
          map['imageUrls'] != null ? List<String>.from(map['imageUrls']) : null,
      imageUrl: map['imageUrl'], // 단일 이미지 URL 로드
      userDrawing: userDrawing,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }
}
