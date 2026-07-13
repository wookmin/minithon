/// 등록된 돌봄 대상자에서 파생한 병원 검색용 인적사항.
class ParentProfile {
  final String name;
  final String address;
  final int? age;

  const ParentProfile({required this.name, required this.address, this.age});
}
