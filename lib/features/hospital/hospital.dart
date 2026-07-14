/// 근처 병원 항목.
class Hospital {
  final String name;
  final String department;
  final String address;
  final String distance;
  final bool isOpenNow;
  final String hours;
  final String phone;
  final double rating;
  final int reviewCount;
  final double? latitude;
  final double? longitude;

  const Hospital({
    required this.name,
    required this.department,
    required this.address,
    required this.distance,
    this.isOpenNow = true,
    this.hours = '',
    this.phone = '',
    this.rating = 0,
    this.reviewCount = 0,
    this.latitude,
    this.longitude,
  });

  bool get hasLocation => latitude != null && longitude != null;
}
