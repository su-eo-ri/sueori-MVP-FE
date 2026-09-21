// 카메라 미리보기용 HTML video/canvas를 Flutter Web의 PlatformView로 등록.
// poc/hand_landmark_poc과 동일한 패턴 — registerCameraView()는 runApp() 전에
// main()에서 한 번만 호출해야 한다.

import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

const cameraVideoElementId = 'sueori-video';
const cameraCanvasElementId = 'sueori-canvas';
const _viewType = 'sueori-camera-view';

void registerCameraView() {
  ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
    final container = web.HTMLDivElement()
      ..style.position = 'relative'
      ..style.width = '480px'
      ..style.height = '360px'
      ..style.backgroundColor = '#111';

    final video = web.HTMLVideoElement()
      ..id = cameraVideoElementId
      ..autoplay = true
      ..muted = true
      ..style.position = 'absolute'
      ..style.left = '0'
      ..style.top = '0'
      ..style.width = '480px'
      ..style.height = '360px'
      ..style.transform = 'scaleX(-1)' // 거울모드
      ..setAttribute('playsinline', 'true');

    final canvas = web.HTMLCanvasElement()
      ..id = cameraCanvasElementId
      ..width = 480
      ..height = 360
      ..style.position = 'absolute'
      ..style.left = '0'
      ..style.top = '0'
      ..style.width = '480px'
      ..style.height = '360px'
      ..style.transform = 'scaleX(-1)';

    // 수어 동작 영역 가이드 — 상하: 정수리~배꼽(허리선), 좌우: 어깨너비+α.
    // 실제 체형/거리를 측정해서 그리는 게 아니라(손 랜드마크만 있고 어깨/머리
    // 랜드마크는 없음) 프레임 대비 고정 비율로 보여주는 시각적 가이드 —
    // 사용자가 이 박스 안에서 동작하도록 유도해서 녹화 데이터 프레이밍을
    // 일관되게 맞추는 목적.
    final guideLabel = web.HTMLDivElement()
      ..style.position = 'absolute'
      ..style.left = '0'
      ..style.top = '-18px'
      ..style.color = '#00e676'
      ..style.fontSize = '11px'
      ..style.fontFamily = 'sans-serif'
      ..style.whiteSpace = 'nowrap'
      ..textContent = '동작 영역 (정수리~배꼽, 어깨너비+α)';

    final guideOverlay = web.HTMLDivElement()
      ..style.position = 'absolute'
      ..style.left = '20%'
      ..style.top = '5%'
      ..style.width = '60%'
      ..style.height = '67%'
      ..style.boxSizing = 'border-box'
      ..style.border = '2px dashed #00e676'
      ..style.borderRadius = '4px'
      ..style.pointerEvents = 'none';
    guideOverlay.append(guideLabel);

    container.append(video);
    container.append(canvas);
    container.append(guideOverlay);
    return container;
  });
}

/// 카메라 프리뷰 + 스켈레톤 오버레이(그리기는 JS 쪽 담당).
class CameraPreview extends StatelessWidget {
  const CameraPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 480, height: 360, child: HtmlElementView(viewType: _viewType));
  }
}
