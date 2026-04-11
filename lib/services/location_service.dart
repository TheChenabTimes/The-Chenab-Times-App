import 'dart:async';
import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class LocationService extends ChangeNotifier {
  static const _cityKey = 'location_city';
  static const _districtKey = 'location_district';
  static const _stateKey = 'location_state';
  static const _countryKey = 'location_country';
  static const _latitudeKey = 'location_latitude';
  static const _longitudeKey = 'location_longitude';
  static const _tempKey = 'location_temperature';
  static const _weatherLabelKey = 'location_weather_label';

  String? _city;
  String? _district;
  String? _state;
  String? _country;
  double? _latitude;
  double? _longitude;
  double? _temperature;
  String? _weatherLabel;
  bool _loading = false;
  String? _error;

  String? get city => _city;
  String? get district => _district;
  String? get state => _state;
  String? get country => _country;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  double? get temperature => _temperature;
  String? get weatherLabel => _weatherLabel;
  bool get loading => _loading;
  String? get error => _error;

  String get headlineLocation {
    if ((_state ?? '').isNotEmpty) return _state!;
    if ((_city ?? '').isNotEmpty) return _city!;
    if ((_country ?? '').isNotEmpty) return _country!;
    return 'your region';
  }

  List<String> get interestKeywords {
    final values = <String>{
      if ((_city ?? '').isNotEmpty) _city!,
      if ((_district ?? '').isNotEmpty) _district!,
      if ((_state ?? '').isNotEmpty) _state!,
      if ((_country ?? '').isNotEmpty) _country!,
    };

    if ((_country ?? '').toLowerCase() == 'india' &&
        (_state ?? '').isNotEmpty) {
      values.add('India');
      values.add(_state!);
    }

    return values.where((item) => item.trim().isNotEmpty).toList();
  }

  List<String> get locationLookupTerms {
    final values = <String>{
      ...interestKeywords,
      if ((_city ?? '').toLowerCase().startsWith('new '))
        _city!.substring(4).trim(),
      if ((_city ?? '').toLowerCase().startsWith('old '))
        _city!.substring(4).trim(),
    };
    return values.where((item) => item.trim().isNotEmpty).toList();
  }

  Future<void> init() async {
    await _loadCachedLocation();
    unawaited(refreshLocation());
  }

  Future<void> refreshLocation() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission was not granted.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _latitude = position.latitude;
      _longitude = position.longitude;

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _city = _pickFirstNonEmpty([place.locality, place.subLocality]);
        _district = _pickFirstNonEmpty([
          place.subAdministrativeArea,
          place.locality,
        ]);
        _state = _pickFirstNonEmpty([
          place.administrativeArea,
          place.subAdministrativeArea,
        ]);
        _country = place.country;
      }

      await _fetchWeather(position.latitude, position.longitude);
      await _persist();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchWeather(double latitude, double longitude) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$latitude&longitude=$longitude'
      '&current=temperature_2m,weather_code',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) return;

    final Map<String, dynamic> data = jsonDecode(response.body);
    final current = data['current'] as Map<String, dynamic>?;
    if (current == null) return;

    final temp = current['temperature_2m'];
    final code = current['weather_code'];
    if (temp is num) _temperature = temp.toDouble();
    if (code is num) _weatherLabel = _weatherLabelForCode(code.toInt());
  }

  Future<WeatherForecast?> fetchWeatherForecast({int days = 3}) async {
    final latitude = _latitude;
    final longitude = _longitude;

    if (latitude == null || longitude == null) {
      await refreshLocation();
    }

    if (_latitude == null || _longitude == null) return null;

    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${_latitude!}&longitude=${_longitude!}'
      '&timezone=auto'
      '&forecast_days=$days'
      '&current=temperature_2m,apparent_temperature,weather_code,wind_speed_10m,relative_humidity_2m'
      '&hourly=temperature_2m,apparent_temperature,precipitation_probability,weather_code,wind_speed_10m'
      '&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw Exception('Failed to load forecast data.');
    }

    final Map<String, dynamic> data = jsonDecode(response.body);
    return WeatherForecast.fromJson(data);
  }

  Future<void> _loadCachedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    _city = prefs.getString(_cityKey);
    _district = prefs.getString(_districtKey);
    _state = prefs.getString(_stateKey);
    _country = prefs.getString(_countryKey);
    _latitude = prefs.getDouble(_latitudeKey);
    _longitude = prefs.getDouble(_longitudeKey);
    _temperature = prefs.getDouble(_tempKey);
    _weatherLabel = prefs.getString(_weatherLabelKey);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cityKey, _city ?? '');
    await prefs.setString(_districtKey, _district ?? '');
    await prefs.setString(_stateKey, _state ?? '');
    await prefs.setString(_countryKey, _country ?? '');
    if (_latitude != null) {
      await prefs.setDouble(_latitudeKey, _latitude!);
    }
    if (_longitude != null) {
      await prefs.setDouble(_longitudeKey, _longitude!);
    }
    if (_temperature != null) {
      await prefs.setDouble(_tempKey, _temperature!);
    }
    await prefs.setString(_weatherLabelKey, _weatherLabel ?? '');
  }

  String? _pickFirstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return null;
  }

  String _weatherLabelForCode(int code) {
    switch (code) {
      case 0:
        return 'Clear';
      case 1:
      case 2:
      case 3:
        return 'Cloudy';
      case 45:
      case 48:
        return 'Fog';
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
      case 65:
      case 80:
      case 81:
      case 82:
        return 'Rain';
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return 'Snow';
      case 95:
      case 96:
      case 99:
        return 'Storm';
      default:
        return 'Weather';
    }
  }
}

