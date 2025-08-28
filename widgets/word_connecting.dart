// ignore_for_file: deprecated_member_use

import 'dart:math';
import 'package:doobi/models/words.dart';
import 'package:doobi/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

/// 단어 연결 게임 위젯 (수동 연결 방식)
class WordConnectingGameWidget extends StatefulWidget {
  final List<Word> optionWords;
  final Word currentWord;
  final Animation<double> cardAnimation;
  final List<int?> rightIndices;
  final Function()? onConnectionComplete;
  final List<int?>? initialConnectionPairs;
  final Function(List<int?>)? onConnectionUpdate;

  const WordConnectingGameWidget({
    super.key,
    required this.optionWords,
    required this.currentWord,
    required this.cardAnimation,
    required this.rightIndices,
    this.onConnectionComplete,
    this.initialConnectionPairs,
    this.onConnectionUpdate,
  });

  @override
  _WordConnectingGameWidgetState createState() =>
      _WordConnectingGameWidgetState();
}

class _WordConnectingGameWidgetState extends State<WordConnectingGameWidget> {
  // 좌측 카드 인덱스에 대응하는 우측 카드 인덱스 (연결되지 않은 경우 null)
  late List<int?> connectionPairs;
  // 사용자가 현재 선택한 좌측 카드 인덱스 (수동 연결을 위해)
  int? selectedLeftIndex;

  // 모든 연결이 완료되었는지 여부
  bool _allConnected = false;

  @override
  void initState() {
    super.initState();
    // 초기 연결 상태 설정
    connectionPairs =
        widget.initialConnectionPairs ??
        List<int?>.filled(widget.optionWords.length, null);
  }

  /// 좌측 카드 탭 시 처리: 이미 선택된 경우 취소, 아니면 선택
  void handleLeftCardTap(int index) {
    // 모든 연결이 완료되었으면 더 이상 선택할 수 없음
    if (_allConnected) return;

    setState(() {
      if (selectedLeftIndex == index) {
        selectedLeftIndex = null;
      } else {
        selectedLeftIndex = index;
      }
    });
  }

  /// 우측 카드 탭 시 처리: 좌측 카드가 선택되어 있다면 두 카드 연결
  void handleRightCardTap(int index) {
    // 모든 연결이 완료되었으면 더 이상 선택할 수 없음
    if (_allConnected) return;

    if (selectedLeftIndex != null) {
      setState(() {
        // 이미 연결된 다른 카드가 있으면 해당 연결 해제
        for (int i = 0; i < connectionPairs.length; i++) {
          if (connectionPairs[i] == index) {
            connectionPairs[i] = null;
          }
        }

        connectionPairs[selectedLeftIndex!] = index;
        selectedLeftIndex = null;

        // 연결 상태 업데이트 콜백 호출
        if (widget.onConnectionUpdate != null) {
          widget.onConnectionUpdate!(List.from(connectionPairs));
        }
      });

      // 모든 연결이 완료되었는지 체크
      checkAllConnections();
    }
  }

