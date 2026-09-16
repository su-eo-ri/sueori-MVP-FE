import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scoring_poc/scoring_poc.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../camera/data/hand_landmark_bridge.dart';
import '../../../camera/presentation/camera_view.dart';
import '../../../scoring/domain/scoring_result.dart';
import '../../../scoring/domain/word_type.dart';
import '../../../scoring/presentation/providers/scoring_providers.dart';

/// 임시 홈 화면 — 익명 인증 + 실제 카메라 랜드마크 채점이 붙어서 동작하는지
/// 눈으로 확인하기 위한 통합 스모크 테스트용.
/// Week 2 작업(플래시카드 → 권한 → 채점 → 결과 → 재도전)이 이 자리를 대체한다.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _bridge = HandLandmarkBridge();

  Timer? _pollTimer;
  bool _cameraStarting = false;
  bool _cameraStarted = false;
  Map<String, dynamic> _stats = const {};
  String _scoringLog = '카메라를 시작하고 손을 비춘 뒤 "지금 프레임으로 채점"을 눌러보세요.';

  List<Point3> _referencePose() =>
      List.generate(21, (i) => Point3(0.1 * i, 0.2 * i, 0.05 * i));

  Future<void> _startCamera() async {
    setState(() => _cameraStarting = true);
    try {
      await _bridge.start(videoElementId: cameraVideoElementId, canvasElementId: cameraCanvasElementId);
    } finally {
      if (mounted) setState(() => _cameraStarting = false);
    }
    if (!mounted) return;
    setState(() => _cameraStarted = true);
    _pollTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (mounted) setState(() => _stats = _bridge.getStats());
    });
  }

  void _stopCamera() {
    _bridge.stop();
    _pollTimer?.cancel();
    setState(() {
      _cameraStarted = false;
      _stats = const {};
    });
  }

  void _captureAndScore() {
    final landmarks = _bridge.getLandmarks();
    if (landmarks == null) {
      _log('손이 감지되지 않았습니다 — 카메라에 손을 비춘 뒤 다시 시도하세요.');
      return;
    }
    try {
      final service = ref.read(scoringServiceProvider);
      final result = service.score(
        wordType: WordType.staticSign,
        referenceFrames: [_referencePose()],
        candidateFrames: [landmarks],
      );
      _log('실제 카메라 프레임 채점 → ${_fmt(result)}');
    } on ArgumentError catch (e) {
      _log('채점 불가: ${e.message}');
    }
  }

  void _runDynamicIdentical() {
    final service = ref.read(scoringServiceProvider);
    final sequence = [_referencePose(), _referencePose(), _referencePose()];
    final result = service.score(
      wordType: WordType.dynamicSign,
      referenceFrames: sequence,
      candidateFrames: sequence,
    );
    _log('동적(동일 시퀀스, DTW) → ${_fmt(result)}');
  }

  void _runNaNGuard() {
    final service = ref.read(scoringServiceProvider);
    final pose = _referencePose();
    final noisyPose = [Point3(double.nan, pose[0].y, pose[0].z), ...pose.sublist(1)];
    try {
      service.score(
        wordType: WordType.staticSign,
        referenceFrames: [pose],
        candidateFrames: [noisyPose],
      );
      _log('NaN 방어 실패 — 예외가 안 던져짐 (버그)');
    } on ArgumentError catch (e) {
      _log('NaN 입력 → 방어 코드가 정상적으로 막음: ${e.message}');
    }
  }

  String _fmt(ScoringResult r) {
    final base = '${r.score.toStringAsFixed(1)}점';
    if (r.avgAlignedCost != null) {
      return '$base (avgAlignedCost=${r.avgAlignedCost!.toStringAsFixed(3)}, pathLength=${r.pathLength})';
    }
    return base;
  }

  void _log(String line) => setState(() => _scoringLog = line);

  @override
  void dispose() {
    _pollTimer?.cancel();
    if (_cameraStarted) _bridge.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final loaded = _stats['loaded'] == true;
    final loading = _stats['loading'] == true;
    final error = _stats['error'] as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('수어리')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: user == null
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('세션 연결됨'),
                          const SizedBox(height: 4),
                          Text(
                            'user.id: ${user.id}',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                          ),
                          Text('isAnonymous: ${user.isAnonymous}'),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('카메라 채점 (실제 랜드마크)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const CameraPreview(),
            const SizedBox(height: 8),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(error, style: TextStyle(color: Colors.red.shade700)),
              ),
            if (loaded) Text('모델: ${_stats['delegate'] ?? '-'} · FPS: ${_stats['fps'] ?? '-'}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _cameraStarting ? null : (_cameraStarted ? _stopCamera : _startCamera),
                  icon: Icon(_cameraStarted ? Icons.stop : Icons.videocam),
                  label: Text(
                    _cameraStarting ? '모델 로딩 + 카메라 준비 중...' : (_cameraStarted ? '카메라 중지' : '카메라 시작'),
                  ),
                ),
                ElevatedButton(
                  onPressed: _cameraStarted && !loading ? _captureAndScore : null,
                  child: const Text('지금 프레임으로 채점'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('그 외 채점 서비스 테스트', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _runDynamicIdentical,
                  child: const Text('동적: 동일 시퀀스(DTW)'),
                ),
                OutlinedButton(
                  onPressed: _runNaNGuard,
                  child: const Text('NaN 방어 테스트'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_scoringLog, style: const TextStyle(fontFamily: 'monospace')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
