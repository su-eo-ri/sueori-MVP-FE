/// `03-PM-Planning/수어리 - 데이터 모델 (ERD)` 기준 Favorite 엔티티.
enum FavoriteSource {
  /// 사용자가 직접 추가.
  manual,

  /// 기준(passThreshold) 미달로 시스템이 자동 추가.
  autoLowScore;

  static FavoriteSource fromDbValue(String value) => switch (value) {
    'manual' => FavoriteSource.manual,
    'auto_low_score' => FavoriteSource.autoLowScore,
    _ => throw ArgumentError('알 수 없는 Favorite.source 값: $value'),
  };

  String get dbValue => switch (this) {
    FavoriteSource.manual => 'manual',
    FavoriteSource.autoLowScore => 'auto_low_score',
  };
}

class Favorite {
  const Favorite({
    required this.id,
    required this.userId,
    required this.wordId,
    required this.source,
    required this.addedAt,
    this.resolvedAt,
  });

  final String id;
  final String userId;
  final String wordId;
  final FavoriteSource source;
  final DateTime addedAt;

  /// 재도전으로 기준 이상 달성 시 기록. null이면 아직 미해결(오답노트에 남아있음).
  final DateTime? resolvedAt;

  factory Favorite.fromJson(Map<String, dynamic> json) => Favorite(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    wordId: json['word_id'] as String,
    source: FavoriteSource.fromDbValue(json['source'] as String),
    addedAt: DateTime.parse(json['added_at'] as String),
    resolvedAt: json['resolved_at'] == null ? null : DateTime.parse(json['resolved_at'] as String),
  );
}
