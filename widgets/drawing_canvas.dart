// presentation/widgets/drawing_canvas.dart 파일 (필요한 경우 수정)

import 'dart:ui';

import 'package:flutter/material.dart';

/// 그림 그리기 점 데이터 클래스
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

/// 그림 그리기 캔버스 위젯
class DrawingCanvas extends StatelessWidget {
  final List<DrawingPoint> drawingPoints;
  final Color selectedColor;
  final double strokeWidth;
  final Function(Offset) onPathStart;
  final Function(Offset) onPathUpdate;
  final Function() onPathEnd;

  const DrawingCanvas({
    super.key,
    required this.drawingPoints,
    required this.selectedColor,
    required this.strokeWidth,
    required this.onPathStart,
    required this.onPathUpdate,
    required this.onPathEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        onPathStart(details.localPosition);
      },
      onPanUpdate: (details) {
        onPathUpdate(details.localPosition);
      },
      onPanEnd: (details) {
        onPathEnd();
      },
      child: CustomPaint(
        painter: DrawingPainter(
          drawingPoints: drawingPoints,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// 그림 그리기를 위한 CustomPainter
class DrawingPainter extends CustomPainter {
  final List<DrawingPoint> drawingPoints;

  DrawingPainter({required this.drawingPoints});

  @override
  void paint(Canvas canvas, Size size) {
    // 배경 그리기 (선택 사항)
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // 그림 그리기
    for (int i = 0; i < drawingPoints.length; i++) {
      if (i == 0 || drawingPoints[i].isNewPath) {
        // 새 경로 시작
        canvas.drawPoints(
          PointMode.points,
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}