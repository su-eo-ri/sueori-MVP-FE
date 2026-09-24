import 'dart:math' as math;

import 'normalize.dart';
import 'point3.dart';

/// 정적 수어(지문자) 채점기 — 한 프레임(손모양) vs 정답 한 프레임을 비교한다.
///
/// PRD 5.1: "정적(지문자) = 코사인 유사도 → 0~100 점수"
class CosineScorer {
  const CosineScorer();

  /// 0~100 사이 점수를 반환한다. 100에 가까울수록 정답 손모양과 일치.
  double score(List<Point3> reference, List<Point3> candidate) {
    final a = normalizeAndFlatten(reference);
    final b = normalizeAndFlatten(candidate);
    final similarity = _cosineSimilarity(a, b).clamp(-1.0, 1.0);
    // 코사인 유사도는 이론상 [-1, 1]이지만, 정규화된 손 랜드마크끼리는
    // 완전히 반대 방향(-1)이 나오는 경우가 실질적으로 없다. 그래도 방어적으로
    // 전체 구간을 0~100에 선형 매핑한다.
    return ((similarity + 1) / 2 * 100).clamp(0, 100);
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    assert(a.length == b.length);
    var dot = 0.0, na = 0.0, nb = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    if (na < 1e-12 || nb < 1e-12) return 0.0;
    return dot / (math.sqrt(na) * math.sqrt(nb));
  }
}
