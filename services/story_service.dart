// services/story_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:doobi/models/story_model.dart';
import 'package:doobi/services/story_storage_service.dart';
import 'package:doobi/utils/logger.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

/// 스토리 생성 및 관리 서비스
class StoryService {
  // API 엔드포인트
  static const String _storyApiUrl = 'Your API Key Here';
  static const String _imageApiUrl = 'Your API Key Here';

  // API 타임아웃 설정 - 이미지 생성용으로 증가
  static const Duration _connectTimeout = Duration(seconds: 30);
  static const Duration _receiveTimeout = Duration(seconds: 45);
  static const Duration _imageReceiveTimeout = Duration(
    minutes: 3,
  ); // 이미지용 타임아웃 증가

  // Dio 인스턴스
  late final Dio _dio;
  late final Dio _imageDio; // 이미지 전용 Dio 인스턴스

  // 싱글톤 패턴
  static final StoryService _instance = StoryService._internal();
  factory StoryService() => _instance;

  StoryService._internal() {
    // 일반 Dio 인스턴스 (텍스트 생성용)
    _dio = Dio();
    _dio.options.connectTimeout = _connectTimeout;
    _dio.options.receiveTimeout = _receiveTimeout;

    // 이미지 전용 Dio 인스턴스 (더 긴 타임아웃)
    _imageDio = Dio();
    _imageDio.options.connectTimeout = _connectTimeout;
    _imageDio.options.receiveTimeout = _imageReceiveTimeout;

    // Dio 로깅 설정 (디버그용)
    final logInterceptor = LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (obj) => AppLogger.debug(obj.toString()),
    );

