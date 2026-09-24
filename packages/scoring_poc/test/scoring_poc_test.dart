import 'package:flutter_test/flutter_test.dart';
import 'package:scoring_poc/scoring_poc.dart';

import 'synthetic_hand.dart';

void main() {
  group('CosineScorer — 정적 수어(지문자) 채점', () {
    const scorer = CosineScorer();

    test('정답과 완전히 동일한 손모양 → 만점에 가까운 점수', () {
      final score = scorer.score(openHandPose, openHandPose);
      expect(score, closeTo(100, 0.01));
    });

    test('아주 살짝 다른 손모양(노이즈) → 전역 통과 기준(80점) 이상', () {
      final noisy = withNoise(openHandPose, 0.01, 0);
      final score = scorer.score(openHandPose, noisy);
      // PRD: 전역 기본값 80점 = "이 정도 오차는 통과시켜야 한다"는 실사용 기준.
      expect(score, greaterThanOrEqualTo(80));
    });

    test(
      '[PoC 발견] 완전히 다른 손모양(주먹 vs 편 손)인데도 코사인 유사도는 '
      '여전히 높은 점수를 준다 → 정적 채점에 코사인 유사도 단독 사용은 부적합',
      () {
        final score = scorer.score(openHandPose, fistPose);
        // 기대와 반대되는 결과를 의도적으로 문서화한다: 21개 랜드마크 중
        // 손목+5개 MCP(=63차원 중 18차원)가 두 손모양에서 완전히 동일해서,
        // 손끝이 크게 움직여도 전체 벡터의 "방향"은 별로 안 바뀐다.
        // → 아래 DistanceScorer 비교 테스트가 실제 채점에 쓸 대안을 보여준다.
        expect(
          score,
          greaterThan(90),
          reason:
              '이 값이 낮아졌다면 코사인 유사도 구현이 바뀐 것이니 이 문서화 자체를 '
              '재검토할 것. 현재(PoC 단계) 결론: 코사인 유사도는 정적 채점에 그대로 '
              '쓰기엔 판별력이 부족함. score=$score',
        );
      },
    );

    test('손의 화면상 위치/카메라와의 거리는 점수에 영향 없음(정규화 검증)', () {
      // 같은 손모양을 화면 오른쪽 아래로 평행이동 + 2배 확대만 한 버전.
      final shiftedAndScaled = [
        for (final p in openHandPose)
          Point3(p.x * 2 + 0.3, p.y * 2 + 0.1, p.z * 2),
      ];
      final score = scorer.score(openHandPose, shiftedAndScaled);
      expect(score, closeTo(100, 0.01));
    });
  });

  group('DistanceScorer — 코사인 유사도의 대안 검증', () {
    const scorer = DistanceScorer();

    test('정답과 완전히 동일한 손모양 → 만점에 가까운 점수', () {
      final score = scorer.score(openHandPose, openHandPose);
      expect(score, closeTo(100, 0.01));
    });

    test('아주 살짝 다른 손모양(노이즈) → 전역 통과 기준(80점) 이상', () {
      final noisy = withNoise(openHandPose, 0.01, 0);
      final score = scorer.score(openHandPose, noisy);
      expect(score, greaterThanOrEqualTo(80));
    });

    test(
      '[코사인과 대조] 완전히 다른 손모양(주먹 vs 편 손) → 뚜렷하게 낮은 점수 '
      '(코사인 유사도는 같은 입력에 90점대를 줬음)',
      () {
        final score = scorer.score(openHandPose, fistPose);
        expect(score, lessThan(50));
      },
    );

    test('손의 화면상 위치/카메라와의 거리는 점수에 영향 없음(정규화 검증)', () {
      final shiftedAndScaled = [
        for (final p in openHandPose)
          Point3(p.x * 2 + 0.3, p.y * 2 + 0.1, p.z * 2),
      ];
      final score = scorer.score(openHandPose, shiftedAndScaled);
      expect(score, closeTo(100, 0.01));
    });
  });

  group('DtwScorer — 동적 수어(단어) 채점', () {
    const scorer = DtwScorer();

    test('정답과 동일한 시퀀스(같은 프레임 수) → 만점에 가까운 점수', () {
      final reference = triangularWaveSequence(10);
      final result = scorer.score(reference, reference);
      expect(result.score, closeTo(100, 0.5));
    });

    test(
      '같은 동작을 다른 속도로(더 많은 프레임으로) 수행 → DTW는 여전히 높은 점수 '
      '(시간축 정렬로 속도 차이를 흡수하는지가 이 PoC의 핵심 검증 포인트)',
      () {
        final reference = triangularWaveSequence(10);
        final slowerCandidate = triangularWaveSequenceResampled(23);
        final result = scorer.score(reference, slowerCandidate);
        expect(
          result.score,
          greaterThanOrEqualTo(80),
          reason:
              '동작 모양(fist→open→fist)은 동일하고 속도만 다른데 낮은 점수가 나오면 '
              'DTW를 쓰는 의미가 없다. score=${result.score}',
        );
      },
    );

    test('모양 자체가 다른 동작(펼치기만 하고 다시 안 쥠) → 눈에 띄게 낮은 점수', () {
      final reference = triangularWaveSequence(10);
      final different = monotonicOpenSequence(10);
      final result = scorer.score(reference, different);
      expect(result.score, lessThan(80));
    });

    test(
      '"모양은 같은데 속도만 다른 경우" 점수가 "모양이 다른 경우" 점수보다 뚜렷하게 높다',
      () {
        final reference = triangularWaveSequence(10);
        final sameShapeDifferentSpeed = triangularWaveSequenceResampled(23);
        final differentShape = monotonicOpenSequence(10);

        final sameShapeScore =
            scorer.score(reference, sameShapeDifferentSpeed).score;
        final differentShapeScore =
            scorer.score(reference, differentShape).score;

        expect(sameShapeScore, greaterThan(differentShapeScore));
      },
    );

    test('빈 시퀀스 입력 시 크래시 없이 0점 처리', () {
      final result = scorer.score([], triangularWaveSequence(5));
      expect(result.score, 0);
    });
  });
}
