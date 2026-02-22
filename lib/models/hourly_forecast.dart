class HourlyForecast {
  final DateTime date;
  final double temp;
  final String icon;
  final String description;

  HourlyForecast({
    required this.date,
    required this.temp,
    required this.icon,
    required this.description,
  });
}