import 'dart:math' as math;

import 'landmark_distance.dart';
import 'normalize.dart';
import 'point3.dart';

/// DTW(Dynamic Time Warping) 채점 결과.
class DtwResult {
  /// 0~100 점수. 100에 가까울수록 정답 동작과 일치.
  final double score;

  /// 정렬 경로 길이로 나눈 평균 정렬 비용(정규화된 랜드마크 공간 거리). 디버깅/튜닝용.
  final double avgAlignedCost;

  /// 최적 정렬 경로 길이(참고용).
  final int pathLength;

  const DtwResult({
    required this.score,
    required this.avgAlignedCost,
    required this.pathLength,
  });

  @override
  String toString() =>
      'DtwResult(score: ${score.toStringAsFixed(1)}, '
      'avgAlignedCost: ${avgAlignedCost.toStringAsFixed(4)}, '
      'pathLength: $pathLength)';
}

/// 동적 수어(단어) 채점기 — 프레임 시퀀스 vs 정답 시퀀스를 비교한다.
///
/// PRD 5.1: "동적(단어) = DTW → 0~100 점수"
///
/// 왜 프레임별 코사인 유사도의 단순 평균이 아니라 DTW인가:
/// 사용자가 정답 시연보다 느리게/빠르게 따라 하거나, 동작 중간에 살짝 머뭇거려도
/// "같은 동작을 다른 속도로 했을 뿐"이라면 채점에서 불리해지면 안 된다.
/// DTW는 두 시퀀스의 프레임 수가 달라도 최적의 시간축 정렬(warping)을 찾아
/// 비교하므로, 속도 차이에 강건하다. 이 PoC의 핵심 검증 포인트가 바로 이 부분.
class DtwScorer {
  /// 점수 감쇠 계수. 정규화된 랜드마크 공간에서 프레임당 평균 정렬 비용이 클수록
  /// 점수가 0에 가깝게 지수적으로 감쇠한다. 실사용 데이터로 튜닝 예정(PRD 명시).
  ///
  /// [DistanceScorer]와 같은 "랜드마크당 평균 거리" 척도를 쓰지만 **같은
  /// decayFactor를 그대로 재사용할 수 없다는 것이 PoC에서 확인됐다**: DTW는
  /// 최적 정렬을 찾도록 설계돼 있어서, 완전히 다른 두 동작을 비교해도
  /// 프레임 단위 최선의 정렬 비용은 "완전히 다른 한 프레임끼리의 거리"보다
  /// 체계적으로 작게 나온다. 정적 채점과 같은 계수(≈2.0)를 그대로 쓰면
  /// 명백히 다른 동작도 80점을 넘겨버려 채점이 무의미해진다 — 그래서 더 큰
  /// 계수(≈6.5)로 별도 보정했다. bin/debug_distances.dart 참고.
  final double decayFactor;

  const DtwScorer({this.decayFactor = 6.5});

  DtwResult score(
    List<List<Point3>> reference,
    List<List<Point3>> candidate,
  ) {
    final a = reference.map(normalizeAndFlatten).toList();
    final b = candidate.map(normalizeAndFlatten).toList();
    final n = a.length;
    final m = b.length;
    if (n == 0 || m == 0) {
      return const DtwResult(
        score: 0,
        avgAlignedCost: double.infinity,
        pathLength: 0,
      );
    }

    // dp[i][j] = a[0..i) 와 b[0..j) 사이 최소 누적 정렬 비용
    final dp = List.generate(
      n + 1,
      (_) => List<double>.filled(m + 1, double.infinity),
    );
    dp[0][0] = 0;
    for (var i = 1; i <= n; i++) {
      for (var j = 1; j <= m; j++) {
        final cost = averageLandmarkDistance(a[i - 1], b[j - 1]);
        final prevMin = math.min(
          dp[i - 1][j],
          math.min(dp[i][j - 1], dp[i - 1][j - 1]),
        );
        dp[i][j] = cost + prevMin;
      }
    }

    final pathLength = _backtrackPathLength(dp, n, m);
    final totalCost = dp[n][m];
    final avgCost = totalCost / pathLength;

    final rawScore = 100 * math.exp(-decayFactor * avgCost);
    return DtwResult(
      score: rawScore.clamp(0, 100),
      avgAlignedCost: avgCost,
      pathLength: pathLength,
    );
  }

  int _backtrackPathLength(List<List<double>> dp, int n, int m) {
    var i = n, j = m, pathLength = 0;
    while (i > 0 || j > 0) {
      pathLength++;
      if (i == 0) {
        j--;
      } else if (j == 0) {
        i--;
      } else {
        final diag = dp[i - 1][j - 1];
        final up = dp[i - 1][j];
        final left = dp[i][j - 1];
        final minVal = math.min(diag, math.min(up, left));
        if (minVal == diag) {
          i--;
          j--;
        } else if (minVal == up) {
          i--;
        } else {
          j--;
        }
      }
    }
    return pathLength;
  }
}
