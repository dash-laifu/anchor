import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:anchor/models/parking_spot.dart';

class LocationService {
  static const Duration locationTimeout = Duration(seconds: 6);

  static Future<bool> checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  static Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkPermissions();
      if (!hasPermission) {
        return null;
      }

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      );

      return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
        timeLimit: locationTimeout,
      );
    } catch (e) {
      // Fallback to last known position if current fails
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (e) {
        return null;
      }
    }
  }

  static Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        List<String> parts = [];
        
        if (place.name?.isNotEmpty == true) parts.add(place.name!);
        if (place.street?.isNotEmpty == true) parts.add(place.street!);
        if (place.locality?.isNotEmpty == true) parts.add(place.locality!);
        
        return parts.take(2).join(', ');
      }
    } catch (e) {
      // Silently fail reverse geocoding
    }
    return null;
  }

  static double calculateDistance(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  static String formatDistance(double meters, String unit) {
    if (unit == 'mi') {
      double miles = meters * 0.000621371;
      if (miles < 0.1) {
        return '${(meters * 3.28084).round()}ft';
      }
      return '${miles.toStringAsFixed(1)}mi';
    } else {
      if (meters < 1000) {
        return '${meters.round()}m';
      }
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  static double calculateBearing(
    double lat1, double lon1,
    double lat2, double lon2,
  ) {
    final dLon = (lon2 - lon1) * pi / 180;
    final lat1Rad = lat1 * pi / 180;
    final lat2Rad = lat2 * pi / 180;

    final y = sin(dLon) * cos(lat2Rad);
    final x = cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLon);

    final bearing = atan2(y, x) * 180 / pi;
    return (bearing + 360) % 360;
  }

  static String formatBearing(double bearing) {
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((bearing + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  static ParkingLocationAccuracy getAccuracyLevel(double accuracyMeters) {
    if (accuracyMeters <= 25) return ParkingLocationAccuracy.high;
    if (accuracyMeters <= 75) return ParkingLocationAccuracy.medium;
    return ParkingLocationAccuracy.low;
  }

  static Future<String> launchNavigation(
    double latitude,
    double longitude,
    String? preferredApp,
  ) async {
    // Return URL for external navigation
    if (preferredApp == 'apple_maps') {
      return 'http://maps.apple.com/?daddr=$latitude,$longitude&dirflg=w';
    } else {
      return 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&travelmode=walking';
    }
  }
}