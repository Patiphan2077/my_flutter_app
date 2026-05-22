import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherApp extends StatefulWidget {
  const WeatherApp({super.key});

  @override
  State<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends State<WeatherApp>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _city = 'Bangkok, Thailand';
  double _latitude = 13.7563;
  double _longitude = 100.5018;

  WeatherData? _weatherData;
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fetchWeather();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _animationController.reset();

    try {
      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$_latitude&longitude=$_longitude&current=temperature_2m,weather_code,relative_humidity_2m,wind_speed_10m&timezone=auto',
      );

      final forecastUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$_latitude&longitude=$_longitude&daily=temperature_2m_max,temperature_2m_min,weather_code&timezone=auto&forecast_days=5',
      );

      final weatherResponse = await http.get(weatherUrl).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Connection timeout'),
          );

      final forecastResponse = await http.get(forecastUrl).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Connection timeout'),
          );

      if (weatherResponse.statusCode == 200 &&
          forecastResponse.statusCode == 200) {
        final weatherJson = jsonDecode(weatherResponse.body);
        final forecastJson = jsonDecode(forecastResponse.body);

        _weatherData = WeatherData.fromJson(weatherJson, forecastJson);
        _animationController.forward();
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchCity(String cityName) async {
    try {
      final geoUrl = Uri.parse(
        'https://geocoding-api.open-meteo.com/v1/search?name=$cityName&count=1&language=en&format=json',
      );

      final response = await http.get(geoUrl).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Connection timeout'),
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['results'] != null && json['results'].isNotEmpty) {
          final result = json['results'][0];
          _latitude = result['latitude'];
          _longitude = result['longitude'];
          _city = '${result['name']}, ${result['country']}';
          _cityController.clear();
          await _fetchWeather();
        } else {
          setState(() {
            _errorMessage = 'City not found';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error searching city: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[300]!,
              Colors.blue[400]!,
              Colors.blue[600]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      _city,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _cityController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Search city...',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                              ),
                              prefixIcon: const Icon(Icons.location_on,
                                  color: Colors.white),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.search,
                                    color: Colors.white),
                                onPressed: () {
                                  if (_cityController.text.isNotEmpty) {
                                    _searchCity(_cityController.text);
                                  }
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                _searchCity(value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _fetchWeather,
                                  child: const Text('Retry'),
                                )
                              ],
                            ),
                          )
                        : _weatherData == null
                            ? const Center(
                                child: Text(
                                  'No data available',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : FadeTransition(
                                opacity: _fadeAnimation,
                                child: SingleChildScrollView(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(32),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.2),
                                              Colors.white.withOpacity(0.1),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _getWeatherIconColor(
                                                    _weatherData!.weatherCode),
                                              ),
                                              child: Icon(
                                                _getWeatherIcon(
                                                    _weatherData!.weatherCode),
                                                size: 80,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              '${_weatherData!.temperature.toInt()}°C',
                                              style: const TextStyle(
                                                fontSize: 72,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _getWeatherDescription(
                                                  _weatherData!.weatherCode),
                                              style: TextStyle(
                                                fontSize: 20,
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildDetailCard(
                                              'Humidity',
                                              '${_weatherData!.humidity}%',
                                              Icons.opacity,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _buildDetailCard(
                                              'Wind Speed',
                                              '${_weatherData!.windSpeed.toInt()} km/h',
                                              Icons.air,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white.withOpacity(0.15),
                                              Colors.white.withOpacity(0.08),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              '5-Day Forecast',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            ..._weatherData!.forecast
                                                .asMap()
                                                .entries
                                                .map((e) {
                                              final day = e.value;
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 12),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      flex: 2,
                                                      child: Text(
                                                        day['dayName'],
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          color: Colors.white
                                                              .withOpacity(0.9),
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                    Icon(
                                                      _getWeatherIcon(
                                                          day['weatherCode']),
                                                      color: Colors.white,
                                                      size: 24,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        '${day['tempMax']}° / ${day['tempMin']}°',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.white
                                                              .withOpacity(0.8),
                                                        ),
                                                        textAlign:
                                                            TextAlign.right,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                    ],
                                  ),
                                ),
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getWeatherIcon(int weatherCode) {
    if (weatherCode == 0) return Icons.wb_sunny;
    if (weatherCode == 1 || weatherCode == 2) return Icons.cloud;
    if (weatherCode == 3) return Icons.cloud;
    if (weatherCode == 45 || weatherCode == 48) return Icons.cloud_queue;
    if (weatherCode >= 51 && weatherCode <= 67) return Icons.grain;
    if (weatherCode >= 71 && weatherCode <= 77) return Icons.cloudy_snowing;
    if (weatherCode >= 80 && weatherCode <= 82) return Icons.water_drop;
    if (weatherCode >= 85 && weatherCode <= 86) return Icons.cloudy_snowing;
    if (weatherCode >= 90 && weatherCode <= 99) return Icons.flash_on;
    return Icons.wb_sunny;
  }

  Color _getWeatherIconColor(int weatherCode) {
    if (weatherCode == 0) return Colors.orange;
    if (weatherCode >= 51 && weatherCode <= 67) return Colors.blue;
    if (weatherCode >= 71 && weatherCode <= 77) return Colors.cyan;
    if (weatherCode >= 90 && weatherCode <= 99) return Colors.purple;
    return Colors.grey;
  }

  String _getWeatherDescription(int weatherCode) {
    if (weatherCode == 0) return 'Clear Sky';
    if (weatherCode == 1 || weatherCode == 2) return 'Mostly Cloudy';
    if (weatherCode == 3) return 'Overcast';
    if (weatherCode == 45 || weatherCode == 48) return 'Foggy';
    if (weatherCode >= 51 && weatherCode <= 67) return 'Rainy';
    if (weatherCode >= 71 && weatherCode <= 77) return 'Snowy';
    if (weatherCode >= 80 && weatherCode <= 82) return 'Rain Showers';
    if (weatherCode >= 85 && weatherCode <= 86) return 'Snow Showers';
    if (weatherCode >= 90 && weatherCode <= 99) return 'Thunderstorm';
    return 'Unknown';
  }
}

class WeatherData {
  final double temperature;
  final int humidity;
  final double windSpeed;
  final int weatherCode;
  final List<Map<String, dynamic>> forecast;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.weatherCode,
    required this.forecast,
  });

  factory WeatherData.fromJson(
      Map<String, dynamic> json, Map<String, dynamic> forecastJson) {
    final current = json['current'];
    final daily = forecastJson['daily'];

    final temps = (daily['temperature_2m_max'] as List).cast<num>();
    final minTemps = (daily['temperature_2m_min'] as List).cast<num>();
    final weatherCodes = (daily['weather_code'] as List).cast<int>();
    final dates = (daily['time'] as List).cast<String>();

    List<Map<String, dynamic>> forecast = [];
    for (int i = 0; i < 5 && i < temps.length; i++) {
      final date = DateTime.parse(dates[i]);
      final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

      forecast.add({
        'dayName': dayNames[date.weekday % 7],
        'tempMax': temps[i].toInt(),
        'tempMin': minTemps[i].toInt(),
        'weatherCode': weatherCodes[i],
      });
    }

    return WeatherData(
      temperature: (current['temperature_2m'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      weatherCode: current['weather_code'] as int,
      forecast: forecast,
    );
  }
}
