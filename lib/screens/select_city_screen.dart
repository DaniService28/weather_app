import 'package:flutter/material.dart';
import '../services/country_service.dart';

class SelectCityScreen extends StatefulWidget {
  final String countryCode;
  final String countryName;

  const SelectCityScreen({
    required this.countryCode,
    required this.countryName,
  });

  @override
  _SelectCityScreenState createState() => _SelectCityScreenState();
}

class _SelectCityScreenState extends State<SelectCityScreen> {
  List<String> _cities = [];
  List<String> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final list = CountryService.getCities(widget.countryCode);
    setState(() {
      _cities = list;
      _filtered = list;
    });
  }

  void _search(String query) {
    setState(() {
      _filtered = _cities
          .where((c) => c.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select City — ${widget.countryName}")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search city",
                border: OutlineInputBorder(),
              ),
              onChanged: _search,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final city = _filtered[i];
                return ListTile(
                  title: Text(city),
                  onTap: () {
                    Navigator.pop(context, {
                      "city": city,
                      "countryCode": widget.countryCode,
                    });
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
