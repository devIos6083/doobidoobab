import 'dart:math';
import 'package:flutter/material.dart';

/// 카드 뒤집기 위젯
///
/// 앞면과 뒷면을 3D 애니메이션으로 전환할 수 있는 카드 위젯입니다.
class FlipCard extends StatefulWidget {
  /// 카드 앞면 위젯
  final Widget front;

  /// 카드 뒷면 위젯
  final Widget back;

  /// 카드 너비
  final double width;

  /// 카드 높이
  final double height;

  /// 카드 애니메이션 시간 (밀리초)
  final int animationDuration;

  /// 현재 카드가 뒤집힌 상태를 외부에서 제어할 수 있는 컨트롤러
  final FlipCardController? controller;

  const FlipCard({
    super.key,
    required this.front,
    required this.back,
    this.width = 300,
    this.height = 250,
    this.animationDuration = 400,
    this.controller,
  });

  @override
  _FlipCardState createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFrontSide = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: widget.animationDuration),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.controller != null) {
      widget.controller!._state = this;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 카드 뒤집기 함수
  void flip() {
    if (_isFrontSide) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    _isFrontSide = !_isFrontSide;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: flip,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001) // 원근감 추가
            ..rotateY(angle);

          // 카드가 반쯤 뒤집혔을 때 (90도) 내용 전환
          final showFrontSide = angle < pi / 2;

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: showFrontSide
                    ? widget.front
                    : Transform(
                        // 뒤집어진 텍스트를 다시 뒤집어서 보이게 함
                        transform: Matrix4.identity()..rotateY(pi),
                        alignment: Alignment.center,
                        child: widget.back,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 카드 뒤집기 컨트롤러
///
/// 카드의 뒤집기 상태를 외부에서 제어할 수 있는 컨트롤러입니다.
class FlipCardController {
  _FlipCardState? _state;

  /// 카드 뒤집기
  void flip() => _state?.flip();

  /// 카드를 앞면으로 설정
  void setFront() {
    if (_state != null && !_state!._isFrontSide) {
      _state!.flip();
    }
  }

  /// 카드를 뒷면으로 설정
  void setBack() {
    if (_state != null && _state!._isFrontSide) {
      _state!.flip();
    }
  }

  /// 현재 카드가 앞면인지 확인
  bool get isFrontSide => _state?._isFrontSide ?? true;
}
