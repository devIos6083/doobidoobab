// ignore_for_file: deprecated_member_use

import 'package:doobi/models/words.dart';
import 'package:doobi/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'flip_card.dart';

/// 단어 카드 위젯
///
/// 영어 단어를 앞면에, 한글 의미를 뒷면에 보여주는 뒤집을 수 있는 카드 위젯입니다.
class WordCard extends StatefulWidget {
  /// 표시할 단어 데이터
  final Word word;

  /// 애니메이션 트리거 (스케일 애니메이션)
  final Animation<double> animation;

  /// 힌트 보기 콜백
  final Function(bool) onHintToggled;

  /// 힌트 표시 여부
  final bool showHint;

  const WordCard({
    super.key,
    required this.word,
    required this.animation,
    required this.onHintToggled,
    required this.showHint,
  });

  @override
  _WordCardState createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> {
  // 카드 뒤집기 컨트롤러
  final FlipCardController _flipController = FlipCardController();

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: widget.animation,
      child: FlipCard(
        controller: _flipController,
        front: _buildFrontSide(),
        back: _buildBackSide(),
      ),
    );
  }

  /// 카드 앞면 (영어 단어) 위젯
  Widget _buildFrontSide() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, AppColors.primary.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Text(
                widget.word.word,
                style: GoogleFonts.quicksand(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // 힌트 버튼 & 내용
          if (widget.showHint)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lightbulb, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.word.hint ?? '',
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        color: Colors.grey[700],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            )
          else
            TextButton.icon(
              onPressed: () => widget.onHintToggled(true),
              icon: const Icon(Icons.lightbulb_outline, size: 18),
              label: const Text('힌트 보기'),
              style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
            ),
        ],
      ),
    );
  }

  /// 카드 뒷면 (한글 의미) 위젯
  Widget _buildBackSide() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, AppColors.primaryLight.withOpacity(0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.word.meaning,
                    style: GoogleFonts.quicksand(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Icon(
                    Icons.arrow_forward,
                    color: AppColors.accent.withOpacity(0.5),
                    size: 40,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '카드를 다시 탭하여 영어 단어 보기',
              style: GoogleFonts.quicksand(
                fontSize: 14,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
