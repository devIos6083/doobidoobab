// screens/comic_detail_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:doobi/models/story_model.dart';
import 'package:doobi/utils/constants.dart';
import 'package:doobi/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

/// 만화 상세 보기 화면
class ComicDetailScreen extends StatefulWidget {
  final Story story;

  const ComicDetailScreen({super.key, required this.story});

  @override
  _ComicDetailScreenState createState() => _ComicDetailScreenState();
}

class _ComicDetailScreenState extends State<ComicDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late List<String> _panels;

  @override
  void initState() {
    super.initState();
    // 스토리 패널 초기화
    _panels = widget.story.panels;
    AppLogger.info('만화 상세 보기: ${_panels.length}개의 패널 로드됨');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 스토리 공유 기능
  Future<void> _shareStory() async {
    try {
      // 임시 파일로 텍스트 저장
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${widget.story.word}_story.txt');

      // 스토리 텍스트 구성
      final storyText = '''
제목: ${widget.story.word} 스토리
날짜: ${DateFormat('yyyy년 MM월 dd일').format(widget.story.createdAt)}

${widget.story.storyText}
''';

      await file.writeAsString(storyText);

      // 이미지와 텍스트 파일 함께 공유
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '두비 앱에서 만든 "${widget.story.word}" 스토리를 공유합니다!',
        subject: '두비 - ${widget.story.word} 스토리',
      );

      AppLogger.info('스토리 공유 완료: ${widget.story.word}');
    } catch (e) {
      AppLogger.error('스토리 공유 중 오류', e);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('스토리 공유 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 뒤로가기 버튼
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: AppColors.accent,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),

                  // 제목
                  Expanded(
                    child: Text(
                      '"${widget.story.word}" 스토리',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accent,
                      ),
                    ),
                  ),

                  // 공유 버튼
                  IconButton(
                    icon: Icon(Icons.share_rounded, color: AppColors.accent),
                    onPressed: _shareStory,
                  ),
                ],
              ),
            ),

            // 생성 날짜 표시
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                '생성일: ${DateFormat('yyyy년 MM월 dd일').format(widget.story.createdAt)}',
                style: GoogleFonts.quicksand(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

            SizedBox(height: 8),

            // 페이지 인디케이터
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _getTotalPages(),
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

            SizedBox(height: 16),

            // 스토리 콘텐츠
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  // 사용자 그림 페이지
                  _buildUserDrawingPanel(),

                  // AI 생성 이미지 페이지 (있는 경우)
                  if (widget.story.imageUrl != null) _buildStoryImagePanel(),

                  // 스토리 패널 페이지들
                  for (int i = 0; i < _panels.length; i++) _buildStoryPanel(i),
                ],
              ),
            ),

            // 페이지 컨트롤 버튼
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
                    '${_currentPage + 1}/${_getTotalPages()}',
                    style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  // 다음 버튼
                  ElevatedButton(
                    onPressed:
                        _currentPage < _getTotalPages() - 1
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
          ],
        ),
      ),
    );
  }

  /// 총 페이지 수 계산
  int _getTotalPages() {
    // 사용자 그림 + AI 이미지(있다면) + 스토리 패널 수
    return _panels.length + (widget.story.imageUrl != null ? 2 : 1);
  }

  /// 사용자 그림 패널
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
                  '내가 그린 "${widget.story.word}"',
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
                widget.story.userDrawing != null
                    ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Hero(
                          tag: 'story_image_${widget.story.word}',
                          child: Image.memory(
                            widget.story.userDrawing!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    )
                    : const Center(child: Text('그림을 불러올 수 없습니다.')),
          ),
        ],
      ),
    );
  }

  /// AI 생성 이미지 패널
  Widget _buildStoryImagePanel() {
    final String? imageUrl = widget.story.imageUrl;

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
                  'AI가 생성한 "${widget.story.word}" 이미지',
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

  /// 스토리 패널
  Widget _buildStoryPanel(int panelIndex) {
    if (panelIndex >= _panels.length) return Container();

    final storyText = _panels[panelIndex];

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

  /// 이미지 로드 실패 시 표시할 위젯
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
}
