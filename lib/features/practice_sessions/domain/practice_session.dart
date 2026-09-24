/// `03-PM-Planning/수어리 - 데이터 모델 (ERD)` 기준 PracticeSession 엔티티.
///
/// `comparisonSummary` 형태(DB에 `comparison_summary_shape` check 제약 있음, 최소
/// `version`/`algorithm`/`landmarkDeltas` 키 필수):
/// ```json
/// {
///   "version": 1,
///   "algorithm": "distance" | "dtw",
///   "referenceFrameIndex": 0,
///   "userTimestampMs": 0,
///   "handedness": "left" | "right",
///   "userLandmarks": [[x,y,z], ...],   // 21개
///   "landmarkDeltas": [0.02, ...],     // 21개
///   "weakestLandmarks": [8, 12, 16]
/// }
/// ```
class PracticeSession {
  const PracticeSession({
    required this.id,
    required this.userId,
    required this.wordId,
    required this.score,
    required this.comparisonSummary,
    required this.createdAt,
    this.retryOfSessionId,
  });

  final String id;
  final String userId;
  final String wordId;
  final int score;
  final Map<String, dynamic> comparisonSummary;
  final DateTime createdAt;
  final String? retryOfSessionId;

  List<int> get weakestLandmarks =>
      (comparisonSummary['weakestLandmarks'] as List?)?.cast<int>() ?? const [];

  factory PracticeSession.fromJson(Map<String, dynamic> json) => PracticeSession(
    id: json['id'] as String,
    userId: json['user_id'] as String,
    wordId: json['word_id'] as String,
    score: json['score'] as int,
    comparisonSummary: Map<String, dynamic>.from(json['comparison_summary'] as Map),
    createdAt: DateTime.parse(json['created_at'] as String),
    retryOfSessionId: json['retry_of_session_id'] as String?,
  );
}
