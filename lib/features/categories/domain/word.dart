import '../../scoring/domain/word_type.dart';

/// `03-PM-Planning/수어리 - 데이터 모델 (ERD)` 기준 Word 엔티티.
class Word {
  const Word({
    required this.id,
    required this.categoryId,
    required this.term,
    required this.type,
    required this.sortOrder,
    this.thumbnailAsset,
  });

  final String id;
  final String categoryId;
  final String term;
  final WordType type;
  final int sortOrder;
  final String? thumbnailAsset;

  factory Word.fromJson(Map<String, dynamic> json) => Word(
    id: json['id'] as String,
    categoryId: json['category_id'] as String,
    term: json['term'] as String,
    type: WordType.fromDbValue(json['type'] as String),
    sortOrder: json['sort_order'] as int,
    thumbnailAsset: json['thumbnail_asset'] as String?,
  );
}
