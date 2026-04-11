import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:the_chenab_times/services/location_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  WeatherForecast? _forecast;
  bool _loading = true;
  String? _error;
  int _selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadForecast(refreshLocation: true);
    });
  }

  Future<void> _loadForecast({bool refreshLocation = false}) async {
    final locationService = context.read<LocationService>();
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (refreshLocation) {
        await locationService.refreshLocation();
      }
      final forecast = await locationService.fetchWeatherForecast(days: 3);
      if (!mounted) return;
      setState(() {
        _forecast = forecast;
        _selectedDayIndex = 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationService = context.watch<LocationService>();
    final titleLocation =
        locationService.city ??
        locationService.state ??
        locationService.country ??
        'Your location';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F3EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6E8D5),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFBF5), Color(0xFFF1DDC1)],
            ),
            border: Border(
              bottom: BorderSide(color: Color(0xFFE1CCAF), width: 1),
            ),
          ),
        ),
        title: const Text(
          'Weather Forecast',
          style: TextStyle(
            color: Color(0xFF5E160F),
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF8C1D18),
        backgroundColor: const Color(0xFFFFFBF5),
        onRefresh: () => _loadForecast(refreshLocation: true),
        child: _loading
            ? _buildLoadingState()
            : _error != null ||
                  _forecast == null ||
                  (_forecast?.daily.isEmpty ?? true)
            ? _buildErrorState()
            : ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                children: [
                  _buildWeatherHero(titleLocation),
                  const SizedBox(height: 16),
                  _buildDaySelector(),
                  const SizedBox(height: 16),
                  _buildSelectedDayOverview(),
                  const SizedBox(height: 16),
                  _buildHourlyForecastSection(),
                ],
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: const [
        _WeatherLoadingHero(),
        SizedBox(height: 16),
        _WeatherLoadingCard(height: 98),
        SizedBox(height: 16),
        _WeatherLoadingCard(height: 128),
        SizedBox(height: 16),
        _WeatherLoadingCard(height: 320),
      ],
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 70),
        Container(
          width: 94,
          height: 94,
          margin: const EdgeInsets.symmetric(horizontal: 110),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFBF5), Color(0xFFF2E2CA)],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE3CCAC)),
          ),
          child: const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFF8C1D18),
            size: 40,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          _error ?? 'Could not load weather right now.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF6C1715),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Pull down to try again.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF7A6247),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherHero(String titleLocation) {
    final forecast = _forecast;
    final current = forecast?.current;
    final today = forecast?.daily.isNotEmpty == true
        ? forecast!.daily.first
        : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBF5), Color(0xFFF2E2CA)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE4CEB2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFB22D1F), Color(0xFF7C1714)],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x228C1D18),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              _weatherIcon(current?.weatherCode),
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleLocation,
                  style: const TextStyle(
                    color: Color(0xFF5D1A12),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${current?.temperature?.round() ?? '--'}°C',
                  style: const TextStyle(
                    color: Color(0xFF6D1715),
                    fontSize: 38,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _weatherLabel(current?.weatherCode),
                  style: const TextStyle(
                    color: Color(0xFF7A6247),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _WeatherMetricPill(
                label: 'Feels like',
                value: '${current?.apparentTemperature?.round() ?? '--'}°C',
              ),
              const SizedBox(height: 8),
              _WeatherMetricPill(
                label: 'Humidity',
                value: '${current?.humidity ?? '--'}%',
              ),
              const SizedBox(height: 8),
              _WeatherMetricPill(
                label: 'Today',
                value:
                    '${today?.minTemperature?.round() ?? '--'}° / ${today?.maxTemperature?.round() ?? '--'}°',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    final daily = _forecast?.daily ?? [];
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: daily.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = daily[index];
          final selected = index == _selectedDayIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedDayIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              width: 128,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFB22D1F), Color(0xFF7C1714)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFFBF5), Color(0xFFF2E2CA)],
                      ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFE8C08C)
                      : const Color(0xFFE4CEB2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: selected
                        ? const Color(0x238C1D18)
                        : const Color(0x12000000),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat.E().format(item.date),
                    style: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF7A6247),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        _weatherIcon(item.weatherCode),
                        color: selected
                            ? Colors.white
                            : const Color(0xFF8C1D18),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${item.maxTemperature?.round() ?? '--'}°',
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF5D1A12),
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    '${item.minTemperature?.round() ?? '--'}° low',
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFFF5E6D6)
                          : const Color(0xFF7A6247),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSelectedDayOverview() {
    final day = (_forecast?.daily ?? [])[_selectedDayIndex];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, d MMM').format(day.date),
            style: const TextStyle(
              color: Color(0xFF4A2017),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _WeatherInfoTile(
                  label: 'Condition',
                  value: _weatherLabel(day.weatherCode),
                  icon: _weatherIcon(day.weatherCode),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WeatherInfoTile(
                  label: 'Rain chance',
                  value: '${day.precipitationProbability ?? '--'}%',
                  icon: Icons.water_drop_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _WeatherInfoTile(
                  label: 'Sunrise',
                  value: day.sunrise != null
                      ? DateFormat.jm().format(day.sunrise!)
                      : '--',
                  icon: Icons.wb_sunny_outlined,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WeatherInfoTile(
                  label: 'Sunset',
                  value: day.sunset != null
                      ? DateFormat.jm().format(day.sunset!)
                      : '--',
                  icon: Icons.nights_stay_outlined,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyForecastSection() {
    final daily = _forecast?.daily ?? [];
    final hourly = _forecast?.hourly ?? [];
    final day = daily[_selectedDayIndex];
    final start = DateTime(day.date.year, day.date.month, day.date.day);
    final end = start.add(const Duration(days: 1));
    final selectedHourly = hourly
        .where(
          (item) =>
              item.time.isAfter(start.subtract(const Duration(seconds: 1))) &&
              item.time.isBefore(end),
        )
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x16000000),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hourly Forecast',
            style: TextStyle(
              color: Color(0xFF4A2017),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (selectedHourly.isEmpty)
            const Text(
              'No hourly forecast is available for this day yet.',
              style: TextStyle(
                color: Color(0xFF7A6247),
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...selectedHourly.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _HourlyWeatherRow(entry: entry),
              ),
            ),
        ],
      ),
    );
  }

  IconData _weatherIcon(int? code) {
    switch (code) {
      case 0:
        return Icons.wb_sunny_rounded;
      case 1:
      case 2:
      case 3:
        return Icons.cloud_queue_rounded;
      case 45:
      case 48:
        return Icons.foggy;
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
      case 65:
      case 80:
      case 81:
      case 82:
        return Icons.grain_rounded;
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return Icons.ac_unit_rounded;
      case 95:
      case 96:
      case 99:
        return Icons.thunderstorm_rounded;
      default:
        return Icons.cloud_rounded;
    }
  }

  String _weatherLabel(int? code) {
    switch (code) {
      case 0:
        return 'Clear sky';
      case 1:
      case 2:
        return 'Partly cloudy';
      case 3:
        return 'Cloudy';
      case 45:
      case 48:
        return 'Fog';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 61:
      case 63:
      case 65:
      case 80:
      case 81:
      case 82:
        return 'Rain';
      case 71:
      case 73:
      case 75:
      case 77:
      case 85:
      case 86:
        return 'Snow';
      case 95:
      case 96:
      case 99:
        return 'Thunderstorm';
      default:
        return 'Weather';
    }
  }
}

class _WeatherMetricPill extends StatelessWidget {
  const _WeatherMetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7A6247),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF5D1A12),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherInfoTile extends StatelessWidget {
  const _WeatherInfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBF5), Color(0xFFF5E7D1)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9D9C4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF8C1D18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF7A6247),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF4A2017),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HourlyWeatherRow extends StatelessWidget {
  const _HourlyWeatherRow({required this.entry});

  final HourlyWeather entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBF5), Color(0xFFF5E7D1)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9D9C4)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 68,
            child: Text(
              DateFormat.j().format(entry.time),
              style: const TextStyle(
                color: Color(0xFF4A2017),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(
                  _hourlyIcon(entry.weatherCode),
                  color: const Color(0xFF8C1D18),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.temperature?.round() ?? '--'}°C',
                  style: const TextStyle(
                    color: Color(0xFF4A2017),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Rain ${entry.precipitationProbability ?? '--'}%',
            style: const TextStyle(
              color: Color(0xFF7A6247),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _hourlyIcon(int? code) {
    switch (code) {
      case 0:
        return Icons.wb_sunny_rounded;
      case 1:
      case 2:
      case 3:
        return Icons.cloud_rounded;
      case 45:
      case 48:
        return Icons.foggy;
      case 95:
      case 96:
      case 99:
        return Icons.thunderstorm_rounded;
      default:
        return Icons.water_drop_rounded;
    }
  }
}

class _WeatherLoadingHero extends StatelessWidget {
  const _WeatherLoadingHero();

  @override
  Widget build(BuildContext context) {
    return const _WeatherLoadingCard(height: 150);
  }
}

class _WeatherLoadingCard extends StatelessWidget {
  const _WeatherLoadingCard({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFBF5), Color(0xFFF2E2CA)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4CEB2)),
      ),
    );
  }
}
