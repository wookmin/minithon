import {onCall, HttpsError} from "firebase-functions/v2/https";
import {defineSecret} from "firebase-functions/params";
import {setGlobalOptions} from "firebase-functions/v2";
import {initializeApp} from "firebase-admin/app";
import {getFirestore, FieldValue} from "firebase-admin/firestore";
import {
  GEMINI_ENDPOINT,
  GEMINI_MODEL,
  NEED_PROMPT,
  NEED_SCHEMA,
} from "./gemini";

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");
const KAKAO_REST_API_KEY = defineSecret("KAKAO_REST_API_KEY");

setGlobalOptions({region: "asia-northeast3"});

initializeApp();
const db = getFirestore();

// App Check 클라이언트 설정 완료 후 true 로 바꿔 봇/외부 호출을 차단하세요.
const ENFORCE_APP_CHECK = false;

// 사용자당 일일 호출 상한. 외부 API(Gemini/Kakao) 비용 남용을 막는다.
const DAILY_LIMITS = {classify: 200, transcribe: 50, hospitals: 100} as const;

/**
 * 사용자·일자별 호출 수를 Firestore에 원자적으로 증가시키고, 상한 초과 시 차단한다.
 * (admin SDK는 보안 규칙을 우회하므로 rate_limits 컬렉션은 서버 전용)
 */
// 사용자 타임존(Asia/Seoul) 기준 yyyy-mm-dd. "오늘"의 리셋 시각을 사용자와 일치시킨다.
function kstDayKey(): string {
  return new Intl.DateTimeFormat("en-CA", {timeZone: "Asia/Seoul"}).format(
    new Date()
  );
}

async function enforceDailyQuota(
  uid: string,
  action: keyof typeof DAILY_LIMITS
): Promise<void> {
  // uid를 문자열 연결 대신 개별 path 세그먼트로 사용(잘못된 문서 경로 방지 + 조회/TTL 용이).
  const ref = db
    .collection("rate_limits")
    .doc(uid)
    .collection("days")
    .doc(kstDayKey());
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const current = (snap.get(action) as number | undefined) ?? 0;
    if (current >= DAILY_LIMITS[action]) {
      throw new HttpsError(
        "resource-exhausted",
        "오늘 사용 한도를 초과했어요. 내일 다시 시도해주세요."
      );
    }
    tx.set(
      ref,
      {[action]: current + 1, updatedAt: FieldValue.serverTimestamp()},
      {merge: true}
    );
  });
}

// 1) 통화 텍스트 → 니즈 분류
export const classifyNeed = onCall(
  {secrets: [GEMINI_API_KEY], enforceAppCheck: ENFORCE_APP_CHECK},
  async (req) => {
    if (!req.auth) throw new HttpsError("unauthenticated", "로그인이 필요합니다.");
    await enforceDailyQuota(req.auth.uid, "classify");
    const text = String(req.data?.text ?? "").trim();
    if (text.length === 0) {
      return {categories: ["none"], confidence: 1, reason: "빈 텍스트"};
    }

    const res = await fetch(GEMINI_ENDPOINT(GEMINI_MODEL), {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_API_KEY.value(),
      },
      body: JSON.stringify({
        systemInstruction: {parts: [{text: NEED_PROMPT}]},
        contents: [{role: "user", parts: [{text: `통화 텍스트:\n${text}`}]}],
        generationConfig: {
          temperature: 0,
          maxOutputTokens: 256,
          responseMimeType: "application/json",
          responseSchema: NEED_SCHEMA,
        },
      }),
    });
    if (!res.ok) throw new HttpsError("unavailable", `Gemini ${res.status}`);

    const json = (await res.json()) as GeminiResponse;
    const out = json.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!out) throw new HttpsError("internal", "Gemini 응답이 비어 있습니다.");
    return JSON.parse(out);
  }
);

// 2) 오디오 → 한국어 전사 (base64 인라인)
export const transcribeAudio = onCall(
  {secrets: [GEMINI_API_KEY], enforceAppCheck: ENFORCE_APP_CHECK},
  async (req) => {
    if (!req.auth) throw new HttpsError("unauthenticated", "로그인이 필요합니다.");
    await enforceDailyQuota(req.auth.uid, "transcribe");
    const audioBase64 = String(req.data?.audioBase64 ?? "");
    const mimeType = String(req.data?.mimeType ?? "audio/mp4");
    if (audioBase64.length === 0) {
      throw new HttpsError("invalid-argument", "오디오가 없습니다.");
    }

    const res = await fetch(GEMINI_ENDPOINT(GEMINI_MODEL), {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-goog-api-key": GEMINI_API_KEY.value(),
      },
      body: JSON.stringify({
        contents: [
          {
            role: "user",
            parts: [
              {
                text:
                  "이 오디오는 한국어 통화 녹음이다. 화자 표시·설명 없이 발화 내용만 한국어로 받아써라.",
              },
              {inlineData: {mimeType, data: audioBase64}},
            ],
          },
        ],
        generationConfig: {temperature: 0, maxOutputTokens: 2048},
      }),
    });
    if (!res.ok) throw new HttpsError("unavailable", `Gemini ${res.status}`);

    const json = (await res.json()) as GeminiResponse;
    const parts = json.candidates?.[0]?.content?.parts ?? [];
    const transcript = parts
      .map((p) => p.text ?? "")
      .join("")
      .trim();
    return {transcript};
  }
);

// 3) 주소 → 주변 병원 (Kakao 지오코딩 + HP8)
export const nearbyHospitals = onCall(
  {secrets: [KAKAO_REST_API_KEY], enforceAppCheck: ENFORCE_APP_CHECK},
  async (req) => {
    if (!req.auth) throw new HttpsError("unauthenticated", "로그인이 필요합니다.");
    await enforceDailyQuota(req.auth.uid, "hospitals");
    const address = String(req.data?.address ?? "").trim();
    if (address.length === 0) return {hospitals: []};

    const headers = {Authorization: `KakaoAK ${KAKAO_REST_API_KEY.value()}`};

    const geoRes = await fetch(
      "https://dapi.kakao.com/v2/local/search/address.json?" +
        `query=${encodeURIComponent(address)}&size=1`,
      {headers}
    );
    if (!geoRes.ok) throw new HttpsError("unavailable", `Kakao ${geoRes.status}`);
    const geo = (await geoRes.json()) as KakaoResponse;
    const doc = geo.documents?.[0];
    if (!doc) return {hospitals: []};

    const listRes = await fetch(
      "https://dapi.kakao.com/v2/local/search/category.json?" +
        `category_group_code=HP8&x=${doc.x}&y=${doc.y}` +
        "&radius=5000&sort=distance&size=15",
      {headers}
    );
    if (!listRes.ok) throw new HttpsError("unavailable", `Kakao ${listRes.status}`);
    const list = (await listRes.json()) as KakaoResponse;
    return {hospitals: list.documents ?? []};
  }
);

interface GeminiResponse {
  candidates?: {content?: {parts?: {text?: string}[]}}[];
}

interface KakaoResponse {
  documents?: {x?: string; y?: string; [key: string]: unknown}[];
}
