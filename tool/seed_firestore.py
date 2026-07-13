#!/usr/bin/env python3
"""공용 카탈로그(심부름·전문가) 데모 데이터를 Firestore에 시드한다.

- 최상위 컬렉션 `errands`, `experts` 를 채운다. (앱의 errandRequestsProvider /
  careExpertsProvider 가 읽는 위치)
- 고정 문서 ID로 upsert(PATCH) 하므로 여러 번 실행해도 중복이 생기지 않는다.
- 관리자 자격증명은 gcloud 액세스 토큰을 사용한다(보안 규칙 우회, 시드 전용).

사용법:
    gcloud auth login            # 프로젝트 소유자/편집자 계정
    python3 tool/seed_firestore.py
"""

import json
import subprocess
import urllib.request

PROJECT = "minithon-1b459"
BASE = f"https://firestore.googleapis.com/v1/projects/{PROJECT}/databases/(default)/documents"

ERRANDS = [
    {"title": "남원의료원 진료 동행", "category": "병원 동행", "region": "남원시 도통동", "distance": "1.8km", "description": "오전 진료 후 약국까지 함께 이동할 분을 찾고 있어요.", "status": "오늘 가능", "helperCount": 4},
    {"title": "거실 전등 교체", "category": "수리", "region": "남원시 왕정동", "distance": "2.3km", "description": "사다리가 필요한 작업이에요. 전구는 미리 준비되어 있습니다.", "status": "새 요청", "helperCount": 1},
    {"title": "전주 병원 이동 도움", "category": "교통", "region": "남원 → 전주", "distance": "49km", "description": "오전 8:40 출발 예정입니다. 보호자 동승도 문의 가능해요.", "status": "동승 가능", "helperCount": 3},
    {"title": "쌀과 생필품 장보기", "category": "장보기", "region": "남원시 금동", "distance": "900m", "description": "쌀 10kg과 세제처럼 무거운 물품 위주로 부탁드려요.", "status": "근처 요청", "helperCount": 2},
]

EXPERTS = [
    {"name": "박지영", "role": "방문 사회복지사", "region": "남원시 전역", "rating": 4.9, "career": "복지 상담 8년", "availableTime": "오늘 17:00 전화 상담", "reviewCount": 132, "isCertified": True, "rehireRate": 94},
    {"name": "이정호", "role": "요양보호사", "region": "도통동 · 왕정동", "rating": 4.8, "career": "방문 돌봄 6년", "availableTime": "내일 10:30 방문 가능", "reviewCount": 87, "isCertified": True, "rehireRate": 91},
    {"name": "최민서", "role": "병원 동행 매니저", "region": "남원 · 전주", "rating": 4.7, "career": "동행 320건", "availableTime": "이번 주 화·목 가능", "reviewCount": 64, "isCertified": False, "rehireRate": 88},
]


def _typed(value):
    if isinstance(value, bool):
        return {"booleanValue": value}
    if isinstance(value, int):
        return {"integerValue": str(value)}
    if isinstance(value, float):
        return {"doubleValue": value}
    return {"stringValue": str(value)}


def _upsert(token, collection, doc_id, data):
    body = json.dumps({"fields": {k: _typed(v) for k, v in data.items()}}).encode()
    request = urllib.request.Request(
        f"{BASE}/{collection}/{doc_id}",
        data=body,
        method="PATCH",
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
    )
    with urllib.request.urlopen(request) as response:
        return response.status


def main():
    token = subprocess.check_output(["gcloud", "auth", "print-access-token"]).decode().strip()
    for index, item in enumerate(ERRANDS, start=1):
        print("errand", index, _upsert(token, "errands", f"errand-{index}", item))
    for index, item in enumerate(EXPERTS, start=1):
        print("expert", index, _upsert(token, "experts", f"expert-{index}", item))
    print("done")


if __name__ == "__main__":
    main()
