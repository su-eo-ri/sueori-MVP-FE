import 'package:scoring_poc/scoring_poc.dart';

import 'scoring_result.dart';
import 'word_type.dart';

/// `Word.type`에 따라 poc/scoring_poc에서 검증된 [DistanceScorer](정적) /
/// [DtwScorer](동적)로 라우팅하는 채점 서비스.
///
/// ERD 기준 `ReferenceLandmark.frames`는 static도 length=1인 프레임 시퀀스이므로,
/// 이 서비스는 정적/동적 구분 없이 항상 `List<List<Point3>>`(프레임 시퀀스)를
/// 입력으로 받는다 — static이면 첫 프레임만 사용.
class ScoringService {
  const ScoringService({
    this.staticScorer = const DistanceScorer(),
    this.dynamicScorer = const DtwScorer(),
  });

  final DistanceScorer staticScorer;
  final DtwScorer dynamicScorer;

  ScoringResult score({
    required WordType wordType,
    required List<List<Point3>> referenceFrames,
    required List<List<Point3>> candidateFrames,
  }) {
    // scoring_poc 테스트에서 발견된 버그: CosineScorer/DistanceScorer는 NaN
    // 좌표가 섞이면 만점(100)을 준다(Dart의 num.clamp가 NaN을 상한으로 취급).
    // MediaPipe가 손을 놓치면 이런 좌표가 나올 수 있으므로, 실시간 입력인
    // candidateFrames는 스코어러에 넘기기 전에 반드시 finite 여부를 검증한다.
    _assertFinite(candidateFrames, label: 'candidateFrames');
    _assertFinite(referenceFrames, label: 'referenceFrames');

    switch (wordType) {
      case WordType.staticSign:
        final referencePose = referenceFrames.first;
        final candidatePose = candidateFrames.first;
        return ScoringResult(score: staticScorer.score(referencePose, candidatePose));
      case WordType.dynamicSign:
        final result = dynamicScorer.score(referenceFrames, candidateFrames);
        return ScoringResult(
          score: result.score,
          avgAlignedCost: result.avgAlignedCost,
          pathLength: result.pathLength,
        );
    }
  }

  void _assertFinite(List<List<Point3>> frames, {required String label}) {
    for (final frame in frames) {
      for (final p in frame) {
        if (!p.x.isFinite || !p.y.isFinite || !p.z.isFinite) {
          throw ArgumentError(
            '$label에 NaN/Infinity 좌표가 섞여 있음 — 손 인식 실패로 추정, 채점 불가',
          );
        }
      }
    }
  }
}
