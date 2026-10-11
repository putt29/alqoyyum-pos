import 'icon_registry.dart';

/// Icon fallback per kategori bila icon_name tidak ditemukan.
String resolveIconName(String? iconName, String categoryName) {
  if (iconName != null && kIconNames.contains(iconName)) return iconName;
  switch (categoryName) {
    case 'Jasa':
      return 'service/service';
    case 'Tindakan':
      return 'treatment/procedure';
    case 'Lab':
      return 'service/lab';
    case 'BHP':
    case 'Alat':
      return 'equipment/equipment';
    default:
      return 'medicine/medicine';
  }
}
