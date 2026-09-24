import 'dart:math' as math;

import 'landmark_distance.dart';
import 'normalize.dart';
import 'point3.dart';

/// 정적 수어(지문자) 채점기 — 코사인 유사도의 대안으로 검증하는 "거리 기반" 방식.
///
/// 이 PoC에서 [CosineScorer]가 서로 다른 손모양(예: 편 손 vs 주먹)도 90점대로
/// 채점하는 문제가 실측으로 확인됐다 (README 참고). 21개 랜드마크 중 손목과
/// MCP 관절 다수가 두 손모양에서 거의 그대로이기 때문에, 63차원 벡터 전체의
/// "방향"은 손가락 끝 몇 개가 크게 움직여도 별로 안 바뀐다 — 코사인 유사도가
/// 태생적으로 둔감한 구간.
///
/// 대안: 정규화된 랜드마크 간 평균 유클리드 거리를 지수 감쇠로 점수화.
/// DTW 채점기가 프레임 단위 비용으로 이미 쓰고 있는 방식과 동일해 일관성도 있다.
class DistanceScorer {
  /// 점수 감쇠 계수. 합성(synthetic) 테스트 데이터 기준으로 역산한 값:
  /// "아주 작은 노이즈"(관절당 평균 거리 ≈0.057)는 점수 90 근처, "완전히 다른
  /// 손모양"(관절당 평균 거리 ≈0.54)은 점수 34 근처가 나오도록 맞춘 값이다.
  /// 실사용 데이터로 재튜닝 필요(PRD 명시) — bin/debug_distances.dart 참고.
  final double decayFactor;

  const DistanceScorer({this.decayFactor = 2.0});

  /// 0~100 사이 점수를 반환한다.
  double score(List<Point3> reference, List<Point3> candidate) {
    final a = normalizeAndFlatten(reference);
    final b = normalizeAndFlatten(candidate);
    final distance = averageLandmarkDistance(a, b);
    return (100 * math.exp(-decayFactor * distance)).clamp(0, 100);
  }
}