    _dio.interceptors.add(logInterceptor);
    _imageDio.interceptors.add(logInterceptor);
  }

  /// 스토리 텍스트 생성 API 호출
  Future<String?> generateStoryText(String word, Uint8List drawing) async {
    try {
      AppLogger.info('스토리 텍스트 생성 시작: $word');

      // FormData 형식으로 변경 - word와 file 필드 사용
      final formData = FormData.fromMap({
        'word': word, // 'word' 필드 사용
        'file': MultipartFile.fromBytes(
          drawing,
          filename: '${word}_drawing.png',
          contentType: MediaType('image', 'png'),
        ),
      });

      final response = await _dio.post(
        _storyApiUrl,
        data: formData, // FormData 사용
        options: Options(
          contentType: 'multipart/form-data', // content-type 변경
          headers: {
            'Accept': 'application/json',
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      if (response.statusCode == 200) {
        final storyText = response.data['story'];
        AppLogger.info(
          '스토리 텍스트 생성 완료: ${storyText.substring(0, min(50, storyText.length))}...',
        );
        return storyText;
      } else {
        AppLogger.error('스토리 API 오류: ${response.statusCode}', response.data);
        return null;
      }
    } catch (e) {
      AppLogger.error('스토리 API 호출 중 오류', e);
      return null;
    }
  }

  // 스토리 이미지 생성 API 호출 - 재시도 로직 추가
  Future<String?> generateStoryImage(
    String word,
    String storyText,
    Uint8List drawing, {
    int maxRetries = 2,
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        AppLogger.info(
          '스토리 이미지 생성 시작: $word (시도 ${attempt + 1}/${maxRetries + 1})',
        );

        // FormData 생성 - word, story, file 필드 사용 (Postman 형식과 동일)
        final formData = FormData.fromMap({
          'word': word,
          'story': storyText,
          'file': MultipartFile.fromBytes(
            drawing,
            filename: '${word}_drawing.png',
            contentType: MediaType('image', 'png'),
          ),
        });

        final response = await _imageDio.post(
          // 이미지 전용 Dio 사용
          _imageApiUrl,
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
            headers: {
              'Accept': 'application/json, image/png', // PNG 포맷도 허용
              'ngrok-skip-browser-warning': 'true',
            },
            responseType: ResponseType.bytes, // 바이너리 데이터로 응답 받기
          ),
        );

        if (response.statusCode == 200) {
          // 응답 유형 확인
          final contentType = response.headers.value('content-type') ?? '';
          AppLogger.debug('응답 Content-Type: $contentType');

          if (contentType.contains('image/png') ||
              contentType.contains('image')) {
            // 이미지 데이터 받기
            final imageData = response.data as List<int>;
            AppLogger.info('이미지 데이터 수신 완료: ${imageData.length} 바이트');

            // 이미지 파일로 저장
            final directory = await getApplicationDocumentsDirectory();
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final imagePath = '${directory.path}/${word}_story_$timestamp.png';

            final file = File(imagePath);
            await file.writeAsBytes(imageData);

            AppLogger.info('이미지 파일 저장 완료: $imagePath');
            return 'file://$imagePath'; // file:// 프로토콜 사용
          } else if (contentType.contains('application/json')) {
            // JSON 응답인 경우 기존 방식으로 처리
            final dynamic jsonData = json.decode(utf8.decode(response.data));
            AppLogger.debug('JSON 응답: $jsonData');

            if (jsonData is Map) {
              if (jsonData.containsKey('images')) {
                final dynamic imagesData = jsonData['images'];
                if (imagesData is List && imagesData.isNotEmpty) {
                  final imageUrl = imagesData[0].toString();
                  AppLogger.info('스토리 이미지 URL 생성 완료: $imageUrl');
                  return imageUrl;
                }
              }
            }
          }

          AppLogger.warning('응답 데이터 처리 실패: 지원되지 않는 형식');
          if (attempt == maxRetries) return null;
        } else {
          AppLogger.error('이미지 API 오류: ${response.statusCode}');
          if (attempt == maxRetries) return null;
        }
      } on DioException catch (e) {
        if (e.type == DioExceptionType.receiveTimeout) {
          AppLogger.warning(
            '이미지 생성 타임아웃 (시도 ${attempt + 1}/${maxRetries + 1})',
          );
          if (attempt == maxRetries) {
            AppLogger.error('최대 재시도 횟수 초과 - 이미지 생성 실패');
            return null;
          }
          // 다음 시도 전 잠시 대기
          await Future.delayed(Duration(seconds: 5));
        } else {
          AppLogger.error('이미지 API 호출 중 DioException', e);
          if (attempt == maxRetries) return null;
        }
      } catch (e, stackTrace) {
        AppLogger.error('이미지 API 호출 중 오류', e);
        AppLogger.error('스택 트레이스:', stackTrace);
        if (attempt == maxRetries) return null;
      }
    }
    return null;
  }

  /// 전체 스토리 생성 프로세스 (단일 이미지 사용)
  Future<Story?> generateFullStory(String word, Uint8List drawing) async {
    try {
      // 1. 스토리 텍스트 생성 - 단어와 이미지를 함께 전송
      final storyText = await generateStoryText(word, drawing);
      if (storyText == null) return null;

      AppLogger.info('스토리 생성 완료, 이미지 생성 시작: $word');

      // 2. 스토리 패널 파싱
      final panels = Story.parsePanels(storyText);

      // 3. 이미지 생성 API 호출 - 생성된 스토리를 바탕으로, 단일 이미지 생성
      final imageUrl = await generateStoryImage(word, storyText, drawing);

      // 4. 스토리 객체 생성
      final story = Story(
        word: word,
        storyText: storyText,
        panels: panels,
        imageUrl: imageUrl, // 단일 이미지 URL 저장
        imageUrls: imageUrl != null ? [imageUrl] : null, // 호환성을 위해 리스트에도 저장
        userDrawing: drawing,
      );

      // 5. 스토리 저장
      final storyStorage = StoryStorageService();
      await storyStorage.saveStory(story);
      AppLogger.info('스토리 저장 완료: $word');

      return story;
    } catch (e) {
      AppLogger.error('스토리 생성 프로세스 오류', e);
      return null;
    }
  }

  /// 여러 이미지 생성 메서드 (인생네컷을 위한 별도 메서드, 필요시 사용)
  Future<List<String>?> generateMultipleStoryImages(
    String word,
    String storyText,
    Uint8List drawing,
  ) async {
    try {
      AppLogger.info('여러 스토리 이미지 생성 시작: $word');

      // FormData 생성 - word, story, file 필드 사용
      final formData = FormData.fromMap({
        'word': word,
        'story': storyText,
        'file': MultipartFile.fromBytes(
          drawing,
          filename: '${word}_drawing.png',
          contentType: MediaType('image', 'png'),
        ),
      });

      final response = await _imageDio.post(
        // 이미지 전용 Dio 사용
        _imageApiUrl,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {
            'Accept': 'application/json',
            'ngrok-skip-browser-warning': 'true',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> imageUrls = response.data['images'] ?? [];
        final result = imageUrls.map((url) => url.toString()).toList();

        AppLogger.info('여러 스토리 이미지 생성 완료: ${result.length}개');
        return result;
      } else {
        AppLogger.error('이미지 API 오류: ${response.statusCode}', response.data);
        return null;
      }
    } catch (e) {
      AppLogger.error('이미지 API 호출 중 오류', e);
      return null;
    }
  }

  /// 여러 이미지를 사용하는 스토리 생성 프로세스 (인생네컷 등에 사용, 필요시 호출)
  Future<Story?> generateFullStoryWithMultipleImages(
    String word,
    Uint8List drawing,
  ) async {
    try {
      // 1. 스토리 텍스트 생성
      final storyText = await generateStoryText(word, drawing);
      if (storyText == null) return null;

      AppLogger.info('스토리 생성 완료, 여러 이미지 생성 시작: $word');

      // 2. 스토리 패널 파싱
      final panels = Story.parsePanels(storyText);

      // 3. 여러 이미지 생성 API 호출
      final imageUrls = await generateMultipleStoryImages(
        word,
        storyText,
        drawing,
      );

      // 4. 스토리 객체 생성 - 첫 번째 이미지는 메인 이미지로 저장
      return Story(
        word: word,
        storyText: storyText,
        panels: panels,
        imageUrl:
            imageUrls != null && imageUrls.isNotEmpty ? imageUrls[0] : null,
        imageUrls: imageUrls, // 모든 이미지 URL 저장
        userDrawing: drawing,
      );
    } catch (e) {
      AppLogger.error('스토리 생성 프로세스 오류', e);
      return null;
    }
  }
}
