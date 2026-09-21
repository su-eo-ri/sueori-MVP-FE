// ScoringService의 라우팅 로직(static→DistanceScorer, dynamic→DtwScorer)만
// 검증한다. 채점 알고리즘 자체(코사인 부적합, decayFactor 등)는 poc/scoring_poc의
// 테스트가 이미 검증했으므로 여기서 재검증하지 않는다.

import 'package:flutter_test/flutter_test.dart';
import 'package:scoring_poc/scoring_poc.dart';
import 'package:sueori/features/scoring/domain/scoring_service.dart';
import 'package:sueori/features/scoring/domain/word_type.dart';

List<Point3> _samplePose({double offset = 0}) => List.generate(
  21,
  (i) => Point3(0.1 * i + offset, 0.2 * i + offset, 0.05 * i + offset),
);

void main() {
  group('WordType.fromDbValue', () {
    test('static/dynamic 문자열을 올바르게 매핑한다', () {
      expect(WordType.fromDbValue('static'), WordType.staticSign);
      expect(WordType.fromDbValue('dynamic'), WordType.dynamicSign);
    });

    test('알 수 없는 값이면 예외를 던진다', () {
      expect(() => WordType.fromDbValue('unknown'), throwsArgumentError);
    });
  });

  group('ScoringService', () {
    const service = ScoringService();

    test('static이면 첫 프레임만으로 DistanceScorer 결과를 낸다 (동일 포즈 → 만점)', () {
      final pose = _samplePose();
      final result = service.score(
        wordType: WordType.staticSign,
        referenceFrames: [pose],
        candidateFrames: [pose],
      );

      expect(result.score, closeTo(100, 0.01));
      // static은 DTW 전용 디버그 필드가 채워지지 않는다.
      expect(result.avgAlignedCost, isNull);
      expect(result.pathLength, isNull);
    });

    test('dynamic이면 프레임 시퀀스 전체로 DtwScorer 결과를 낸다 (동일 시퀀스 → 만점 + 디버그 필드 포함)', () {
      final sequence = [_samplePose(), _samplePose(offset: 0.01), _samplePose(offset: 0.02)];
      final result = service.score(
        wordType: WordType.dynamicSign,
        referenceFrames: sequence,
        candidateFrames: sequence,
      );

      expect(result.score, closeTo(100, 0.01));
      expect(result.avgAlignedCost, isNotNull);
      expect(result.pathLength, isNotNull);
    });

    test('static과 dynamic은 서로 다른 스코어러로 라우팅된다 (동일 입력이라도 결과 구조가 다름)', () {
      final pose = _samplePose();

      final staticResult = service.score(
        wordType: WordType.staticSign,
        referenceFrames: [pose],
        candidateFrames: [pose],
      );
      final dynamicResult = service.score(
        wordType: WordType.dynamicSign,
        referenceFrames: [pose],
        candidateFrames: [pose],
      );

      expect(staticResult.avgAlignedCost, isNull);
      expect(dynamicResult.avgAlignedCost, isNotNull);
    });

    test('candidateFrames에 NaN 좌표가 섞이면 만점 대신 예외를 던진다', () {
      // poc/scoring_poc의 edge_cases_test.dart에서 발견된 버그(NaN이 clamp의
      // 상한으로 취급돼 만점 처리됨)를 이 서비스 레이어에서 막고 있는지 검증.
      final pose = _samplePose();
      final noisyPose = [
        Point3(double.nan, pose[0].y, pose[0].z),
        ...pose.sublist(1),
      ];

      expect(
        () => service.score(
          wordType: WordType.staticSign,
          referenceFrames: [pose],
          candidateFrames: [noisyPose],
        ),
        throwsArgumentError,
      );
    });

    test('referenceFrames에 Infinity 좌표가 섞여도 예외를 던진다', () {
      final pose = _samplePose();
      final brokenReference = [
        Point3(double.infinity, pose[0].y, pose[0].z),
        ...pose.sublist(1),
      ];

      expect(
        () => service.score(
          wordType: WordType.staticSign,
          referenceFrames: [brokenReference],
          candidateFrames: [pose],
        ),
        throwsArgumentError,
      );
    });
  });
}
