// services/drawing_service.dart
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../widgets/drawing_canvas.dart';
import '../utils/logger.dart';

class DrawingService {
  // 싱글톤 패턴 구현
  static final DrawingService _instance = DrawingService._internal();
  factory DrawingService() => _instance;
  DrawingService._internal();

  // 단어별 그림 저장 맵
  final Map<String, Uint8List> _drawings = {};

  // 기본 이미지 데이터 생성 (UI 표시용)
  Future<Uint8List?> getDrawingImageData(
    List<DrawingPoint> drawingPoints,
    Size size,
  ) async {
    try {
      if (drawingPoints.isEmpty) {
        print('그림 포인트가 비어있음');
        return null;
      }

      print(
        '그림 변환 시작: ${drawingPoints.length}개 포인트, 크기: ${size.width}x${size.height}',
      );

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

      // 그림 그리기
      for (int i = 0; i < drawingPoints.length; i++) {
        if (i == 0 || drawingPoints[i].isNewPath) {
          canvas.drawPoints(ui.PointMode.points, [
            drawingPoints[i].offset,
          ], drawingPoints[i].paint);
        } else {
          canvas.drawLine(
            drawingPoints[i - 1].offset,
            drawingPoints[i].offset,
            drawingPoints[i].paint,
          );
        }
      }

      final img = await recorder.endRecording().toImage(
        size.width.toInt(),
        size.height.toInt(),
      );

      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        print('이미지 변환 실패: byteData는 null입니다');
        return null;
      }

      final uint8List = byteData.buffer.asUint8List();

      // PNG 헤더 확인 (디버깅용)
      print('PNG 헤더 확인: ${uint8List.take(8).toList()}');
      print('이미지 변환 완료: ${uint8List.length} 바이트');

      return uint8List;
    } catch (e) {
      print('그림 데이터 변환 오류: $e');
      print('스택 트레이스: ${StackTrace.current}');
      return null;
    }
  }

  // 서버 최적화 이미지 생성 (검정색 고정, 크기 조정)
  Future<Uint8List?> getDrawingImageDataForServer(
    List<DrawingPoint> drawingPoints,
    Size size,
  ) async {
    try {
      if (drawingPoints.isEmpty) {
        print('그림 포인트가 비어있음');
        return null;
      }

      print('서버용 그림 변환 시작: ${drawingPoints.length}개 포인트');

      // 1. 먼저 캔버스에 그리기
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

      // 그림 그리기 (검정색으로 강제)
      for (int i = 0; i < drawingPoints.length; i++) {
        // 서버가 예상하는 검정색으로 고정
        final blackPaint =
            Paint()
              ..color = Colors.black
              ..isAntiAlias = true
              ..strokeWidth =
                  drawingPoints[i].paint.strokeWidth *
                  0.7 // 선 굵기 약간 감소
              ..strokeCap = StrokeCap.round
              ..style = PaintingStyle.stroke;

        if (i == 0 || drawingPoints[i].isNewPath) {
          canvas.drawPoints(ui.PointMode.points, [
            drawingPoints[i].offset,
          ], blackPaint);
        } else {
          canvas.drawLine(
            drawingPoints[i - 1].offset,
            drawingPoints[i].offset,
            blackPaint,
          );
        }
      }

      // 2. 이미지로 변환
      final picture = recorder.endRecording();
      final img = await picture.toImage(
        size.width.toInt(),
        size.height.toInt(),
      );

      // 3. 크기 조정 (서버의 모델에 맞게)
      final resizedImg = await resizeImage(img, 280, 280);

      final byteData = await resizedImg.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) {
        print('이미지 변환 실패');
        return null;
      }

      final uint8List = byteData.buffer.asUint8List();
      print('서버용 이미지 생성 완료: ${uint8List.length} 바이트');

      return uint8List;
    } catch (e) {
      print('서버용 그림 변환 오류: $e');
      return null;
    }
  }

  // 이미지 리사이즈 함수
  Future<ui.Image> resizeImage(ui.Image image, int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromPoints(
        Offset(0, 0),
        Offset(width.toDouble(), height.toDouble()),
      ),
    );

    // 흰색 배경
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = Colors.white,
    );

    // 이미지 그리기 (크기 조정)
    final paint = Paint()..filterQuality = FilterQuality.high;
    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dstRect = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());

    canvas.drawImageRect(image, srcRect, dstRect, paint);

    final picture = recorder.endRecording();
    return await picture.toImage(width, height);
  }

  // 그림을 파일로 저장하고 경로 반환
  Future<String?> saveDrawingToFile(String word, Uint8List imageData) async {
    try {
      // 임시 디렉토리 가져오기
      final directory = await getTemporaryDirectory();

      // 타임스탬프를 포함한 파일명 생성
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${word}_$timestamp.png';
      final filePath = '${directory.path}/$fileName';

      // 파일로 저장
      final file = File(filePath);
      await file.writeAsBytes(imageData);

      // 디버깅 정보 출력
      print('=== 이미지 파일 정보 ===');
      print('단어: $word');
      print('파일 경로: $filePath');
      print('파일 크기: ${await file.length()} 바이트');
      print('파일 존재: ${await file.exists()}');

      // PNG 헤더 확인
      final bytes = await file.readAsBytes();
      print('PNG 헤더: ${bytes.take(8).toList()}');

      print('\n=== 파일 확인 방법 ===');
      print('1. Finder 열기');
      print('2. Shift + Command + G 누르기');
      print('3. 위 경로 붙여넣기: $filePath');
      print('\n이미지 미리보기 URL: file://$filePath\n');

      if (await file.exists()) {
        print('✅ 파일 생성 성공!');

        // Documents 디렉토리에도 복사 (찾기 쉽게)
        try {
          final docsDir = await getApplicationDocumentsDirectory();
          final docsPath = '${docsDir.path}/${word}_latest.png';
          final docsFile = File(docsPath);
          await docsFile.writeAsBytes(imageData);
          print('📁 Documents 디렉토리에도 저장: $docsPath');
        } catch (e) {
          print('Documents 저장 실패: $e');
        }

        return filePath;
      } else {
        print('❌ 파일이 생성되지 않았습니다.');
        return null;
      }
    } catch (e) {
      print('파일 저장 중 오류: $e');
      return null;
    }
  }

  // 현재 그린 그림을 특정 단어에 저장
  Future<bool> saveDrawing(
    String word,
    List<DrawingPoint> drawingPoints,
    Size size,
  ) async {
    try {
      final imageData = await getDrawingImageData(drawingPoints, size);
      if (imageData == null) return false;

      // 메모리에 저장
      _drawings[word] = imageData;

      // 파일로도 저장 (옵션)
      await saveDrawingToFile(word, imageData);

      return true;
    } catch (e) {
      print('그림 저장 오류: $e');
      return false;
    }
  }

  // 저장된 특정 단어의 그림 가져오기
  Uint8List? getDrawing(String word) {
    return _drawings[word];
  }

  // 모든 저장된 그림 목록 가져오기
  Map<String, Uint8List> getAllDrawings() {
    return Map.from(_drawings);
  }

  // 저장된 그림이 있는지 확인
  bool hasDrawing(String word) {
    return _drawings.containsKey(word);
  }

  // 모든 그림 지우기
  void clearAllDrawings() {
    _drawings.clear();
  }
}
