/// 부모님 인적사항. 병원 추천 등에 사용.
///
/// 이번 단계는 하드코딩. 나중에 로컬 저장(shared_preferences 등)으로 교체 가능.
class ParentProfile {
  final String name;
  final String address;
  final int? age;

  const ParentProfile({
    required this.name,
    required this.address,
    this.age,
  });
}
