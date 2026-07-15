// 앱의 lib/features/classification/gemini 프롬프트·스키마를 서버로 이식.

export const NEED_PROMPT = `너는 부모님과 자녀의 통화 텍스트에서 앱이 처리할 수 있는 실제 니즈만 분류하는 엔진이다.

반드시 아래 네 카테고리 중에서만 판단한다.
- hospital: 통증, 아픔, 건강 이상, 병원, 진료, 약 등 병원/건강 도움
- general: 전등 교체, 장보기, 집수리, 무거운 물건 옮기기 등 생활 심부름/일상 도움
- professional: 사회복지사, 요양보호사, 간병, 치매, 거동 곤란, 혼자 생활 곤란 등 전문 돌봄 개입
- none: 위 서비스로 실제 연결할 니즈가 없음

중요 규칙:
- 우리 앱이 실제로 도와줄 수 있는 서비스 연결 니즈가 아니면 반드시 none을 반환한다.
- 단순 안부, 날씨, 식사 여부, 감정 표현, 잡담, 가벼운 근황은 none이다.
- 애매하면 알림을 띄우지 않는 쪽이 원칙이므로 none이다.
- 한 통화에 여러 니즈가 있으면 categories에 여러 카테고리를 넣는다.
- none은 반드시 단독으로만 반환한다.
- JSON 이외의 설명, 마크다운, 코드블록을 절대 출력하지 않는다.
- reason은 한국어로 짧게 작성한다.

서비스 유형(serviceType):
- general(생활 심부름)일 때 구체 유형을 아래 중 하나로 지정한다.
  - repair: 전등·수도·가전·가구·보일러 등 고장 수리
  - cleaning: 청소·정리·환기
  - shopping: 장보기·생필품 구매·배달
  - transport: 이동·교통 지원(병원 외)
- general이 아니거나 판단이 애매하면 "none"으로 둔다.

날짜 규칙:
- preferredDate: 통화에서 도움이 필요한 구체적 날짜/시점이 언급되면 YYYY-MM-DD 형식으로 반환한다.
- "내일", "모레", "다음 주 화요일", "이번 주말", "3일 뒤" 같은 상대 표현은 입력으로 주어지는 '오늘 날짜'를 기준으로 계산한다.
- 시각만 있고 날짜가 없으면 오늘 날짜로 본다.
- 날짜/시점 언급이 없거나 애매하면 빈 문자열("")을 반환한다.`;

export const NEED_SCHEMA = {
  type: "OBJECT",
  properties: {
    categories: {
      type: "ARRAY",
      items: {
        type: "STRING",
        enum: ["hospital", "general", "professional", "none"],
      },
      minItems: 1,
      description:
        "Actionable service categories. Use [\"none\"] only when there is no actionable need.",
    },
    confidence: {
      type: "NUMBER",
      minimum: 0,
      maximum: 1,
      description: "Confidence from 0 to 1.",
    },
    reason: {type: "STRING", description: "A brief Korean reason."},
    serviceType: {
      type: "STRING",
      enum: ["repair", "cleaning", "shopping", "transport", "none"],
      description: "Sub-type for general needs; none otherwise.",
    },
    preferredDate: {
      type: "STRING",
      description:
        "Requested date as YYYY-MM-DD, or empty string if none/ambiguous.",
    },
  },
  required: [
    "categories",
    "confidence",
    "reason",
    "serviceType",
    "preferredDate",
  ],
  propertyOrdering: [
    "categories",
    "confidence",
    "reason",
    "serviceType",
    "preferredDate",
  ],
};

export const GEMINI_MODEL = "gemini-2.5-flash-lite";
export const GEMINI_ENDPOINT = (model: string) =>
  `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`;
