// screens/comic_gallery_screen.dart
// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:doobi/models/story_model.dart';
import 'package:doobi/screens/comic_detail_screen.dart';
import 'package:doobi/services/story_storage_service.dart';
import 'package:doobi/utils/constants.dart';
import 'package:doobi/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

/// 만화방 (스토리 갤러리) 화면
class ComicGalleryScreen extends StatefulWidget {
  const ComicGalleryScreen({super.key});

  @override
  _ComicGalleryScreenState createState() => _ComicGalleryScreenState();
}

class _ComicGalleryScreenState extends State<ComicGalleryScreen> {
  final StoryStorageService _storyStorage = StoryStorageService();
  List<Story> _stories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStories();
  }

  /// 저장된 스토리 목록 불러오기
  Future<void> _loadStories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stories = await _storyStorage.loadStoryList();

      // 최신순으로 정렬
      stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _stories = stories;
        _isLoading = false;
      });

      AppLogger.info('만화방: ${stories.length}개의 스토리 로드됨');
    } catch (e) {
      AppLogger.error('만화방: 스토리 로드 중 오류', e);

      setState(() {
        _stories = [];
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('스토리를 불러오는 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 스토리 삭제 처리
  Future<void> _deleteStory(Story story) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('스토리 삭제'),
            content: Text('정말 "${story.word}" 스토리를 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('취소'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('삭제', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        final result = await _storyStorage.deleteStory(story.word);

        if (result) {
          setState(() {
            _stories.removeWhere((s) => s.word == story.word);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('스토리가 삭제되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('스토리 삭제에 실패했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        AppLogger.error('스토리 삭제 중 오류', e);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('스토리 삭제 중 오류가 발생했습니다.'),
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
      appBar: AppBar(
        title: Text(
          '만화방',
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // 새로고침 버튼
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: _loadStories,
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _stories.isEmpty
              ? _buildEmptyState()
              : _buildStoryGrid(),
    );
  }

  /// 빈 화면 위젯
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.collections_bookmark,
            size: 80,
            color: Colors.grey.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            '아직 생성된 스토리가 없습니다.',
            style: GoogleFonts.quicksand(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '게임방에서 그림을 그리고 스토리를 만들어보세요!',
            style: GoogleFonts.quicksand(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.brush),
            label: Text('게임 하러가기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 스토리 그리드 위젯
  Widget _buildStoryGrid() {
    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _stories.length,
      itemBuilder: (context, index) {
        final story = _stories[index];
        return _buildStoryCard(story);
      },
    );
  }

  /// 스토리 카드 위젯
  Widget _buildStoryCard(Story story) {
    // 이미지 소스 결정 (사용자 그림 또는 AI 생성 이미지)
    Widget imageWidget;

    if (story.userDrawing != null) {
      // 사용자 그림 표시
      imageWidget = Image.memory(
        story.userDrawing!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorImage();
        },
      );
    } else if (story.imageUrl != null) {
      // AI 생성 이미지 표시
      final String imageUrl = story.imageUrl!;

      if (imageUrl.startsWith('file://')) {
        // 로컬 파일 경로인 경우
        final filePath = imageUrl.substring(7); // 'file://' 제거
        imageWidget = Image.file(
          File(filePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorImage();
          },
        );
      } else {
        // 네트워크 URL인 경우
        imageWidget = Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorImage();
          },
        );
      }
    } else {
      // 이미지가 없는 경우
      imageWidget = _buildErrorImage();
    }

    return GestureDetector(
      onTap: () {
        // 상세 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ComicDetailScreen(story: story),
          ),
        ).then((_) {
          // 돌아왔을 때 상태 업데이트를 위해 스토리 다시 로드
          _loadStories();
        });
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 이미지 영역
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Hero(
                      tag: 'story_image_${story.word}',
                      child: imageWidget,
                    ),
                  ),
                ),

                // 텍스트 영역 - 높이 제약 조정
                Container(
                  height: 60, // 고정 높이 설정
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min, // 내용물에 맞게 최소 크기로 변경
                    children: [
                      // 단어
                      Text(
                        story.word,
                        style: GoogleFonts.quicksand(
                          fontSize: 16, // 폰트 크기 약간 축소
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(height: 4), // 여백 축소
                      // 날짜
                      Text(
                        DateFormat('yyyy.MM.dd').format(story.createdAt),
                        style: GoogleFonts.quicksand(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // 삭제 버튼
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _deleteStory(story),
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 이미지 로드 실패 시 표시할 위젯
  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey.withOpacity(0.2),
      child: Center(
        child: Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
      ),
    );
  }
}
