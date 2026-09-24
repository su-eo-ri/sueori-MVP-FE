// scoring_poc 엣지 케이스 테스트 — 기존 scoring_poc_test.dart(13개, 정상 경로 위주)를
// 보완한다. 여기는 입력 검증, 비정상 값(NaN/Infinity), 경계값, 극단적인 시퀀스
// 길이 차이를 다룬다. 새 스코어러/정규화 로직을 만들지 않고, 기존 공개 API만 호출한다.

import 'package:flutter_test/flutter_test.dart';
import 'package:scoring_poc/scoring_poc.dart';

import 'synthetic_hand.dart';

void main() {
  group('normalizeAndFlatten — 랜드마크 개수 검증', () {
    test('21개 미만이면 assert로 막힌다', () {
      final tooFew = openHandPose.sublist(0, 5);
      expect(() => normalizeAndFlatten(tooFew), throwsA(isA<AssertionError>()));
    });

    test('21개 초과면 assert로 막힌다', () {
      final tooMany = [...openHandPose, openHandPose.last];
      expect(() => normalizeAndFlatten(tooMany), throwsA(isA<AssertionError>()));
    });
  });

  group('[알려진 한계] NaN/Infinity 좌표를 스코어러가 감지하지 못한다', () {
    // 실제 MediaPipe가 손을 놓쳐서 좌표가 NaN/Infinity로 나올 가능성 자체는 이
    // PoC 범위 밖(hand_landmark_poc가 다룸)이지만, "만약 그런 값이 들어온다면
    // 스코어러가 안전하게 낮은 점수를 주는가"는 이 패키지가 보장해야 할 계약이다.
    // 아래 두 테스트는 그 계약이 지금은 깨져 있다는 걸 문서화한다: Dart의
    // `num.clamp(lo, hi)`는 값이 NaN이면 **upper bound를 반환**하기 때문에
    // (dot/na/nb가 NaN → similarity/거리 계산이 NaN → clamp가 1.0 또는 100을
    // 반환), NaN이 섞인 입력이 오히려 "완벽히 일치"로 채점된다.
    //
    // 프로덕션 이식 시 랜드마크 입력 단계에서 NaN/Infinite 방어 검증(예:
    // `landmarks.any((p) => !p.x.isFinite || !p.y.isFinite || !p.z.isFinite)`)을
    // 추가해서 이런 입력 자체를 거부하거나 0점 처리해야 한다 — 이 스코어러들
    // 내부 로직만으로는 안전하지 않다.

    test('CosineScorer: 랜드마크 1개가 NaN이어도 100점을 준다 (버그, 의도 아님)', () {
      final nanPose = [
        for (var i = 0; i < openHandPose.length; i++)
          i == 8
              ? Point3(double.nan, openHandPose[i].y, openHandPose[i].z)
              : openHandPose[i],
      ];
      final score = const CosineScorer().score(openHandPose, nanPose);
      expect(
        score,
        100.0,
        reason:
            'num.clamp(NaN, -1, 1)이 upper bound(1.0)를 반환하는 Dart 동작에 '
            '기인함. 이 값이 100이 아니게 바뀌었다면 clamp 동작이 바뀐 것이니 '
            '재검토하고, NaN 방어 로직을 추가한 뒤엔 이 테스트를 "낮은 점수를 '
            '준다"로 뒤집을 것.',
      );
    });

    test('DistanceScorer: 랜드마크 1개가 NaN이어도 100점을 준다 (버그, 의도 아님)', () {
      final nanPose = [
        for (var i = 0; i < openHandPose.length; i++)
          i == 8
              ? Point3(double.nan, openHandPose[i].y, openHandPose[i].z)
              : openHandPose[i],
      ];
      final score = const DistanceScorer().score(openHandPose, nanPose);
      expect(
        score,
        100.0,
        reason: '위 CosineScorer 테스트와 동일한 원인(num.clamp(NaN, 0, 100) '
            '= 100). 두 스코어러 다 NaN 방어가 없다는 뜻.',
      );
    });

    test(
      'DistanceScorer: 랜드마크 1개가 Infinity면 반대로 0점을 준다 '
      '(NaN과 정반대 — "비정상 입력" 처리가 일관되지 않음)',
      () {
        final infPose = [
          for (var i = 0; i < openHandPose.length; i++)
            i == 8
                ? Point3(double.infinity, openHandPose[i].y, openHandPose[i].z)
                : openHandPose[i],
        ];
        final score = const DistanceScorer().score(openHandPose, infPose);
        expect(
          score,
          0.0,
          reason: 'exp(-decayFactor * Infinity) = 0이라 여기선 "우연히" 안전한 '
              '방향으로 떨어지지만, 같은 "비정상 좌표" 범주인 NaN은 반대로 100점을 '
              '주므로 입력 검증이 일관되게 설계된 게 아니라는 걸 보여준다.',
        );
      },
    );
  });

  group('DistanceScorer — 80점 통과 기준 경계', () {
    test('노이즈가 커질수록 점수는 단조 감소한다', () {
      const magnitudes = [0.0, 0.01, 0.02, 0.05, 0.1, 0.15];
      final scores = [
        for (final m in magnitudes)
          const DistanceScorer()
              .score(openHandPose, withNoise(openHandPose, m, 0)),
      ];
      for (var i = 1; i < scores.length; i++) {
        expect(
          scores[i],
          lessThan(scores[i - 1]),
          reason: 'noise=${magnitudes[i]} 점수(${scores[i]})가 '
              'noise=${magnitudes[i - 1]} 점수(${scores[i - 1]})보다 낮아야 함',
        );
      }
    });

    test('noise=0.018과 0.02 사이에서 실제로 80점 기준을 넘나든다', () {
      // 사전에 dart run으로 실측: mag=0.018 -> 81.57점, mag=0.02 -> 79.81점.
      final justAbove = const DistanceScorer()
          .score(openHandPose, withNoise(openHandPose, 0.018, 0));
      final justBelow = const DistanceScorer()
          .score(openHandPose, withNoise(openHandPose, 0.02, 0));
      expect(justAbove, greaterThanOrEqualTo(80));
      expect(justBelow, lessThan(80));
    });
  });

  group('DtwScorer — 극단적인 프레임 길이 차이', () {
    test('1프레임 정답 vs 100프레임(전부 동일 포즈) 후보 → 완벽 정렬로 만점', () {
      final reference = [openHandPose];
      final candidate = List.generate(100, (_) => openHandPose);
      final result = const DtwScorer().score(reference, candidate);
      expect(result.score, closeTo(100, 0.5));
      expect(result.pathLength, 100);
    });

    test('10프레임 정답을 100프레임(10배)으로 리샘플링해도 여전히 통과 기준(80점) 이상', () {
      final reference = triangularWaveSequence(10);
      final candidate = resampleSequence(reference, 100);
      final result = const DtwScorer().score(reference, candidate);
      expect(
        result.score,
        greaterThanOrEqualTo(80),
        reason: '기존 테스트는 10→23프레임(≈2.3배) 속도 차이까지만 검증했다. '
            '10배까지 극단적으로 벌려도 DTW가 흡수하는지 확인. '
            'score=${result.score}',
      );
    });
  });
}