class WeatherForecast {
  WeatherForecast({
    required this.current,
    required this.hourly,
    required this.daily,
  });

  final CurrentWeather current;
  final List<HourlyWeather> hourly;
  final List<DailyWeather> daily;

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    final currentJson = json['current'] as Map<String, dynamic>? ?? {};
    final hourlyJson = json['hourly'] as Map<String, dynamic>? ?? {};
    final dailyJson = json['daily'] as Map<String, dynamic>? ?? {};

    final hourlyTimes = (hourlyJson['time'] as List<dynamic>? ?? [])
        .map((entry) => DateTime.tryParse(entry.toString()))
        .toList();
    final hourlyTemps = hourlyJson['temperature_2m'] as List<dynamic>? ?? [];
    final hourlyFeelsLike =
        hourlyJson['apparent_temperature'] as List<dynamic>? ?? [];
    final hourlyRain =
        hourlyJson['precipitation_probability'] as List<dynamic>? ?? [];
    final hourlyCodes = hourlyJson['weather_code'] as List<dynamic>? ?? [];
    final hourlyWind = hourlyJson['wind_speed_10m'] as List<dynamic>? ?? [];

    final hourlyItems = <HourlyWeather>[];
    for (var i = 0; i < hourlyTimes.length; i++) {
      final time = hourlyTimes[i];
      if (time == null) continue;
      hourlyItems.add(
        HourlyWeather(
          time: time,
          temperature: _numAt(hourlyTemps, i),
          apparentTemperature: _numAt(hourlyFeelsLike, i),
          precipitationProbability: _numAt(hourlyRain, i)?.round(),
          weatherCode: _numAt(hourlyCodes, i)?.round(),
          windSpeed: _numAt(hourlyWind, i),
        ),
      );
    }

    final dailyTimes = (dailyJson['time'] as List<dynamic>? ?? [])
        .map((entry) => DateTime.tryParse(entry.toString()))
        .toList();
    final dailyMax = dailyJson['temperature_2m_max'] as List<dynamic>? ?? [];
    final dailyMin = dailyJson['temperature_2m_min'] as List<dynamic>? ?? [];
    final dailyRain =
        dailyJson['precipitation_probability_max'] as List<dynamic>? ?? [];
    final dailyCodes = dailyJson['weather_code'] as List<dynamic>? ?? [];
    final sunrise = dailyJson['sunrise'] as List<dynamic>? ?? [];
    final sunset = dailyJson['sunset'] as List<dynamic>? ?? [];

    final dailyItems = <DailyWeather>[];
    for (var i = 0; i < dailyTimes.length; i++) {
      final date = dailyTimes[i];
      if (date == null) continue;
      dailyItems.add(
        DailyWeather(
          date: date,
          maxTemperature: _numAt(dailyMax, i),
          minTemperature: _numAt(dailyMin, i),
          precipitationProbability: _numAt(dailyRain, i)?.round(),
          weatherCode: _numAt(dailyCodes, i)?.round(),
          sunrise: DateTime.tryParse(_stringAt(sunrise, i) ?? ''),
          sunset: DateTime.tryParse(_stringAt(sunset, i) ?? ''),
        ),
      );
    }

    return WeatherForecast(
      current: CurrentWeather(
        temperature: (currentJson['temperature_2m'] as num?)?.toDouble(),
        apparentTemperature: (currentJson['apparent_temperature'] as num?)
            ?.toDouble(),
        weatherCode: (currentJson['weather_code'] as num?)?.toInt(),
        windSpeed: (currentJson['wind_speed_10m'] as num?)?.toDouble(),
        humidity: (currentJson['relative_humidity_2m'] as num?)?.toInt(),
      ),
      hourly: hourlyItems,
      daily: dailyItems,
    );
  }

  static double? _numAt(List<dynamic> items, int index) {
    if (index >= items.length) return null;
    final value = items[index];
    return value is num ? value.toDouble() : double.tryParse('$value');
  }

  static String? _stringAt(List<dynamic> items, int index) {
    if (index >= items.length) return null;
    return items[index]?.toString();
  }
}

class CurrentWeather {
  CurrentWeather({
    required this.temperature,
    required this.apparentTemperature,
    required this.weatherCode,
    required this.windSpeed,
    required this.humidity,
  });

  final double? temperature;
  final double? apparentTemperature;
  final int? weatherCode;
  final double? windSpeed;
  final int? humidity;
}

class HourlyWeather {
  HourlyWeather({
    required this.time,
    required this.temperature,
    required this.apparentTemperature,
    required this.precipitationProbability,
    required this.weatherCode,
    required this.windSpeed,
  });

  final DateTime time;
  final double? temperature;
  final double? apparentTemperature;
  final int? precipitationProbability;
  final int? weatherCode;
  final double? windSpeed;
}

class DailyWeather {
  DailyWeather({
    required this.date,
    required this.maxTemperature,
    required this.minTemperature,
    required this.precipitationProbability,
    required this.weatherCode,
    required this.sunrise,
    required this.sunset,
  });

  final DateTime date;
  final double? maxTemperature;
  final double? minTemperature;
  final int? precipitationProbability;
  final int? weatherCode;
  final DateTime? sunrise;
  final DateTime? sunset;
}
