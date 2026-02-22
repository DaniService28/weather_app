import 'package:flutter/material.dart';
import '../services/country_service.dart';
import 'select_city_screen.dart';

class SelectCountryScreen extends StatefulWidget {
  @override
  _SelectCountryScreenState createState() => _SelectCountryScreenState();
}

class _SelectCountryScreenState extends State<SelectCountryScreen> {
  List<Map<String, String>> _countries = [];
  List<Map<String, String>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await CountryService.loadCountries();
    final list = CountryService.getCountries();

    setState(() {
      _countries = list;
      _filtered = list;
    });
  }

  void _search(String query) {
    setState(() {
      _filtered = _countries
          .where((c) => c["name"]!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Country")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search country",
                border: OutlineInputBorder(),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final country = _filtered[i];
                return ListTile(
                  title: Text(country["name"]!),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SelectCityScreen(
                          countryCode: country["code"]!,
                          countryName: country["name"]!,
                        ),
                      ),
                    );

                    if (result != null) {
                      Navigator.pop(context, result); // ← CLAVE
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
