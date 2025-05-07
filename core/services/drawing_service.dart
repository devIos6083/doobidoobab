import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:doobidoobab/core/utils/logger.dart';

class DrawingService {
  // 그림을 저장하는 메서드
  Future<bool> saveDrawing(
    String word,
    List<DrawingPoint> drawingPoints,
    Size canvasSize,
  ) async {
    try {
      // 캔버스 생성
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      // 배경 그리기
      canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
        paint,
      );

      // 그림 그리기
      for (int i = 0; i < drawingPoints.length; i++) {
        if (drawingPoints[i].isNewPath) {
          paint.color = drawingPoints[i].paint.color;
          paint.strokeWidth = drawingPoints[i].paint.strokeWidth;
          paint.strokeCap = drawingPoints[i].paint.strokeCap;
          paint.style = drawingPoints[i].paint.style;
        } else if (i > 0) {
          canvas.drawLine(
            drawingPoints[i - 1].offset,
            drawingPoints[i].offset,
            paint,
          );
        }
      }

      // 그림을 이미지로 변환
      final picture = recorder.endRecording();
      final image = await picture.toImage(
        canvasSize.width.toInt(),
        canvasSize.height.toInt(),
      );
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // 앱 디렉토리 가져오기
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$word.png');

      // 파일로 저장
      await file.writeAsBytes(bytes);
      return true;
    } catch (e) {
      print('그림 저장 중 오류 발생: $e');
      return false;
    }
  }

  // 저장된 모든 그림 불러오기
  Future<Map<String, Uint8List>> getAllDrawings() async {
    final Map<String, Uint8List> drawings = {};
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = await directory.list().toList();

      for (var file in files) {
        if (file.path.endsWith('.png')) {
          final fileName = file.path.split('/').last;
          final word = fileName.replaceAll('.png', '');
          final bytes = await File(file.path).readAsBytes();
          drawings[word] = bytes;
        }
      }
    } catch (e) {
      print('그림 불러오기 중 오류 발생: $e');
    }
    return drawings;
  }
}

/// 그림 그리기 점 모델
class DrawingPoint {
  final Offset offset;
  final Paint paint;
  final bool isNewPath;

  DrawingPoint({
    required this.offset,
    required this.paint,
    this.isNewPath = false,
  });
}
