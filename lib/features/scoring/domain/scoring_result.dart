/// [ScoringService.score]의 결과. 정적/동적 채점 방식이 달라도 화면에서는
/// 동일한 형태로 다룰 수 있도록 통일한 값 객체.
class ScoringResult {
  const ScoringResult({required this.score, this.avgAlignedCost, this.pathLength});

  /// 0~100 점수.
  final double score;

  /// DTW(동적) 채점일 때만 채워짐 — 디버깅/튜닝용.
  final double? avgAlignedCost;

  /// DTW(동적) 채점일 때만 채워짐 — 디버깅/튜닝용.
  final int? pathLength;
}
