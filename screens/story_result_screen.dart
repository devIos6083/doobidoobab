// screens/story_result_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'dart:typed_data';

import 'package:doobi/models/story_model.dart';
import 'package:doobi/utils/constants.dart';
import 'package:doobi/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StoryResultScreen extends StatefulWidget {
  final String word;
  final String story;
  final List<String>? storyImages; // 기존 호환성 유지
  final String? storyImage; // 단일 이미지 URL 추가
  final Uint8List? userDrawing;

  const StoryResultScreen({
    super.key,
    required this.word,
    required this.story,
    this.storyImages,
    this.storyImage, // 단일 이미지 URL 파라미터 추가
    this.userDrawing,
  });

  @override
  State<StoryResultScreen> createState() => _StoryResultScreenState();
}

class _StoryResultScreenState extends State<StoryResultScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<String> _storyPanels = [];

  @override
  void initState() {
    super.initState();
    // 스토리 텍스트를 패널별로 나누기
    _storyPanels = Story.parsePanels(widget.story);

    AppLogger.info('스토리 패널 ${_storyPanels.length}개 로드됨');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // comic_detail_screen.dart와 동일한 구조: 내가 그린 그림 + AI 이미지(있는 경우) + 장면들
    final int storyPanelsToShow =
        _storyPanels.length > 4 ? 4 : _storyPanels.length;
    // AI 이미지가 있는지 확인 (storyImage 또는 storyImages 첫 번째)
    final bool hasAIImage =
        widget.storyImage != null ||
        (widget.storyImages != null && widget.storyImages!.isNotEmpty);
    final int totalPages =
        storyPanelsToShow +
        (hasAIImage ? 2 : 1); // 내가 그린 그림 + AI 이미지(있다면) + 장면들

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryLight, AppColors.secondaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 헤더
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: AppColors.accent,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        '"${widget.word}" 스토리',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.quicksand(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.share_rounded,
                        color: AppColors.accent,
                      ),
                      onPressed: () {
                        // 공유 기능 구현
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('스토리 공유 준비중입니다.')),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // 페이지 표시기
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    totalPages,
                    (index) => Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _currentPage == index
                                ? AppColors.accent
                                : Colors.grey.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 스토리 패널 페이지 뷰
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    // 첫 페이지: 내가 그린 그림
                    _buildUserDrawingPanel(),

                    // 두 번째 페이지: AI 생성 이미지 (있는 경우에만)
                    if (hasAIImage) _buildStoryImagePanel(),

                    // 나머지 페이지: 장면 1~4
                    for (int i = 0; i < storyPanelsToShow; i++)
                      _buildStoryPanel(i),
                  ],
                ),
              ),

              // 하단 컨트롤
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 이전 버튼
                    ElevatedButton(
                      onPressed:
                          _currentPage > 0
                              ? () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent.withOpacity(0.8),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                      ),
                    ),

                    // 페이지 표시
                    Text(
                      '${_currentPage + 1}/$totalPages',
                      style: GoogleFonts.quicksand(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    // 다음 버튼
                    ElevatedButton(
                      onPressed:
                          _currentPage < totalPages - 1
                              ? () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent.withOpacity(0.8),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // 인생네컷 버튼 제거 (이제 첫 페이지가 네컷만화이므로)

              // 완료 버튼
              Padding(
                padding: const EdgeInsets.only(
                  bottom: 16.0,
                  left: 16.0,
                  right: 16.0,
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // 메인 화면으로 돌아가기 (모든 스택 제거)
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    '완료',
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // AI 생성 이미지 패널 (comic_detail_screen.dart와 동일한 구조)
  Widget _buildStoryImagePanel() {
    // 단일 이미지 URL 우선 사용, 없으면 storyImages 리스트의 첫 번째 이미지 시도
    final String? imageUrl =
        widget.storyImage ??
        (widget.storyImages != null && widget.storyImages!.isNotEmpty
            ? widget.storyImages![0]
            : null);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // 패널 헤더
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.image, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'AI가 생성한 "${widget.word}" 이미지',
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // 이미지 내용
          Expanded(
            child:
                imageUrl != null
                    ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            imageUrl.startsWith('file://')
                                ? Image.file(
                                  File(imageUrl.substring(7)), // 'file://' 제거
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    AppLogger.error(
                                      '이미지 로드 오류: $error',
                                      stackTrace,
                                    );
                                    return _buildErrorImage();
                                  },
                                )
                                : Image.network(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (
                                    context,
                                    child,
                                    loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                        color: AppColors.accent,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    AppLogger.error(
                                      '이미지 로드 오류: $error',
                                      stackTrace,
                                    );
                                    return _buildErrorImage();
                                  },
                                ),
                      ),
                    )
                    : const Center(child: Text('이미지를 불러올 수 없습니다.')),
          ),
        ],
      ),
    );
  }

  /// 이미지 로드 실패 시 표시할 위젯 (comic_detail_screen.dart와 동일)
  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey.withOpacity(0.2),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              '이미지를 불러올 수 없습니다.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  // 사용자 그림 패널
  Widget _buildUserDrawingPanel() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // 패널 헤더
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.brush, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '내가 그린 "${widget.word}"',
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // 그림 내용
          Expanded(
            child:
                widget.userDrawing != null
                    ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          widget.userDrawing!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    )
                    : const Center(child: Text('그림을 불러올 수 없습니다.')),
          ),
        ],
      ),
    );
  }

  // 스토리 패널 - 통일된 스타일 적용 (최대 4개만)
  Widget _buildStoryPanel(int panelIndex) {
    if (panelIndex >= _storyPanels.length || panelIndex >= 4)
      return Container();

    final storyText = _storyPanels[panelIndex];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // 패널 헤더
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_stories, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  '장면 ${panelIndex + 1}',
                  style: GoogleFonts.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // 텍스트 영역 - 통일된 스타일 적용
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0), // 패딩 증가
              child: Center(
                // 중앙 정렬 추가
                child: SingleChildScrollView(
                  child: Text(
                    storyText,
                    textAlign: TextAlign.center, // 텍스트 중앙 정렬
                    style: GoogleFonts.quicksand(
                      fontSize: 20, // 폰트 크기 증가 (16 → 20)
                      height: 1.6, // 줄 간격 약간 증가
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500, // 약간의 두께 추가
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
