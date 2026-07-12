enum NeedCategory { hospital, general, professional, none }

extension NeedCategoryText on NeedCategory {
  String get apiValue {
    switch (this) {
      case NeedCategory.hospital:
        return 'hospital';
      case NeedCategory.general:
        return 'general';
      case NeedCategory.professional:
        return 'professional';
      case NeedCategory.none:
        return 'none';
    }
  }

  String get label {
    switch (this) {
      case NeedCategory.hospital:
        return '병원/건강';
      case NeedCategory.general:
        return '일반 심부름';
      case NeedCategory.professional:
        return '전문 돌봄';
      case NeedCategory.none:
        return '없음';
    }
  }

  static NeedCategory? fromApiValue(String value) {
    switch (value) {
      case 'hospital':
      case '병원':
      case '병원/건강':
        return NeedCategory.hospital;
      case 'general':
      case '일반':
      case '심부름':
      case '일반(심부름)':
        return NeedCategory.general;
      case 'professional':
      case '전문':
      case '전문 돌봄':
        return NeedCategory.professional;
      case 'none':
      case '없음':
        return NeedCategory.none;
      default:
        return null;
    }
  }
}

NeedCategory primaryActionCategory(List<NeedCategory> categories) {
  if (categories.contains(NeedCategory.professional)) {
    return NeedCategory.professional;
  }
  if (categories.contains(NeedCategory.hospital)) {
    return NeedCategory.hospital;
  }
  if (categories.contains(NeedCategory.general)) {
    return NeedCategory.general;
  }
  return NeedCategory.none;
}