  void checkAllConnections() {
    // 모든 연결이 완료되었는지 확인
    if (!connectionPairs.contains(null)) {
      setState(() {
        _allConnected = true;
      });

      // 중요: 콜백 호출 전에 적절한 딜레이를 줌
      Future.delayed(const Duration(milliseconds: 500), () {
        // 콜백이 있으면 반드시 호출
        if (widget.onConnectionComplete != null) {
          widget.onConnectionComplete!();
        } else {
          // 콜백이 없는 경우 (디버깅용)
          print("경고: onConnectionComplete 콜백이 설정되지 않았습니다!");
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // AI 문제 출제 애니메이션
          SizedBox(
            height: 100,
            child: Lottie.asset('lottie/ai.json', fit: BoxFit.contain),
          ),
          const SizedBox(height: 20),
          // 문제 텍스트
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '단어와 뜻을 연결하세요',
              style: GoogleFonts.quicksand(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 40),
          // 연결 게임 UI
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: ScaleTransition(
              scale: widget.cardAnimation,
              child: Row(
                children: [
                  // 좌측 열 (영어 단어)
                  Expanded(
                    child: Column(
                      children: List.generate(widget.optionWords.length, (
                        index,
                      ) {
                        // 좌측 카드가 선택되어 있거나 이미 연결된 경우 강조 처리
                        bool isSelected =
                            (selectedLeftIndex == index) ||
                            (connectionPairs[index] != null);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: buildConnectionCard(
                            index,
                            widget.optionWords[index].word,
                            isLeftSide: true,
                            isSelected: isSelected,
                            showResult: _allConnected,
                            isCorrectPair:
                                _allConnected &&
                                connectionPairs[index] != null &&
                                widget.optionWords[index].word ==
                                    widget
                                        .optionWords[widget
                                            .rightIndices[connectionPairs[index]!]!]
                                        .word,
                            onTap: () => handleLeftCardTap(index),
                          ),
                        );
                      }),
                    ),
                  ),
                  // 중간 연결선 영역
                  SizedBox(
                    width: 40,
                    child: CustomPaint(
                      painter: ConnectionLinePainter(
                        connections: connectionPairs,
                        color: AppColors.accent,
                      ),
                      size: const Size(40, 250),
                    ),
                  ),
                  // 우측 열 (한글 뜻)
                  Expanded(
                    child: Column(
                      children: List.generate(widget.optionWords.length, (
                        index,
                      ) {
                        int rightIndex = widget.rightIndices[index]!;
                        // 우측 카드가 이미 연결된 경우 강조 처리
                        bool isSelected = connectionPairs.contains(index);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: buildConnectionCard(
                            index,
                            widget.optionWords[rightIndex].meaning,
                            isLeftSide: false,
                            isSelected: isSelected,
                            showResult: _allConnected,
                            isCorrectPair:
                                _allConnected &&
                                connectionPairs.contains(index) &&
                                widget
                                        .optionWords[connectionPairs.indexOf(
                                          index,
                                        )]
                                        .word ==
                                    widget.optionWords[rightIndex].word,
                            onTap: () => handleRightCardTap(index),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 연결 게임 카드 위젯
Widget buildConnectionCard(
  int index,
  String text, {
  required bool isLeftSide,
  required bool isSelected,
  required bool showResult,
  required bool isCorrectPair,
  required Function() onTap,
}) {
  // 결과에 따른 카드 색상
  Color cardColor = Colors.white;
  if (showResult) {
    cardColor = isCorrectPair ? Colors.green.shade100 : Colors.red.shade100;
  } else if (isSelected) {
    cardColor = AppColors.accent.withOpacity(0.1);
  }

  return GestureDetector(
    onTap: showResult ? null : onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isSelected
                  ? (isLeftSide ? AppColors.accent : Colors.orange)
                  : Colors.grey.withOpacity(0.3),
          width: isSelected ? 3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 단어 텍스트
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.quicksand(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          // 좌측 카드일 경우 선택 시 연결 아이콘 표시
          if (isLeftSide && isSelected && !showResult)
            Icon(Icons.arrow_forward, size: 16, color: AppColors.accent),
          // 결과 표시 (정답/오답)
          if (showResult)
            Icon(
              isCorrectPair ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: isCorrectPair ? Colors.green : Colors.red,
            ),
        ],
      ),
    ),
  );
}

/// 연결선 그리기를 위한 CustomPainter
class ConnectionLinePainter extends CustomPainter {
  final List<int?> connections;
  final Color color;

  ConnectionLinePainter({required this.connections, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = color
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    // 왼쪽 카드의 중앙 위치 (예시)
    List<double> leftPositions = [25, 85, 145, 205];
    // 오른쪽 카드의 중앙 위치 (예시)
    List<double> rightPositions = [25, 85, 145, 205];

    // 각 연결선 그리기
    for (int i = 0; i < connections.length; i++) {
      if (connections[i] != null) {
        final Offset start = Offset(0, leftPositions[i]);
        final Offset end = Offset(size.width, rightPositions[connections[i]!]);
        final Path path = Path();
        path.moveTo(start.dx, start.dy);
        final double controlX1 = size.width * 0.3;
        final double controlX2 = size.width * 0.7;
        path.cubicTo(controlX1, start.dy, controlX2, end.dy, end.dx, end.dy);
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
