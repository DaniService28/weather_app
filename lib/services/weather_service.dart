import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import '../screens/daily_forecast.dart';
import '../models/hourly_forecast.dart';

class WeatherService {
  final String _apiKey = '77879ef9754f362461adbcdefa0a83ad';

  Future<WeatherModel> getWeather(String cityName) async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?q=$cityName&appid=$_apiKey&units=metric&lang=es';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return WeatherModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al obtener el clima');
    }
  }

  Future<List<DailyForecast>> getFiveDayForecast(String cityName) async {
    final url =
        'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&appid=$_apiKey&units=metric&lang=en';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['list'];

      Map<String, List> grouped = {};

      for (var item in list) {
        final rawDate = item['dt_txt'];
        final parsed = DateTime.tryParse(rawDate);

        if (parsed == null) continue;

        final dayKey = "${parsed.year}-${parsed.month}-${parsed.day}";

        grouped.putIfAbsent(dayKey, () => []);
        grouped[dayKey]!.add(item);
      }

      List<DailyForecast> forecasts = [];

      grouped.forEach((key, items) {
        if (items.isEmpty) return;

        double minTemp = 999;
        double maxTemp = -999;

        String icon = items.first['weather'][0]['icon'];
        String description = items.first['weather'][0]['description'];

        for (var item in items) {
          final tempMin = (item['main']['temp_min'] as num).toDouble();
          final tempMax = (item['main']['temp_max'] as num).toDouble();

          if (tempMin < minTemp) minTemp = tempMin;
          if (tempMax > maxTemp) maxTemp = tempMax;
        }

        final parsed = DateTime.tryParse(items.first['dt_txt']);
        if (parsed == null) return;

        final safeDate = DateTime(parsed.year, parsed.month, parsed.day);

        forecasts.add(
          DailyForecast(
            date: safeDate,
            minTemp: minTemp,
            maxTemp: maxTemp,
            icon: icon,
            description: description,
          ),
        );
      });

      return forecasts.take(5).toList();
    } else {
      throw Exception('Error fetching forecast');
    }
  }

  Future<List<HourlyForecast>> getHourlyForecast(String cityName) async {
    final url =
        'https://api.openweathermap.org/data/2.5/forecast?q=$cityName&appid=$_apiKey&units=metric&lang=es';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List list = data['list'];

      List<HourlyForecast> hourly = [];

      for (var item in list.take(8)) {
        // solo las próximas 24 horas (8 bloques)
        final rawDate = item['dt_txt'];
        final parsed = DateTime.tryParse(rawDate);
        if (parsed == null) continue;

        final temp = (item['main']['temp'] as num).toDouble();
        final icon = item['weather'][0]['icon'];
        final description = item['weather'][0]['description'];

        hourly.add(
          HourlyForecast(
            date: parsed,
            temp: temp,
            icon: icon,
            description: description,
          ),
        );
      }

      return hourly;
    } else {
      throw Exception('Error fetching hourly forecast');
    }
  }

  Future<WeatherModel> getWeatherByCoords(double lat, double lon) async {
    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$_apiKey&units=metric&lang=es';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return WeatherModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error obtaining weather by coordinates');
    }
  }
}
