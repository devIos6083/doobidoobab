// services/story_storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:doobi/models/story_model.dart';
import 'package:doobi/utils/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 스토리 저장 및 관리 서비스
class StoryStorageService {
  // 싱글톤 패턴
  static final StoryStorageService _instance = StoryStorageService._internal();
  factory StoryStorageService() => _instance;

  StoryStorageService._internal();

  // 키 상수
  static const String _storyListKey = 'story_list';
  static const String _storiesDir = 'stories';

  /// 스토리 목록 저장
  Future<bool> saveStoryList(List<Story> stories) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 스토리 정보만 추출 (바이너리 데이터는 파일로 저장)
      final List<Map<String, dynamic>> storiesData =
          stories.map((story) => story.toMap()).toList();

      // JSON으로 변환하여 저장
      final jsonString = jsonEncode(storiesData);
      final result = await prefs.setString(_storyListKey, jsonString);

      AppLogger.info('스토리 목록 저장 완료: ${stories.length}개');
      return result;
    } catch (e) {
      AppLogger.error('스토리 목록 저장 중 오류', e);
      return false;
    }
  }

  /// 스토리 목록 불러오기
  Future<List<Story>> loadStoryList() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final jsonString = prefs.getString(_storyListKey);
      if (jsonString == null) {
        AppLogger.info('저장된 스토리 목록이 없습니다.');
        return [];
      }

      // JSON 파싱
      final List<dynamic> storiesData = jsonDecode(jsonString);
      final List<Story> stories = [];

      // 스토리 객체로 변환
      for (var storyData in storiesData) {
        try {
          // 사용자 그림 불러오기
          final Uint8List? userDrawing = await loadDrawingFile(
            storyData['word'],
          );

          // 스토리 객체 생성
          final story = Story.fromMap(storyData, userDrawing: userDrawing);
          stories.add(story);
        } catch (e) {
          AppLogger.error('스토리 객체 변환 중 오류', e);
          // 오류가 있는 항목은 건너뛰고 계속 진행
          continue;
        }
      }

      AppLogger.info('스토리 목록 불러오기 완료: ${stories.length}개');
      return stories;
    } catch (e) {
      AppLogger.error('스토리 목록 불러오기 중 오류', e);
      return [];
    }
  }

  /// 단일 스토리 저장
  Future<bool> saveStory(Story story) async {
    try {
      // 기존 스토리 목록 불러오기
      final stories = await loadStoryList();

      // 같은 단어의 스토리가 있으면 업데이트, 없으면 추가
      final index = stories.indexWhere((s) => s.word == story.word);
      if (index != -1) {
        stories[index] = story;
      } else {
        stories.add(story);
      }

      // 사용자 그림 저장 (파일로)
      if (story.userDrawing != null) {
        await saveDrawingFile(story.word, story.userDrawing!);
      }

      // 목록 저장
      return await saveStoryList(stories);
    } catch (e) {
      AppLogger.error('스토리 저장 중 오류', e);
      return false;
    }
  }

  /// 사용자 그림 파일로 저장
  Future<String?> saveDrawingFile(String word, Uint8List drawingData) async {
    try {
      final directory = await getStoriesDirectory();
      final fileName = '${word}_drawing.png';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(drawingData);
      AppLogger.info('사용자 그림 저장 완료: ${file.path}');

      return file.path;
    } catch (e) {
      AppLogger.error('사용자 그림 저장 중 오류', e);
      return null;
    }
  }

  /// 사용자 그림 파일에서 불러오기
  Future<Uint8List?> loadDrawingFile(String word) async {
    try {
      final directory = await getStoriesDirectory();
      final fileName = '${word}_drawing.png';
      final file = File('${directory.path}/$fileName');

      if (!file.existsSync()) {
        AppLogger.warning('사용자 그림 파일이 존재하지 않습니다: ${file.path}');
        return null;
      }

      final bytes = await file.readAsBytes();
      AppLogger.info('사용자 그림 불러오기 완료: ${file.path}');

      return bytes;
    } catch (e) {
      AppLogger.error('사용자 그림 불러오기 중 오류', e);
      return null;
    }
  }

  /// 스토리 디렉토리 가져오기
  Future<Directory> getStoriesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final storiesDir = Directory('${appDir.path}/$_storiesDir');

    // 디렉토리가 없으면 생성
    if (!storiesDir.existsSync()) {
      await storiesDir.create(recursive: true);
    }

    return storiesDir;
  }

  /// 스토리 삭제
  Future<bool> deleteStory(String word) async {
    try {
      // 기존 스토리 목록 불러오기
      final stories = await loadStoryList();

      // 삭제할 스토리 찾기
      final filteredStories = stories.where((s) => s.word != word).toList();

      if (stories.length == filteredStories.length) {
        AppLogger.warning('삭제할 스토리를 찾을 수 없습니다: $word');
        return false;
      }

      // 사용자 그림 파일 삭제
      try {
        final directory = await getStoriesDirectory();
        final fileName = '${word}_drawing.png';
        final file = File('${directory.path}/$fileName');

        if (file.existsSync()) {
          await file.delete();
          AppLogger.info('사용자 그림 파일 삭제 완료: ${file.path}');
        }
      } catch (e) {
        AppLogger.error('사용자 그림 파일 삭제 중 오류', e);
        // 파일 삭제 실패해도 계속 진행
      }

      // 목록 저장
      return await saveStoryList(filteredStories);
    } catch (e) {
      AppLogger.error('스토리 삭제 중 오류', e);
      return false;
    }
  }
}
