import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scoring_poc/scoring_poc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/breakpoints.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../camera/data/hand_landmark_bridge.dart';
import '../../../camera/presentation/camera_view.dart';
import '../../../categories/presentation/providers/category_providers.dart';
import '../../../practice_sessions/presentation/providers/practice_session_providers.dart';
import '../../../reference_landmarks/presentation/providers/reference_landmark_providers.dart';
import '../../../scoring/domain/comparison_summary.dart';
import '../../../scoring/domain/hand_track_scoring.dart';
import '../../../scoring/domain/word_type.dart';
import '../../../scoring/presentation/providers/scoring_providers.dart';
import '../widgets/ghost_overlay_painter.dart';

/// `/practice/:wordId` 카메라 라이프사이클/권한 UI 상태 6종.
/// 채점은 active 상태에서 "채점하기"로 시작한다: 캡처 → 채점 → practice_sessions
/// 저장 → `/result/:id`.
enum _PracticeUiState { permissionPrompt, active, permissionDenied, noHandDetected, noCamera, recognitionFailed }

const _handFailMessage = '손 인식에 실패했어요. 손이 화면에 잘 보이게 하고 다시 시도해주세요.';

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({required this.wordId, this.retryOfSessionId, super.key});

  final String wordId;
  final String? retryOfSessionId;

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  static const _bridge = HandLandmarkBridge();

  _PracticeUiState _state = _PracticeUiState.permissionPrompt;
  Timer? _handPollTimer;
  int _missedHandPolls = 0;
  bool _cameraEverStarted = false;
  bool _starting = false;
  // 상태가 바뀌어도 같은 <video>가 유지돼야 스트림이 끊기지 않는다.
  final _previewKey = GlobalKey();
  bool _scoring = false;
  String? _scoreStatus;
  String? _scoreError;

  @override
  void dispose() {
    _handPollTimer?.cancel();
    if (_cameraEverStarted) _bridge.stop();
    super.dispose();
  }

  /// "카메라 허용하기"/"다시 시도" 탭에서만 호출 — 화면 진입 시 자동 호출 금지
  /// (브라우저 네이티브 권한 프롬프트가 사용자 의도 없이 뜨지 않게 하기 위함).
  Future<void> _requestCamera() async {
    if (_starting) return;
    _cameraEverStarted = true;
    _handPollTimer?.cancel();

    // JS start()가 id로 <video>/<canvas>를 찾으므로 미리보기를 먼저 DOM에 올린다.
    // _starting은 최종 상태가 정해질 때 같이 끈다. 중간에 끄면 미리보기가 빠졌다가
    // 새로 만들어져서 스트림이 붙은 <video>가 DOM에서 사라진다.
    setState(() => _starting = true);
    for (var i = 0; i < 30 && web.document.getElementById(cameraCanvasElementId) == null; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }
    // start()는 실패해도 던지지 않고 getStats()의 error 필드에 기록만 함.
    await _bridge.start(videoElementId: cameraVideoElementId, canvasElementId: cameraCanvasElementId);

    // 모델 로드/카메라 권한 처리가 비동기라 완료 직후엔 stats가 비어있을 수
    // 있음 — 최대 3초, 300ms 간격으로 폴링해서 error/running이 채워지길 기다림.
    for (var i = 0; i < 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      final stats = _bridge.getStats();
      final error = stats['error'] as String?;
      final running = stats['running'] as bool? ?? false;

      if (running && error == null) {
        _enterActiveState();
        return;
      }
      if (error != null) {
        _resolveError(error);
        return;
      }
    }
    // 3초 넘도록 running도 error도 안 채워지면(모델 로드가 유난히 느린 경우
    // 등) 일반 실패로 취급.
    setState(() {
      _starting = false;
      _state = _PracticeUiState.recognitionFailed;
    });
  }

  void _resolveError(String error) {
    setState(() {
      _starting = false;
      if (error.contains('NotAllowedError')) {
        _state = _PracticeUiState.permissionDenied;
      } else if (error.contains('NotFoundError')) {
        _state = _PracticeUiState.noCamera;
      } else {
        _state = _PracticeUiState.recognitionFailed;
      }
    });
  }

  void _enterActiveState() {
    setState(() {
      _starting = false;
      _state = _PracticeUiState.active;
    });
    _missedHandPolls = 0;
    _handPollTimer?.cancel();
    _handPollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) => _pollHand());
  }

  void _pollHand() {
    if (!mounted) return;
    final stats = _bridge.getStats();
    final error = stats['error'] as String?;
    final running = stats['running'] as bool? ?? false;
    if (!running || error != null) {
      _handPollTimer?.cancel();
      _resolveError(error ?? '카메라 스트림이 중단됐어요.');
      return;
    }

    final noHand = _bridge.getLandmarks() == null;
    if (noHand) {
      _missedHandPolls++;
      if (_missedHandPolls >= 3 && _state != _PracticeUiState.noHandDetected) {
        setState(() => _state = _PracticeUiState.noHandDetected);
      }
    } else {
      _missedHandPolls = 0;
      if (_state != _PracticeUiState.active) {
        setState(() => _state = _PracticeUiState.active);
      }
    }
  }

  Future<void> _score() async {
    if (_scoring) return;
    setState(() {
      _scoring = true;
      _scoreError = null;
      _scoreStatus = null;
    });
    try {
      final word = await ref.read(wordByIdProvider(widget.wordId).future);
      final reference = await ref.read(referenceLandmarkByWordIdProvider(widget.wordId).future);
      if (word == null || reference == null || reference.frames.isEmpty) {
        _failScore('이 단어는 아직 기준 동작 데이터가 없어서 채점할 수 없어요.');
        return;
      }

      final isStatic = word.type == WordType.staticSign;
      final captured = isStatic ? _captureStatic() : await _captureDynamic(recordingDurationFor(reference.frames));
      if (!mounted) return;

      final referenceFrames = reference.frames.map((f) => f.landmarks).toList();
      final best = scoreBestHand(
        service: ref.read(scoringServiceProvider),
        wordType: word.type,
        referenceFrames: referenceFrames,
        captured: captured,
        minFrames: isStatic ? 1 : 5,
      );
      if (best == null) {
        _failScore(_handFailMessage);
        return;
      }
      final score = best.score;
      final summary = buildComparisonSummary(
        wordType: word.type,
        referenceFrames: referenceFrames,
        userFrames: best.frames,
      );

      setState(() => _scoreStatus = '결과를 저장하고 있어요…');
      final auth = ref.read(authRepositoryProvider);
      await auth.ensureSignedIn();
      final session = await ref
          .read(practiceSessionRepositoryProvider)
          .insert(
            userId: auth.currentUser!.id,
            wordId: widget.wordId,
            score: score.round().clamp(0, 100),
            comparisonSummary: summary,
            retryOfSessionId: widget.retryOfSessionId,
          );
      ref.invalidate(myPracticeSessionsProvider);
      if (!mounted) return;
      context.go('/result/${session.id}');
    } on PostgrestException catch (e) {
      if (!mounted) return;
      if (e.code == '42501') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('무료 체험 채점을 모두 사용했거나 로그인이 필요한 카테고리예요. 로그인하면 계속 연습할 수 있어요.')),
        );
        context.go('/login');
        return;
      }
      _failScore('결과를 저장하지 못했어요. 잠시 후 다시 시도해주세요.');
    } catch (_) {
      _failScore('채점 중 문제가 생겼어요. 잠시 후 다시 시도해주세요.');
    } finally {
      if (mounted) {
        setState(() {
          _scoring = false;
          _scoreStatus = null;
        });
      }
    }
  }

  void _failScore(String message) {
    if (mounted) setState(() => _scoreError = message);
  }

  /// 현재 프레임에서 잡힌 손 전부(최대 2개). 손별 채점은 [scoreBestHand]가 한다.
  List<CapturedFrame> _captureHands(int tMs) => [
    for (final hand in _bridge.getLandmarks() ?? const <HandLandmark>[])
      if (hand.points.length == 21) CapturedFrame(tMs: tMs, points: hand.points, handedness: hand.handedness),
  ];

  List<CapturedFrame> _captureStatic() => _captureHands(0);

  /// [duration] 동안 100ms 간격으로 잡힌 손을 모두 모은다. 손이 안 잡힌 프레임은 건너뛴다.
  Future<List<CapturedFrame>> _captureDynamic(Duration duration) async {
    final frames = <CapturedFrame>[];
    final watch = Stopwatch()..start();
    while (watch.elapsed < duration) {
      if (!mounted) return const [];
      final remaining = (duration - watch.elapsed).inMilliseconds / 1000;
      setState(() => _scoreStatus = '동작을 녹화하고 있어요… ${remaining.ceil()}초');
      frames.addAll(_captureHands(watch.elapsedMilliseconds));
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return frames;
  }

  List<Widget> _scoreControls() {
    return [
      _primaryButton(_scoring ? '채점 중…' : '채점하기', _scoring ? null : _score),
      if (_scoreStatus != null) Text(_scoreStatus!, style: AppTextStyles.bodySmall),
      if (_scoreError != null)
        Text(_scoreError!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.stateError)),
    ];
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 정답 동작 고스트 오버레이용 참조 랜드마크. 동적 수어도 MVP에서는
    // 첫 프레임만 정적으로 보여준다(프레임 애니메이션은 범위 밖).
    final referenceLandmark = ref
        .watch(referenceLandmarkByWordIdProvider(widget.wordId))
        .maybeWhen(data: (value) => value, orElse: () => null);
    final ghostLandmarks = referenceLandmark != null && referenceLandmark.frames.isNotEmpty
        ? referenceLandmark.frames.first.landmarks
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('연습하기'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack),
      ),
      body: Breakpoints.isWide(context)
          ? _buildWideBody(ghostLandmarks)
          : Center(
              child: Padding(padding: const EdgeInsets.all(24), child: _buildBody(ghostLandmarks)),
            ),
    );
  }

  /// 와이드(≥768) 전용: 좌측 카메라 뷰(모바일과 동일 크기) + 우측 안내 패널
  /// `Row`. 카메라 상태머신은 그대로, 6개 상태 전부 같은 레이아웃 구조를
  /// 쓰고 안내 텍스트만 바뀐다. `AppShell`은 이 화면(카메라 몰입) 대상이
  /// 아니므로 여기서 쓰지 않음 — 자체 `AppBar`만 유지.
  Widget _buildWideBody(List<Point3>? ghostLandmarks) {
    final (Widget visual, Widget panel) = switch (_state) {
      _ when _starting => (
        _cameraPreviewBox(overlay: const CircularProgressIndicator(color: Colors.white)),
        const _GuidancePanel(title: '카메라를 준비하고 있어요', body: '처음에는 손 인식 모델을 불러오느라 몇 초 걸릴 수 있어요.'),
      ),
      _PracticeUiState.permissionPrompt => (
        _visualPlaceholder(Icons.videocam_outlined, AppColors.brandPrimary),
        _GuidancePanel(
          title: '카메라를 사용해요',
          body: '손 동작을 인식해서 수어 연습을 도와드려요.\n카메라 화면은 저장되지 않고 실시간으로만 사용돼요.',
          actions: [_primaryButton('카메라 허용하기', _requestCamera)],
        ),
      ),
      _PracticeUiState.active => (
        _cameraPreviewBox(ghostLandmarks: ghostLandmarks),
        _GuidancePanel(
          title: '카메라 인식 중이에요',
          body: '카메라를 향해 동작을 취한 뒤 채점하기를 눌러보세요.',
          actions: _scoreControls(),
        ),
      ),
      _PracticeUiState.noHandDetected => (
        _cameraPreviewBox(
          ghostLandmarks: ghostLandmarks,
          overlay: const Icon(Icons.warning_amber_rounded, color: AppColors.stateWarning, size: 48),
        ),
        const _GuidancePanel(title: '손이 잘 안 보여요', body: '밝은 곳에서 카메라 앞에 손을 비춰주세요.'),
      ),
      _PracticeUiState.permissionDenied => (
        _visualPlaceholder(Icons.block, AppColors.stateError),
        _GuidancePanel(
          title: '카메라 권한이 거부됐어요',
          body: '학습은 계속 가능해요.\n브라우저 설정에서 카메라 권한을 허용하면 다시 연습할 수 있어요.',
          actions: [_backToDeckButton()],
        ),
      ),
      _PracticeUiState.noCamera => (
        _visualPlaceholder(Icons.videocam_off_outlined, AppColors.stateError),
        _GuidancePanel(
          title: '카메라를 사용할 수 없어요',
          body: '이 기기 또는 브라우저에서는 카메라를 지원하지 않아요.\n학습은 계속 가능해요.',
          actions: [_backToDeckButton()],
        ),
      ),
      _PracticeUiState.recognitionFailed => (
        _visualPlaceholder(Icons.error_outline, AppColors.stateError),
        _GuidancePanel(
          title: '카메라 인식에 실패했어요',
          body: '잠시 후 다시 시도해주세요.',
          actions: [_primaryButton('다시 시도', _requestCamera)],
        ),
      ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Breakpoints.contentMaxWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [visual, const SizedBox(width: 48), Expanded(child: panel)],
          ),
        ),
      ),
    );
  }

  /// 카메라 프리뷰가 없는 4개 상태(권한요청/거부/카메라없음/인식실패)에서
  /// 와이드 레이아웃의 좌측 슬롯을 [_cameraPreviewBox]와 같은 크기로 채우는
  /// 아이콘 플레이스홀더.
  Widget _visualPlaceholder(IconData icon, Color color) {
    return Container(
      width: 480,
      height: 360,
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Center(child: Icon(icon, size: 48, color: color)),
    );
  }

  Widget _primaryButton(String label, VoidCallback? onPressed) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.brandPrimary,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }

  Widget _buildBody(List<Point3>? ghostLandmarks) {
    if (_starting) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _cameraPreviewBox(overlay: const CircularProgressIndicator(color: Colors.white)),
          const SizedBox(height: 16),
          Text('카메라를 준비하고 있어요', style: AppTextStyles.h3),
        ],
      );
    }
    switch (_state) {
      case _PracticeUiState.permissionPrompt:
        return _MessageView(
          icon: Icons.videocam_outlined,
          iconColor: AppColors.brandPrimary,
          title: '카메라를 사용해요',
          body: '손 동작을 인식해서 수어 연습을 도와드려요.\n카메라 화면은 저장되지 않고 실시간으로만 사용돼요.',
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _requestCamera,
              child: const Text('카메라 허용하기'),
            ),
          ],
        );
      case _PracticeUiState.active:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _cameraPreviewBox(ghostLandmarks: ghostLandmarks),
            const SizedBox(height: 16),
            Text('카메라 인식 중이에요', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            for (final control in _scoreControls()) ...[control, const SizedBox(height: 8)],
          ],
        );
      case _PracticeUiState.noHandDetected:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _cameraPreviewBox(
              ghostLandmarks: ghostLandmarks,
              overlay: const Icon(Icons.warning_amber_rounded, color: AppColors.stateWarning, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              '손이 잘 안 보여요. 밝은 곳에서 카메라 앞에 손을 비춰주세요.',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
          ],
        );
      case _PracticeUiState.permissionDenied:
        return _MessageView(
          icon: Icons.block,
          iconColor: AppColors.stateError,
          title: '카메라 권한이 거부됐어요',
          body: '학습은 계속 가능해요.\n브라우저 설정에서 카메라 권한을 허용하면 다시 연습할 수 있어요.',
          actions: [_backToDeckButton()],
        );
      case _PracticeUiState.noCamera:
        return _MessageView(
          icon: Icons.videocam_off_outlined,
          iconColor: AppColors.stateError,
          title: '카메라를 사용할 수 없어요',
          body: '이 기기 또는 브라우저에서는 카메라를 지원하지 않아요.\n학습은 계속 가능해요.',
          actions: [_backToDeckButton()],
        );
      case _PracticeUiState.recognitionFailed:
        return _MessageView(
          icon: Icons.error_outline,
          iconColor: AppColors.stateError,
          title: '카메라 인식에 실패했어요',
          body: '잠시 후 다시 시도해주세요.',
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _requestCamera,
              child: const Text('다시 시도'),
            ),
          ],
        );
    }
  }

  Widget _backToDeckButton() {
    return TextButton(onPressed: _goBack, child: const Text('학습 목록으로 돌아가기'));
  }

  /// 480×360 카메라 프리뷰를 좁은 모바일 뷰포트에 맞춰 반응형으로 감싼다.
  /// [ghostLandmarks]가 주어지면 정답 동작 반투명 스켈레톤을 프리뷰 위에
  /// 겹쳐 그린다. [overlay]가 주어지면 그 위에 어두운 반투명 레이어 +
  /// 아이콘을 한 번 더 겹친다(손미감지/저조도 상태용) — 쌓는 순서는 카메라
  /// → 고스트 스켈레톤 → 경고 레이어.
  Widget _cameraPreviewBox({List<Point3>? ghostLandmarks, Widget? overlay}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(0, 480).toDouble();
        final height = width * 3 / 4;
        final preview = SizedBox(
          width: width,
          height: height,
          child: FittedBox(fit: BoxFit.contain, child: CameraPreview(key: _previewKey)),
        );
        return Stack(
          alignment: Alignment.center,
          children: [
            preview,
            if (ghostLandmarks != null)
              SizedBox(
                width: width,
                height: height,
                child: CustomPaint(painter: GhostOverlayPainter(landmarks: ghostLandmarks)),
              ),
            if (overlay != null)
              SizedBox(
                width: width,
                height: height,
                child: ColoredBox(color: Colors.black54, child: Center(child: overlay)),
              ),
          ],
        );
      },
    );
  }
}

/// 와이드 레이아웃 우측 안내 패널 — 6개 상태가 공유하는 카드형 레이아웃.
/// 상태별로 [title]/[body]/[actions] 내용만 다르다.
class _GuidancePanel extends StatelessWidget {
  const _GuidancePanel({required this.title, required this.body, this.actions = const []});

  final String title;
  final String body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppTextStyles.h1(context)),
          const SizedBox(height: 12),
          Text(body, style: AppTextStyles.bodyLarge(context)),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 24),
            for (final action in actions) ...[action, const SizedBox(height: 8)],
          ],
        ],
      ),
    );
  }
}

/// 권한요청/거부/카메라없음/인식실패 4개 상태가 공유하는 "아이콘 + 제목 +
/// 본문 + 버튼들" 레이아웃.
class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.actions,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: iconColor),
        const SizedBox(height: 16),
        Text(title, style: AppTextStyles.h2, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(body, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        for (final action in actions) ...[action, const SizedBox(height: 8)],
      ],
    );
  }
}
