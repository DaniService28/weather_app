import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../models/weather_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../screens/daily_forecast.dart';
import '../models/hourly_forecast.dart';
import '../screens/select_country_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<HourlyForecast>? _hourly;
  List<String> _favoriteCities = [];
  List<DailyForecast>? _forecast;

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');
    return "$hours:$minutes";
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _favoriteCities = prefs.getStringList('favorites') ?? [];
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('El GPS está desactivado.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permiso de ubicación denegado.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permiso de ubicación denegado permanentemente.');
    }

    return await Geolocator.getCurrentPosition();
  }

  final TextEditingController _cityController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(title: const Text('Weather App')),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        constraints: const BoxConstraints.expand(),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _weather == null
                ? [Colors.blue.shade200, Colors.white]
                : _getBackgroundGradient(_weather!.description),
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  TextField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      hintText: 'Enter a city name',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onSubmitted: (value) async {
                      if (value.isEmpty) return;

                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });

                      try {
                        final weatherData = await _weatherService.getWeather(
                          value,
                        );

                        setState(() {
                          _weather = weatherData;
                        });

                        final forecastData = await _weatherService
                            .getFiveDayForecast(value);
                        setState(() {
                          _forecast = forecastData;
                        });

                        final hourlyData = await _weatherService
                            .getHourlyForecast(value);
                        setState(() {
                          _hourly = hourlyData;
                        });
                      } catch (e) {
                        setState(() {
                          _errorMessage =
                              'City not found. Please try another city. $e';
                        });
                      } finally {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Abre el selector de país/ciudad
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SelectCountryScreen(),
                          ),
                        );

                        // Si el usuario seleccionó algo
                        if (result != null) {
                          final city = result["city"];
                          final countryCode = result["countryCode"];

                          setState(() {
                            _isLoading = true;
                            _errorMessage = null;
                          });

                          try {
                            final weatherData = await _weatherService
                                .getWeather("$city,$countryCode");
                            final forecastData = await _weatherService
                                .getFiveDayForecast("$city,$countryCode");
                            final hourlyData = await _weatherService
                                .getHourlyForecast("$city,$countryCode");

                            setState(() {
                              _weather = weatherData;
                              _forecast = forecastData;
                              _hourly = hourlyData;
                            });
                          } catch (e) {
                            setState(() {
                              _errorMessage =
                                  'City not found. Please try another city. $e';
                            });
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
                      child: const Text('Select City'),
                    ),
                  ),

                  TextButton(
                    onPressed: () async {
                      try {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });

                        final position = await _determinePosition();

                        final weatherData = await _weatherService
                            .getWeatherByCoords(
                              position.latitude,
                              position.longitude,
                            );

                        final forecastData = await _weatherService
                            .getFiveDayForecast(weatherData.cityName);

                        final hourlyData = await _weatherService
                            .getHourlyForecast(weatherData.cityName);

                        setState(() {
                          _weather = weatherData;
                          _forecast = forecastData;
                          _hourly = hourlyData;
                        });
                      } catch (e) {
                        setState(() {
                          _errorMessage = e.toString();
                        });
                      } finally {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    },
                    child: const Text("Use Current Location"),
                  ),

                  if (_isLoading) ...[
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                  ],

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ],

                  if (_favoriteCities.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      "Favorite Cities:",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    ..._favoriteCities.map((city) {
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.star, color: Colors.amber),
                          title: Text(city),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              _favoriteCities.remove(city);
                              await prefs.setStringList(
                                'favorites',
                                _favoriteCities,
                              );
                              setState(() {});
                            },
                          ),
                          onTap: () async {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });

                            try {
                              // 1. Clima actual
                              final weatherData = await _weatherService
                                  .getWeather(city);

                              // 2. Forecast de 5 días
                              final forecastData = await _weatherService
                                  .getFiveDayForecast(city);

                              // 3. Forecast por horas
                              final hourlyData = await _weatherService
                                  .getHourlyForecast(city);

                              // 4. Actualizar UI
                              setState(() {
                                _weather = weatherData;
                                _forecast = forecastData;
                                _hourly = hourlyData;
                              });
                            } catch (e) {
                              setState(() {
                                _errorMessage = 'Failed to get weather data.';
                              });
                            } finally {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          },
                        ),
                      );
                    }),
                  ],

                  if (_weather != null) ...[
                    const SizedBox(height: 20),
                    Transform.translate(
                      offset: const Offset(0, -10),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 0.1),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: _weather == null
                            ? const SizedBox()
                            : Card(
                                key: ValueKey(_weather!.cityName),
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        _weather!.cityName,
                                        style: const TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                        ),
                                      ),

                                      const SizedBox(height: 10),

                                      Image.network(
                                        'https://openweathermap.org/img/wn/${_weather!.icon}@2x.png',
                                        width: 150,
                                        height: 150,
                                      ),

                                      Text(
                                        '${_weather!.temperature}°C',
                                        style: const TextStyle(fontSize: 40),
                                      ),

                                      Text(
                                        _weather!.description,
                                        style: const TextStyle(fontSize: 20),
                                      ),

                                      const SizedBox(height: 10),

                                      const Divider(height: 30, thickness: 1),

                                      // ⭐ EXTENDED WEATHER INFO (clean + English)
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Feels like: ${_weather!.feelsLike}°C",
                                              ),
                                              Text(
                                                "Humidity: ${_weather!.humidity}%",
                                              ),
                                              Text(
                                                "Wind: ${_weather!.windSpeed} m/s",
                                              ),
                                              Text(
                                                "Pressure: ${_weather!.pressure} hPa",
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                "Min: ${_weather!.tempMin}°C",
                                              ),
                                              Text(
                                                "Max: ${_weather!.tempMax}°C",
                                              ),
                                              Text(
                                                "Sunrise: ${_formatTime(_weather!.sunrise)}",
                                              ),
                                              Text(
                                                "Sunset: ${_formatTime(_weather!.sunset)}",
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],

                  if (_forecast != null) ...[
                    const SizedBox(height: 30),
                    const Text(
                      "5‑Day Forecast",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      height: 150,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _forecast!.length,
                        itemBuilder: (context, index) {
                          final day = _forecast![index];
                          final weekday = [
                            "Mon",
                            "Tue",
                            "Wed",
                            "Thu",
                            "Fri",
                            "Sat",
                            "Sun",
                          ][day.date.weekday - 1];

                          return Container(
                            width: 130,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  weekday,
                                  style: const TextStyle(fontSize: 17),
                                ),
                                Image.network(
                                  'https://openweathermap.org/img/wn/${day.icon}.png',
                                  width: 40,
                                ),
                                Text("${day.minTemp}° / ${day.maxTemp}°"),
                                Text(
                                  day.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  if (_hourly != null) ...[
                    const SizedBox(height: 30),
                    const Text(
                      "Hourly Forecast",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87, // ✔ texto oscuro
                      ),
                    ),
                    const SizedBox(height: 10),

                    Column(
                      children: List.generate(_hourly!.length, (index) {
                        final hour = _hourly![index];
                        final time =
                            "${hour.date.hour.toString().padLeft(2, '0')}:00";

                        final isNow = hour.date.hour == DateTime.now().hour;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Timeline (dot + line)
                            Column(
                              children: [
                                // Dot
                                Container(
                                  width: isNow ? 12 : 8,
                                  height: isNow ? 12 : 8,
                                  decoration: BoxDecoration(
                                    color: isNow
                                        ? Colors.blueAccent
                                        : Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                ),

                                // Line
                                if (index != _hourly!.length - 1)
                                  Container(
                                    width: 2,
                                    height: 45,
                                    color: Colors
                                        .black26, // ✔ visible en cualquier fondo
                                  ),
                              ],
                            ),

                            const SizedBox(width: 15),

                            // Content row
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Hora
                                  Text(
                                    time,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: isNow
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isNow
                                          ? Colors.blueAccent
                                          : Colors.black87,
                                    ),
                                  ),

                                  // Icono
                                  Image.network(
                                    'https://openweathermap.org/img/wn/${hour.icon}.png',
                                    width: 35,
                                  ),

                                  // Temperatura
                                  Text(
                                    "${hour.temp}°",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: isNow
                                          ? Colors.blueAccent
                                          : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],

                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      if (!_favoriteCities.contains(_weather!.cityName)) {
                        _favoriteCities.add(_weather!.cityName);
                        await prefs.setStringList('favorites', _favoriteCities);
                        setState(() {});
                      }
                    },
                    child: const Text("Add to Favorites"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  late final WeatherService _weatherService;

  @override
  void initState() {
    super.initState();
    _weatherService = WeatherService();
    _loadFavorites();
  }

  WeatherModel? _weather;
}

List<Color> _getBackgroundGradient(String description) {
  description = description.toLowerCase();

  if (description.contains('rain')) {
    return [Colors.blueGrey.shade800, Colors.blueGrey.shade400];
  }

  if (description.contains('cloud')) {
    return [Colors.grey.shade700, Colors.grey.shade400];
  }

  if (description.contains('clear')) {
    return [Colors.lightBlue.shade300, Colors.lightBlue.shade100];
  }

  if (description.contains('snow')) {
    return [Colors.blue.shade200, Colors.white];
  }

  return [Colors.blueGrey.shade300, Colors.white];
}
