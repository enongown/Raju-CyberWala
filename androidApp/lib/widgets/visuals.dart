import 'package:flutter/material.dart';

import '../data/models.dart';
import '../theme/app_colors.dart';

/// Icon and colour lookups for the plain-Dart models.

IconData amenityIcon(Amenity a) => switch (a) {
  Amenity.kitchen => Icons.soup_kitchen_outlined,
  Amenity.wifi => Icons.wifi,
  Amenity.parking => Icons.local_parking_outlined,
  Amenity.laundry => Icons.local_laundry_service_outlined,
  Amenity.fireplace => Icons.fireplace_outlined,
  Amenity.hotWater => Icons.hot_tub_outlined,
  Amenity.breakfast => Icons.free_breakfast_outlined,
  Amenity.mountainView => Icons.landscape_outlined,
  Amenity.riverView => Icons.water_outlined,
  Amenity.bonfire => Icons.local_fire_department_outlined,
};

IconData poiIcon(PoiKind k) => switch (k) {
  PoiKind.sight => Icons.account_balance_outlined,
  PoiKind.nature => Icons.park_outlined,
  PoiKind.craft => Icons.shopping_bag_outlined,
  PoiKind.food => Icons.restaurant_outlined,
  PoiKind.stay => Icons.cottage_outlined,
  PoiKind.hospital => Icons.local_hospital_outlined,
  PoiKind.police => Icons.local_police_outlined,
  PoiKind.army => Icons.shield_outlined,
  PoiKind.fire => Icons.fire_truck_outlined,
  PoiKind.pharmacy => Icons.local_pharmacy_outlined,
};

Color poiColor(PoiKind k) => switch (k) {
  PoiKind.sight => AppColors.blue,
  PoiKind.nature => AppColors.green,
  PoiKind.craft => const Color(0xFFE37400),
  PoiKind.food => const Color(0xFFD93025),
  PoiKind.stay => const Color(0xFF9334E6),
  _ => AppColors.red,
};

/// Craft shops & makers on the Explore map: distinct from the orange
/// "Crafts" points of interest.
const shopColor = Color(0xFF00897B);
const shopIcon = Icons.storefront_outlined;

/// Town markers on the Explore map (the selected town turns blue).
const townColor = Color(0xFF455A64);
const townIcon = Icons.location_city_outlined;

IconData pastTripIcon(String kind) => switch (kind) {
  'waterfall' => Icons.water_drop_outlined,
  'trek' => Icons.hiking,
  'lake' => Icons.waves,
  'monastery' => Icons.temple_buddhist_outlined,
  'river' => Icons.kayaking_outlined,
  _ => Icons.landscape_outlined,
};

Color tint(Color c, [double a = 0.12]) =>
    Color.alphaBlend(c.withValues(alpha: a), Colors.white);

/// Icon for a WMO weather code (Open-Meteo); a thermometer when unknown.
IconData weatherIcon(int? code) => switch (code) {
  null => Icons.thermostat_outlined,
  0 || 1 => Icons.wb_sunny_outlined,
  2 => Icons.wb_cloudy_outlined,
  3 => Icons.cloud_outlined,
  45 || 48 => Icons.foggy,
  >= 51 && <= 67 => Icons.water_drop_outlined,
  >= 71 && <= 77 => Icons.ac_unit,
  >= 80 && <= 82 => Icons.grain,
  85 || 86 => Icons.ac_unit,
  >= 95 => Icons.thunderstorm_outlined,
  _ => Icons.cloud_outlined,
};

/// Short description of a WMO weather code.
String weatherLabel(int? code) => switch (code) {
  null => '',
  0 => 'Clear',
  1 => 'Mostly clear',
  2 => 'Partly cloudy',
  3 => 'Overcast',
  45 || 48 => 'Fog',
  >= 51 && <= 57 => 'Drizzle',
  >= 61 && <= 67 => 'Rain',
  >= 71 && <= 77 => 'Snow',
  >= 80 && <= 82 => 'Showers',
  85 || 86 => 'Snow showers',
  >= 95 => 'Thunderstorm',
  _ => 'Cloudy',
};

IconData seasonIconData(SeasonIcon s) => switch (s) {
  SeasonIcon.snow => Icons.ac_unit,
  SeasonIcon.flower => Icons.local_florist_outlined,
  SeasonIcon.sun => Icons.wb_sunny_outlined,
  SeasonIcon.leaf => Icons.eco_outlined,
};

Color seasonColor(SeasonIcon s) => switch (s) {
  SeasonIcon.snow => const Color(0xFF1A73E8),
  SeasonIcon.flower => const Color(0xFFD01884),
  SeasonIcon.sun => const Color(0xFFE37400),
  SeasonIcon.leaf => const Color(0xFF188038),
};
