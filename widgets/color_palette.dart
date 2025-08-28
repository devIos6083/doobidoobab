// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

/// 색상 팔레트 위젯
class ColorPalette extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorSelected;

  const ColorPalette({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  // 사용 가능한 색상 목록
  static const List<Color> colors = [
    Colors.black,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.brown,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final color = colors[index];
          final isSelected = selectedColor.value == color.value;

          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.grey,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}