import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherWidget extends StatefulWidget {
  final Function(double rainfall)? onRainfallData;

  const WeatherWidget({super.key, this.onRainfallData});

  @override
  State<WeatherWidget> createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  Map<String, dynamic>? _weatherData;
  bool _isLoading = false;
  String _errorMessage = '';
  String _location = "Colombo";

  // Available locations in Sri Lanka
  final List<String> _locations = [
    "Colombo",
    "Kandy", 
    "Galle",
    "Jaffna",
    "Negombo",
    "Trincomalee",
    "Anuradhapura",
    "Nuwara Eliya",
    "Ratnapura",
    "Hambantota"
  ];

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
  }

  /// Fetch current weather data from OpenWeatherMap API
  Future<void> _fetchWeatherData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _errorMessage = 'Weather API key not configured';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$_location,LK&appid=$apiKey&units=metric'
      )).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _weatherData = data;
        });

        // Calculate rainfall and notify parent if callback provided
        _calculateRainfall(data);
        
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch weather data (${response.statusCode})';
        });
      }
    } catch (e) {
      print('Weather API error: $e');
      setState(() {
        _errorMessage = 'Unable to fetch weather data. Please check your connection.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Calculate rainfall from weather data
  void _calculateRainfall(Map<String, dynamic> data) {
    double rainfall = 0.0;
    
    // Check for rain data in current weather
    if (data['rain'] != null) {
      if (data['rain']['1h'] != null) {
        rainfall = (data['rain']['1h'] as num).toDouble();
      } else if (data['rain']['3h'] != null) {
        rainfall = (data['rain']['3h'] as num).toDouble() / 3;
      }
    }

    // Notify parent component about rainfall data
    if (widget.onRainfallData != null) {
      widget.onRainfallData!(rainfall);
    }
  }

  /// Get weather icon based on condition code
  IconData _getWeatherIcon(int conditionCode) {
    if (conditionCode < 300) {
      return Icons.thunderstorm; // Thunderstorm
    } else if (conditionCode < 500) {
      return Icons.grain; // Drizzle
    } else if (conditionCode < 600) {
      return Icons.umbrella; // Rain
    } else if (conditionCode < 700) {
      return Icons.ac_unit; // Snow
    } else if (conditionCode < 800) {
      return Icons.foggy; // Atmosphere
    } else if (conditionCode == 800) {
      return Icons.wb_sunny; // Clear
    } else if (conditionCode < 900) {
      return Icons.cloud; // Clouds
    } else {
      return Icons.device_unknown;
    }
  }

  /// Get color based on weather condition
  Color _getWeatherColor(int conditionCode) {
    if (conditionCode < 600) {
      return const Color(0xFF2D7DD2); // Rainy - Blue
    } else if (conditionCode == 800) {
      return const Color(0xFFFF9A3D); // Sunny - Orange
    } else {
      return const Color(0xFF764BA2); // Cloudy - Purple
    }
  }

  /// Get background gradient based on weather
  LinearGradient _getWeatherGradient(int conditionCode) {
    if (conditionCode < 600) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2D7DD2), Color(0xFF1A5FA6)],
      );
    } else if (conditionCode == 800) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFF9A3D), Color(0xFFE87C0C)],
      );
    } else {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF764BA2), Color(0xFF5A378C)],
      );
    }
  }

  /// Get weather description
  String _getWeatherDescription(int conditionCode) {
    if (conditionCode < 300) return "Thunderstorm";
    if (conditionCode < 400) return "Drizzle";
    if (conditionCode < 600) return "Rainy";
    if (conditionCode < 700) return "Snowy";
    if (conditionCode == 800) return "Clear Sky";
    if (conditionCode < 900) return "Cloudy";
    return "Unknown";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: _weatherData != null 
            ? _getWeatherGradient(_weatherData!['weather'][0]['id'] ?? 800)
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2D7DD2), Color(0xFF1A5FA6)],
              ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Current Weather",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _location,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isLoading)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _fetchWeatherData,
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                    tooltip: 'Refresh Weather',
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          if (_isLoading) 
            _buildLoadingState()
          else if (_errorMessage.isNotEmpty)
            _buildErrorState()
          else if (_weatherData != null)
            _buildWeatherContent()
          else
            _buildEmptyState(),
        ],
      ),
    );
  }

  /// Loading state
  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Error state
  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Weather Unavailable",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _fetchWeatherData,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Empty state
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cloud_off, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "No Weather Data",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Tap refresh to load weather",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _fetchWeatherData,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Weather content when data is available
  Widget _buildWeatherContent() {
    final weather = _weatherData!['weather'][0];
    final main = _weatherData!['main'];
    final conditionCode = weather['id'];
    final temperature = main['temp'].round();
    final humidity = main['humidity'];
    final rainfall = _weatherData!['rain'] != null ? 
        (_weatherData!['rain']['1h'] ?? _weatherData!['rain']['3h'] ?? 0) : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Main weather row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getWeatherIcon(conditionCode),
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$temperature°C",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _getWeatherDescription(conditionCode),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Weather details grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeatherDetail("Humidity", "$humidity%", Icons.opacity),
              _buildWeatherDetail("Rainfall", "${rainfall}mm", Icons.water_drop),
              _buildWeatherDetail("Feels Like", "${main['feels_like'].round()}°C", Icons.thermostat),
            ],
          ),

          const SizedBox(height: 16),

          // Location selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _location,
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                dropdownColor: const Color(0xFF2D7DD2),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white,
                ),
                items: _locations.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (newLocation) {
                  if (newLocation != null) {
                    setState(() {
                      _location = newLocation;
                    });
                    _fetchWeatherData();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Individual weather detail item
  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}