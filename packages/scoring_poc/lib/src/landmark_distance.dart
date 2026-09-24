import 'dart:math' as math;

/// 정규화된 랜드마크 벡터(63차원 = 21개 랜드마크 * xyz) 두 개를 받아
/// **랜드마크당 평균 3D 유클리드 거리**를 반환한다.
///
/// 63차원 전체에 대한 단일 유클리드 노름(sqrt of sum of squares)을 그대로 쓰면
/// 랜드마크 개수가 늘어날수록 거리 값 자체가 커지는 부작용이 있어, 감쇠계수를
/// 몇으로 잡아야 "적당한 오차"와 "명백히 다른 손모양"을 가르는지 가늠하기 어렵다.
/// "관절 하나가 평균적으로 얼마나 벗어났는가"로 바꾸면 랜드마크 개수와 무관한,
/// 해석 가능한 척도가 된다 (예: 0.05 = 관절들이 평균적으로 손 크기의 5%만큼 벗어남).
double averageLandmarkDistance(List<double> a, List<double> b) {
  assert(a.length == b.length && a.length % 3 == 0);
  final landmarkCount = a.length ~/ 3;
  if (landmarkCount == 0) return 0;
  var sum = 0.0;
  for (var i = 0; i < landmarkCount; i++) {
    final dx = a[i * 3] - b[i * 3];
    final dy = a[i * 3 + 1] - b[i * 3 + 1];
    final dz = a[i * 3 + 2] - b[i * 3 + 2];
    sum += math.sqrt(dx * dx + dy * dy + dz * dz);
  }
  return sum / landmarkCount;
}
