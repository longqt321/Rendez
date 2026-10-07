import 'dart:math' as math;

bool validCoordinates(double lat, double lng) =>
    lat.isFinite &&
    lng.isFinite &&
    lat >= -90 &&
    lat <= 90 &&
    lng >= -180 &&
    lng <= 180;

double? distanceKm(
  double lat,
  double lng,
  double destinationLat,
  double destinationLng,
) {
  if (!validCoordinates(lat, lng) ||
      !validCoordinates(destinationLat, destinationLng)) {
    return null;
  }
  final radians = math.pi / 180;
  final a =
      math.pow(math.sin((destinationLat - lat) * radians / 2), 2) +
      math.cos(lat * radians) *
          math.cos(destinationLat * radians) *
          math.pow(math.sin((destinationLng - lng) * radians / 2), 2);
  return 6371 * 2 * math.asin(math.sqrt(a.clamp(0, 1)));
}

String formatDistance(double km) =>
    km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
