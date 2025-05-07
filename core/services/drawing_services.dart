import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:doobidoobab/data/models/words.dart';
import 'package:doobidoobab/presentation/widgets/drawing_canvas.dart';
import 'package:http_parser/http_parser.dart';

/// 그림 저장 및 관리를 위한 서비스
class DrawingService {
  // 싱글톤 패턴 구현
  static final DrawingService _instance = DrawingService._internal();
  factory DrawingService() => _instance;
  DrawingService._internal();

  // 단어별 그림 저장 맵 (단어 → 그림 이미지 바이트)
  final Map<String, Uint8List> _drawings = {};
  Future<bool> _sendImageForPrediction(Uint8List imageData, String word) async {
    try {
      const String apiUrl =
          'Your-Api-Key';

      print('==== API 요청 시작 ====');
      print('URL: $apiUrl');
      print('단어: $word');
      print('이미지 크기: ${imageData.length} 바이트');

      // HTTP 요청에 사용할 Dio 인스턴스 생성
      final dio = Dio();

      // 타임아웃 설정 추가
      dio.options.connectTimeout = Duration(seconds: 15);
      dio.options.receiveTimeout = Duration(seconds: 15);

      // 파일 형식으로 이미지 데이터 생성
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          imageData,
          filename: 'drawing.png',
          contentType: MediaType('image', 'png'),
        ),
        'word': word,
      });

      print('폼 데이터 생성 완료, 요청 전송 중...');

      // POST 요청 보내기
      final response = await dio.post(
        apiUrl,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.plain,
        ),
      );

      print('응답 수신: 상태 코드=${response.statusCode}');
      print('응답 내용: ${response.data}');

      // 응답 결과 확인
      if (response.statusCode == 200) {
        final String responseText = response.data.toString().trim();
        return responseText == 'true';
      } else {
        print('API 오류: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('예측 API 요청 중 오류 발생: $e');
      // 상세 오류 정보 출력
      if (e is DioException) {
        print('DioError 타입: ${e.type}');
        print('DioError 메시지: ${e.message}');
        print('DioError 응답: ${e.response}');
      }

      // 개발 단계에서는 테스트를 위해 임의로 성공으로 처리할 수 있음
      // return true; // 테스트용 - 항상 성공으로 처리

      return false;
    }
  }

  /// 그림 데이터를 Uint8List로 변환하여 반환
  Future<Uint8List?> getDrawingImageData(
      List<DrawingPoint> drawingPoints, Size size) async {
    try {
      // 그림이 없으면 null 반환
      if (drawingPoints.isEmpty) return null;

      // 반드시 배경은 흰색으로 설정 (서버에서 검은 배경, 흰색 그림을 기대함)
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromPoints(Offset(0.0, 0.0), Offset(size.width, size.height)),
      );

      // 배경 그리기 (흰색)
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );

      // 그림 그리기 (검은색 또는 사용자가 선택한 색상)
      for (int i = 0; i < drawingPoints.length; i++) {
        if (i == 0 || drawingPoints[i].isNewPath) {
          canvas.drawPoints(
            ui.PointMode.points,
            [drawingPoints[i].offset],
            drawingPoints[i].paint,
          );
        } else {
          canvas.drawLine(
            drawingPoints[i - 1].offset,
            drawingPoints[i].offset,
            drawingPoints[i].paint,
          );
        }
      }

      // 이미지 크기 최적화 - 서버에서 기대하는 크기
      final img = await recorder.endRecording().toImage(
            size.width.toInt(),
            size.height.toInt(),
          );

      // PNG 형식으로 이미지 변환 (투명도 유지)
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        print('이미지 변환 실패: byteData는 null입니다');
        return null;
      }

      print('이미지 데이터 생성 성공: ${byteData.buffer.asUint8List().length} 바이트');
      return byteData.buffer.asUint8List();
    } catch (e) {
      print('그림 데이터 변환 오류: $e');
      return null;
    }
  }

  /// 현재 그린 그림을 특정 단어에 저장
  Future<bool> saveDrawing(
      String word, List<DrawingPoint> drawingPoints, Size size) async {
    try {
      // 그림을 이미지로 변환
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromPoints(
          const Offset(0.0, 0.0),
          Offset(size.width, size.height),
        ),
      );

      // 배경 그리기 (흰색)
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white,
      );

      // 그림 그리기
      for (int i = 0; i < drawingPoints.length; i++) {
        if (i == 0 || drawingPoints[i].isNewPath) {
          // 새 경로 시작
          canvas.drawPoints(
            ui.PointMode.points,
            [drawingPoints[i].offset],
            drawingPoints[i].paint,
          );
        } else {
          // 선으로 연결
          canvas.drawLine(
            drawingPoints[i - 1].offset,
            drawingPoints[i].offset,
            drawingPoints[i].paint,
          );
        }
      }

      // 이미지로 변환
      final picture = recorder.endRecording();
      final img = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      // 저장
      _drawings[word] = pngBytes;
      return true;
    } catch (e) {
      print('그림 저장 오류: $e');
      return false;
    }
  }

  /// 저장된 특정 단어의 그림 가져오기
  Uint8List? getDrawing(String word) {
    return _drawings[word];
  }

  /// 모든 저장된 그림 목록 가져오기
  Map<String, Uint8List> getAllDrawings() {
    return Map.from(_drawings);
  }

  /// 저장된 그림이 있는지 확인
  bool hasDrawing(String word) {
    return _drawings.containsKey(word);
  }

  /// 모든 그림 지우기
  void clearAllDrawings() {
    _drawings.clear();
  }
}
