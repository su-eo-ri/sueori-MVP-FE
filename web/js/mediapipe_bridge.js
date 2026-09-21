// 수어리 메인 앱 — MediaPipe HandLandmarker JS interop 브릿지.
//
// poc/hand_landmark_poc/web/js/mediapipe_bridge.js를 기반으로 하되, 그 PoC는
// 의도적으로 "성능 통계만 노출"하는 범위였다(랜드마크 좌표 자체는 Dart로 안 넘김).
// 이 파일은 실제 채점에 쓸 수 있도록 getLandmarks()를 추가해서 현재 프레임의
// 손 랜드마크 좌표(x,y,z, 정규화됨)를 Dart에 노출한다. numHands=2라 최대 2개
// 손까지 handedness와 함께 반환한다 — 두 손을 쓰는 수어(예: "동생")를 한 손만
// 추적해서 생기던 불안정한 궤적 문제 대응(2026-09-19).

import {
  HandLandmarker,
  FilesetResolver,
} from "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.20/vision_bundle.mjs";

const WASM_BASE =
  "https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@0.10.20/wasm";
const MODEL_URL =
  "https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task";

const state = {
  loaded: false,
  loading: false,
  loadTimeMs: null,
  delegate: null, // "GPU" | "CPU"
  lastInferenceMs: null,
  avgInferenceMs: null,
  fps: 0,
  numHands: 0,
  error: null,
  running: false,
};

// 가장 최근 프레임의 랜드마크 — 손마다 {handedness, landmarks: 21개 {x,y,z}}.
// numHands=2라 최대 2개 손까지 들어올 수 있음. getStats()에는 안 넣고 별도
// getLandmarks()로만 노출한다(폴링 페이로드를 가볍게 유지하기 위해).
let lastLandmarks = null;

let handLandmarker = null;
let video = null;
let canvas = null;
let ctx = null;
let rafId = null;
let lastFpsTime = 0;
let framesSinceFpsTick = 0;
let inferenceTimes = [];

async function createLandmarker(delegate) {
  const vision = await FilesetResolver.forVisionTasks(WASM_BASE);
  return HandLandmarker.createFromOptions(vision, {
    baseOptions: { modelAssetPath: MODEL_URL, delegate },
    runningMode: "VIDEO",
    numHands: 2,
  });
}

async function ensureLandmarker() {
  if (handLandmarker || state.loading) return;
  state.loading = true;
  state.error = null;
  const t0 = performance.now();
  try {
    handLandmarker = await createLandmarker("GPU");
    state.delegate = "GPU";
  } catch (e) {
    console.warn("[sueori] GPU delegate 실패, CPU로 폴백:", e);
    try {
      handLandmarker = await createLandmarker("CPU");
      state.delegate = "CPU";
      state.error = "GPU delegate 사용 불가 → CPU로 폴백됨";
    } catch (e2) {
      state.error = "모델 로드 실패: " + String(e2);
    }
  } finally {
    state.loadTimeMs = performance.now() - t0;
    state.loaded = !!handLandmarker;
    state.loading = false;
  }
}

const CONNECTIONS = [
  [0, 1], [1, 2], [2, 3], [3, 4],
  [0, 5], [5, 6], [6, 7], [7, 8],
  [5, 9], [9, 10], [10, 11], [11, 12],
  [9, 13], [13, 14], [14, 15], [15, 16],
  [13, 17], [17, 18], [18, 19], [19, 20],
  [0, 17],
];

function drawResults(result) {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  for (const landmarks of result.landmarks) {
    ctx.strokeStyle = "#00ffa2";
    ctx.lineWidth = 2;
    for (const [a, b] of CONNECTIONS) {
      const pa = landmarks[a];
      const pb = landmarks[b];
      ctx.beginPath();
      ctx.moveTo(pa.x * canvas.width, pa.y * canvas.height);
      ctx.lineTo(pb.x * canvas.width, pb.y * canvas.height);
      ctx.stroke();
    }
    ctx.fillStyle = "#ff3d5a";
    for (const p of landmarks) {
      ctx.beginPath();
      ctx.arc(p.x * canvas.width, p.y * canvas.height, 3, 0, 2 * Math.PI);
      ctx.fill();
    }
  }
}

function loop() {
  if (!state.running) return;
  if (handLandmarker && video && video.readyState >= 2) {
    const t0 = performance.now();
    const result = handLandmarker.detectForVideo(video, t0);
    const dt = performance.now() - t0;

    state.lastInferenceMs = dt;
    inferenceTimes.push(dt);
    if (inferenceTimes.length > 30) inferenceTimes.shift();
    state.avgInferenceMs =
      inferenceTimes.reduce((a, b) => a + b, 0) / inferenceTimes.length;
    state.numHands = result.landmarks.length;

    // 손이 안 보이면 null로 비워서 Dart 쪽에서 "지금은 캡처 불가"임을 알 수
    // 있게 한다. 손이 보이면 감지된 손마다(최대 2개) handedness + 21개 점.
    lastLandmarks =
      result.landmarks.length > 0
        ? result.landmarks.map((landmarks, i) => ({
            handedness: result.handedness[i]?.[0]?.categoryName ?? null,
            landmarks: landmarks.map((p) => ({ x: p.x, y: p.y, z: p.z })),
          }))
        : null;

    drawResults(result);

    framesSinceFpsTick++;
    const now = performance.now();
    if (now - lastFpsTime >= 1000) {
      state.fps = framesSinceFpsTick;
      framesSinceFpsTick = 0;
      lastFpsTime = now;
    }
  }
  rafId = requestAnimationFrame(loop);
}

async function start(videoId, canvasId) {
  video = document.getElementById(videoId);
  canvas = document.getElementById(canvasId);
  ctx = canvas.getContext("2d");

  await ensureLandmarker();
  if (!handLandmarker) return; // state.error에 이미 원인 기록됨

  try {
    const stream = await navigator.mediaDevices.getUserMedia({
      video: { width: 640, height: 480 },
      audio: false,
    });
    video.srcObject = stream;
    await video.play();
    canvas.width = video.videoWidth || 640;
    canvas.height = video.videoHeight || 480;
  } catch (e) {
    state.error = "카메라 접근 실패: " + String(e);
    return;
  }

  state.running = true;
  lastFpsTime = performance.now();
  loop();
}

function stop() {
  state.running = false;
  if (rafId) cancelAnimationFrame(rafId);
  rafId = null;
  if (video && video.srcObject) {
    for (const track of video.srcObject.getTracks()) track.stop();
    video.srcObject = null;
  }
  lastLandmarks = null;
}

function getStats() {
  return JSON.stringify(state);
}

// 채점용 — 현재 프레임에서 감지된 손마다(최대 2개) {handedness, landmarks}
// 배열을 JSON으로 반환한다(손 미검출 시 null).
function getLandmarks() {
  return JSON.stringify(lastLandmarks);
}

window.SueoriHandLandmark = { start, stop, getStats, getLandmarks, ensureLandmarker };
