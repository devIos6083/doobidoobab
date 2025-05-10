// Law tip model
class LawTip {
  final String id;
  final String title;
  final String summary;
  final String detailedContent;
  final String source;
  final String category;
  final List<String> relatedTipIds;
  final bool isBookmarked;

  LawTip({
    required this.id,
    required this.title,
    required this.summary,
    required this.detailedContent,
    this.source = '',
    this.category = '',
    this.relatedTipIds = const [],
    this.isBookmarked = false,
  });

  LawTip copyWith({
    String? id,
    String? title,
    String? summary,
    String? detailedContent,
    String? source,
    String? category,
    List<String>? relatedTipIds,
    bool? isBookmarked,
  }) {
    return LawTip(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      detailedContent: detailedContent ?? this.detailedContent,
      source: source ?? this.source,
      category: category ?? this.category,
      relatedTipIds: relatedTipIds ?? this.relatedTipIds,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }
}
