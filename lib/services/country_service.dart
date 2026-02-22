import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class CountryService {
  static Map<String, dynamic>? _countries;

  /// Carga el JSON una sola vez (singleton cache)
  static Future<void> loadCountries() async {
    if (_countries != null) return;

    final jsonString = await rootBundle.loadString('assets/data/countries.json');
    _countries = json.decode(jsonString);
  }

  /// Retorna lista de países ordenados alfabéticamente
  static List<Map<String, String>> getCountries() {
    final list = <Map<String, String>>[];

    _countries!.forEach((code, data) {
      list.add({
        "code": code,
        "name": data["name"],
      });
    });

    list.sort((a, b) => a["name"]!.compareTo(b["name"]!));
    return list;
  }

  /// Retorna lista de ciudades para un país
  static List<String> getCities(String countryCode) {
    final cities = _countries![countryCode]["cities"] as List<dynamic>;
    return cities.map((c) => c.toString()).toList();
  }
}