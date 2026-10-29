import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'town_guides.dart';

/// Current conditions at one point.
class WeatherReading {
  const WeatherReading({required this.tempC, this.code});
  final double tempC;

  /// WMO weather code (Open-Meteo `weather_code`), if known.
  final int? code;
}

/// Source of live weather for towns on the Explore map.
///
/// TODO(api): [OpenMeteoWeatherRepository] uses the free, key-less
/// Open-Meteo API. Swap in another provider (or our own backend proxy)
/// by implementing this interface and passing it to `ExploreScreen`.
abstract class WeatherRepository {
  /// Current weather per town id. Throws on network / parse errors.
  Future<Map<String, WeatherReading>> current(List<MapTown> towns);
}

/// https://open-meteo.com: no API key; several coordinates per request.
class OpenMeteoWeatherRepository implements WeatherRepository {
  OpenMeteoWeatherRepository({
    this._client,
    this.timeout = const Duration(seconds: 8),
  });

  final http.Client? _client;
  final Duration timeout;

  static Uri uriFor(List<MapTown> towns) =>
      Uri.https('api.open-meteo.com', '/v1/forecast', {
        'latitude': towns.map((t) => t.lat.toStringAsFixed(4)).join(','),
        'longitude': towns.map((t) => t.lng.toStringAsFixed(4)).join(','),
        'current': 'temperature_2m,weather_code',
        'timezone': 'Asia/Kolkata',
      });

  @override
  Future<Map<String, WeatherReading>> current(List<MapTown> towns) async {
    if (towns.isEmpty) return const {};
    final client = _client ?? http.Client();
    try {
      final res = await client.get(uriFor(towns)).timeout(timeout);
      if (res.statusCode != 200) {
        throw http.ClientException('HTTP ${res.statusCode}');
      }
      final body = jsonDecode(res.body);
      final list = body is List ? body : [body];
      return {
        for (final (i, t) in towns.indexed)
          if (i < list.length) t.id: _parse(list[i] as Map<String, dynamic>),
      };
    } finally {
      if (_client == null) client.close();
    }
  }

  static WeatherReading _parse(Map<String, dynamic> json) {
    final cur = json['current'] as Map<String, dynamic>;
    return WeatherReading(
      tempC: (cur['temperature_2m'] as num).toDouble(),
      code: (cur['weather_code'] as num?)?.toInt(),
    );
  }
}

/// Never returns data; for tests and offline previews.
class OfflineWeatherRepository implements WeatherRepository {
  const OfflineWeatherRepository();

  @override
  Future<Map<String, WeatherReading>> current(List<MapTown> towns) =>
      Future.error(const SocketLikeException());
}

class SocketLikeException implements Exception {
  const SocketLikeException();
  @override
  String toString() => 'offline';
}

enum WeatherSource { live, cached, typical }

/// What the UI shows for one town.
class TownWeather {
  const TownWeather({
    required this.tempC,
    required this.source,
    this.code,
    this.updatedAt,
  });

  final double tempC;
  final int? code;
  final WeatherSource source;
  final DateTime? updatedAt;

  /// e.g. "12°".
  String get short => '${tempC.round()}°';
}

/// Loads cached weather from shared_preferences, refreshes it from the
/// [WeatherRepository] in the background, and falls back to a seasonal
/// typical temperature (from [TownGuides]) when nothing is known. Never
/// blocks the UI: every call has a timeout and errors are swallowed.
class WeatherStore extends ChangeNotifier {
  WeatherStore({WeatherRepository? repository, DateTime Function()? clock})
    : repository = repository ?? OpenMeteoWeatherRepository(),
      _clock = clock ?? DateTime.now;

  final WeatherRepository repository;
  final DateTime Function() _clock;

  static const cacheKey = 'weather_cache_v1';

  /// Values younger than this count as live.
  static const freshFor = Duration(minutes: 30);

  final Map<String, ({double t, int? code, DateTime at})> _values = {};
  bool _disposed = false;
  bool _refreshing = false;

  /// Reads the cache, then refreshes from the network. Safe to call again.
  Future<void> init(List<MapTown> towns) async {
    await _loadCache();
    await refresh(towns);
  }

  Future<void> _loadCache() async {
    try {
      final sp = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 1),
      );
      final raw = sp.getString(cacheKey);
      if (raw == null) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      for (final e in map.entries) {
        final v = e.value as Map<String, dynamic>;
        _values[e.key] = (
          t: (v['t'] as num).toDouble(),
          code: (v['c'] as num?)?.toInt(),
          at: DateTime.fromMillisecondsSinceEpoch(v['at'] as int),
        );
      }
      _notify();
    } catch (e) {
      debugPrint('Weather cache unavailable: $e');
    }
  }

  Future<void> refresh(List<MapTown> towns) async {
    if (_refreshing || towns.isEmpty) return;
    _refreshing = true;
    try {
      final fresh = await repository.current(towns);
      final now = _clock();
      for (final e in fresh.entries) {
        _values[e.key] = (t: e.value.tempC, code: e.value.code, at: now);
      }
      _notify();
      await _saveCache();
    } catch (e) {
      debugPrint('Live weather unavailable, using cache/typical: $e');
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _saveCache() async {
    try {
      final sp = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 2),
      );
      await sp.setString(
        cacheKey,
        jsonEncode({
          for (final e in _values.entries)
            e.key: {
              't': e.value.t,
              'c': e.value.code,
              'at': e.value.at.millisecondsSinceEpoch,
            },
        }),
      );
    } catch (e) {
      debugPrint('Could not save weather cache: $e');
    }
  }

  /// Live or cached reading, else the typical temperature for this month,
  /// else null (town without a guide).
  TownWeather? forTown(String townId) {
    final v = _values[townId];
    if (v != null) {
      final live = _clock().difference(v.at) < freshFor;
      return TownWeather(
        tempC: v.t,
        code: v.code,
        source: live ? WeatherSource.live : WeatherSource.cached,
        updatedAt: v.at,
      );
    }
    final guide = TownGuides.byId(townId);
    if (guide == null) return null;
    return TownWeather(
      tempC: guide.typicalC(_clock().month).toDouble(),
      source: WeatherSource.typical,
    );
  }

  /// "now", "updated 3h ago", "typical for Oct".
  String noteFor(TownWeather w) {
    switch (w.source) {
      case WeatherSource.live:
        return 'now';
      case WeatherSource.cached:
        final age = _clock().difference(w.updatedAt!);
        final ago = age.inDays >= 1
            ? '${age.inDays}d'
            : age.inHours >= 1
            ? '${age.inHours}h'
            : '${age.inMinutes}m';
        return 'updated $ago ago';
      case WeatherSource.typical:
        return 'typical for ${_months[_clock().month - 1]}';
    }
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
