class FirestorePaths {
  const FirestorePaths._();

  static const users = 'users';
  static const recipients = 'recipients';
  static const analyses = 'analyses';
  static const errands = 'errands';

  /// 통화 분석이 만든 비공개 초안. 게시 전까지 본인만 볼 수 있다.
  /// (users/{uid}/errand_drafts — 사용자 하위라 기존 소유자 규칙으로 보호)
  static const errandDrafts = 'errand_drafts';
}
