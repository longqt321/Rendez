import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rendez/core/api/api_client.dart';
import 'package:rendez/core/utils/estimates.dart';

/// Product acceptance limit for centering and user-relative distance estimates.
/// Requested high accuracy is a preference; the returned accuracy must be checked.
const maxUserLocationAccuracyMeters = 500.0;

void validateUserPosition(Position position) {
  if (!validCoordinates(position.latitude, position.longitude) ||
      !position.accuracy.isFinite ||
      position.accuracy < 0) {
    throw const ApiException('Chưa xác định được vị trí của bạn. Hãy thử lại.');
  }
  if (position.accuracy > maxUserLocationAccuracyMeters) {
    throw ApiException(
      'Vị trí chưa đủ chính xác (sai số khoảng ${formatDistance(position.accuracy / 1000)}). Thử lại hoặc dùng điện thoại có GPS.',
    );
  }
}

Future<Position> getCurrentUserPosition() async {
  // On web, getCurrentPosition handles the browser permission prompt itself.
  // requestPermission performs a separate low-accuracy lookup in geolocator_web.
  if (!kIsWeb) {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const ApiException('Bật vị trí trên thiết bị rồi thử lại.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const ApiException('Cho phép Rendez dùng vị trí rồi thử lại.');
    }
  }
  try {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: kIsWeb
          ? WebSettings(
              accuracy: LocationAccuracy.best,
              maximumAge: Duration.zero,
              timeLimit: Duration(seconds: 15),
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.best,
              timeLimit: Duration(seconds: 15),
            ),
    );
    validateUserPosition(position);
    return position;
  } on PermissionDeniedException {
    throw const ApiException('Cho phép Rendez dùng vị trí rồi thử lại.');
  }
}
