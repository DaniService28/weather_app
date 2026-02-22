class WeatherModel {
  final String cityName;
  final double temperature;
  final String description;
  final int humidity;
  final String icon;
  final double feelsLike;
  final double windSpeed;
  final int pressure;
  final int sunrise;
  final int sunset;
  final double tempMin;
  final double tempMax;

  WeatherModel({
    required this.cityName,
    required this.temperature,
    required this.description,
    required this.humidity,
    required this.icon,
    required this.feelsLike,
    required this.windSpeed,
    required this.pressure,
    required this.sunrise,
    required this.sunset,
    required this.tempMin,
    required this.tempMax,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['name'],
      temperature: json['main']['temp'].toDouble(),
      description: json['weather'][0]['description'],
      humidity: json['main']['humidity'],
      icon: json['weather'][0]['icon'],
      feelsLike: json['main']['feels_like'].toDouble(),
      windSpeed: json['wind']['speed'].toDouble(),
      pressure: json['main']['pressure'],
      sunrise: json['sys']['sunrise'],
      sunset: json['sys']['sunset'],
      tempMin: json['main']['temp_min'].toDouble(),
      tempMax: json['main']['temp_max'].toDouble(),
    );
  }
}
