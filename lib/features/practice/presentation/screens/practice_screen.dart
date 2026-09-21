import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../camera/data/hand_landmark_bridge.dart';
import '../../../camera/presentation/camera_view.dart';

/// `/practice/:wordId` 카메라 라이프사이클/권한 UI 상태 6종.
/// 채점 로직(scoring_poc, practice_sessions 저장)은 범위 밖 — 카메라 상태
/// 전이만 다룬다.
enum _PracticeUiState { permissionPrompt, active, permissionDenied, noHandDetected, noCamera, recognitionFailed }

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({required this.wordId, super.key});

  final String wordId;

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> {
  static const _bridge = HandLandmarkBridge();

  _PracticeUiState _state = _PracticeUiState.permissionPrompt;
  Timer? _handPollTimer;
  int _missedHandPolls = 0;
  bool _cameraEverStarted = false;

  @override
  void dispose() {
    _handPollTimer?.cancel();
    if (_cameraEverStarted) _bridge.stop();
    super.dispose();
  }

  /// "카메라 허용하기"/"다시 시도" 탭에서만 호출 — 화면 진입 시 자동 호출 금지
  /// (브라우저 네이티브 권한 프롬프트가 사용자 의도 없이 뜨지 않게 하기 위함).
  Future<void> _requestCamera() async {
    _cameraEverStarted = true;
    _handPollTimer?.cancel();

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
    setState(() => _state = _PracticeUiState.recognitionFailed);
  }

  void _resolveError(String error) {
    if (error.contains('NotAllowedError')) {
      setState(() => _state = _PracticeUiState.permissionDenied);
    } else if (error.contains('NotFoundError')) {
      setState(() => _state = _PracticeUiState.noCamera);
    } else {
      setState(() => _state = _PracticeUiState.recognitionFailed);
    }
  }

  void _enterActiveState() {
    setState(() => _state = _PracticeUiState.active);
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

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('연습하기'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _goBack),
      ),
      body: Center(
        child: Padding(padding: const EdgeInsets.all(24), child: _buildBody()),
      ),
    );
  }

  Widget _buildBody() {
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
          children: [_cameraPreviewBox(), const SizedBox(height: 16), Text('카메라 인식 중이에요', style: AppTextStyles.h3)],
        );
      case _PracticeUiState.noHandDetected:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _cameraPreviewBox(
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
  /// [overlay]가 주어지면 어두운 반투명 레이어 위에 아이콘을 겹쳐 그린다
  /// (손미감지/저조도 상태용).
  Widget _cameraPreviewBox({Widget? overlay}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.clamp(0, 480).toDouble();
        final preview = SizedBox(
          width: width,
          height: width * 3 / 4,
          child: const FittedBox(fit: BoxFit.contain, child: CameraPreview()),
        );
        if (overlay == null) return preview;
        return Stack(
          alignment: Alignment.center,
          children: [preview, Positioned.fill(child: ColoredBox(color: Colors.black54, child: Center(child: overlay)))],
        );
      },
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
