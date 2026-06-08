import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:weatherx/models/weather_model.dart';

import '../models/city_suggestion.dart';
import '../utils/api.dart';


class WeatherServices {
  final String apiKey;

  WeatherServices(this.apiKey);

  Future<WeatherModel> getWeather(String cityName) async {
    debugPrint('[WeatherService] getWeather called with city: "$cityName"');

    if (cityName.isEmpty) {
      debugPrint(
        '[WeatherService] ERROR: city name is empty, cannot fetch weather',
      );
      throw Exception('City name is empty');
    }

    final url = Uri.parse(
      '${Api.baseUrl}?q=$cityName&appid=$apiKey&units=metric',
    );
    debugPrint(
      '[WeatherService] Request URL: ${Api.baseUrl}?q=$cityName&appid=***&units=metric',
    );

    final response = await http.get(url);
    debugPrint('[WeatherService] Response status: ${response.statusCode}');
    debugPrint('[WeatherService] Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final weather = WeatherModel.fromJson(data);
      debugPrint(
        '[WeatherService] Weather loaded: city=${weather.cityName}, temp=${weather.temperature}',
      );
      return weather;
    } else {
      throw Exception(
        'Failed to load weather: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<String> getCurrentCity() async {
    debugPrint('[WeatherService] getCurrentCity started');

    LocationPermission permission = await Geolocator.checkPermission();
    debugPrint('[WeatherService] Initial permission: $permission');

    if (permission == LocationPermission.denied) {
      debugPrint('[WeatherService] Requesting location permission...');
      permission = await Geolocator.requestPermission();
      debugPrint('[WeatherService] Permission after request: $permission');
    }

    if (permission == LocationPermission.denied) {
      debugPrint('[WeatherService] ERROR: location permission denied');
      throw Exception('Location permission denied');
    }
    if (permission == LocationPermission.deniedForever) {
      debugPrint(
        '[WeatherService] ERROR: location permission permanently denied',
      );
      throw Exception('Location permission permanently denied');
    }

    debugPrint('[WeatherService] Fetching current position...');
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    debugPrint(
      '[WeatherService] Position: lat=${position.latitude}, lon=${position.longitude}',
    );

    debugPrint('[WeatherService] Reverse geocoding coordinates...');
    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    debugPrint('[WeatherService] Placemarks found: ${placemarks.length}');

    if (placemarks.isEmpty) {
      debugPrint(
        '[WeatherService] ERROR: no placemarks returned from geocoding',
      );
      throw Exception('No placemarks found for current location');
    }

    final place = placemarks.first;
    debugPrint(
      '[WeatherService] Placemark: locality=${place.locality}, '
      'subAdministrativeArea=${place.subAdministrativeArea}, '
      'administrativeArea=${place.administrativeArea}, '
      'country=${place.country}',
    );

    final city =
        place.locality ??
        place.subAdministrativeArea ??
        place.administrativeArea ??
        '';

    if (city.isEmpty) {
      debugPrint(
        '[WeatherService] ERROR: could not resolve city name from placemark',
      );
      throw Exception('Could not resolve city name from location');
    }

    debugPrint('[WeatherService] Resolved city: "$city"');
    return city;
  }

  Future<WeatherModel> getWeatherByCoords(double lat, double lon) async {
    debugPrint('[WeatherService] getWeatherByCoords: lat=$lat, lon=$lon');

    final url = Uri.parse(
      '${Api.baseUrl}?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
    );

    final response = await http.get(url);
    debugPrint('[WeatherService] coords response: ${response.statusCode}');

    if (response.statusCode == 200) {
      return WeatherModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(
      'Failed to load weather: ${response.statusCode} - ${response.body}',
    );
  }

  Future<List<CitySuggestion>> searchCities(String query, {int limit = 10}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final url = Uri.parse(
      '${Api.geoUrl}?q=${Uri.encodeQueryComponent(trimmed)}&limit=$limit&appid=$apiKey',
    );
    debugPrint('[WeatherService] geocoding "$trimmed"');

    final response = await http.get(url);
    if (response.statusCode != 200) {
      debugPrint('[WeatherService] geocoding failed: ${response.statusCode}');
      return const [];
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .whereType<Map<String, dynamic>>()
        .map(CitySuggestion.fromJson)
        .toList();
  }
}
