/// `03-PM-Planning/수어리 - 데이터 모델 (ERD)` 기준 Category 엔티티.
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.sortOrder,
    required this.isFreeTier,
    this.passThreshold,
  });

  final String id;
  final String name;
  final String slug;
  final int sortOrder;

  /// true면 비로그인 게스트도 채점 가능한 "기초" 카테고리(PRD §5.1).
  final bool isFreeTier;

  /// null이면 전역 기본값(80점) 사용.
  final int? passThreshold;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'] as String,
    name: json['name'] as String,
    slug: json['slug'] as String,
    sortOrder: json['sort_order'] as int,
    isFreeTier: json['is_free_tier'] as bool,
    passThreshold: json['pass_threshold'] as int?,
  );
}
