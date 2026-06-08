import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import 'package:weatherx/utils/assets.dart';
import 'package:weatherx/utils/colors.dart';
import 'package:weatherx/utils/font.dart';

import '../models/city_suggestion.dart';
import '../models/weather_model.dart';
import '../services/weather_services.dart';
import '../utils/api.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  // api key
  final _weatherService = WeatherServices(Api.apiKey);
  WeatherModel? _weatherModel;
  String _cityText = 'Loading city...';
  String _temperatureText = 'Loading temperature...';
  final List<CitySuggestion> _recentSearches = [];
  static const int _maxRecents = 5;

  bool get _isLoading =>
      _cityText == 'Loading city...' ||
      _temperatureText == 'Loading temperature...';

  // fetch weather
  _fetchWeather() async {
    debugPrint('[WeatherPage] _fetchWeather started');

    setState(() {
      _cityText = 'Loading city...';
      _temperatureText = 'Loading temperature...';
    });

    String cityName = '';

    try {
      cityName = await _weatherService.getCurrentCity();
      debugPrint('[WeatherPage] City loaded: "$cityName"');
      if (!mounted) return;
      setState(() {
        _cityText = cityName;
      });
    } catch (e, stack) {
      debugPrint('[WeatherPage] FAILED to load city: $e');
      debugPrint('[WeatherPage] City error stack: $stack');
      if (!mounted) return;
      setState(() {
        _cityText = 'Failed to load city';
        _temperatureText = 'Failed to load temperature';
      });
      return;
    }

    try {
      final weather = await _weatherService.getWeather(cityName);
      debugPrint('[WeatherPage] Weather loaded successfully');
      if (!mounted) return;
      setState(() {
        _weatherModel = weather;
        _temperatureText = '${weather.temperature?.round()}°';
      });
    } catch (e, stack) {
      debugPrint('[WeatherPage] FAILED to load weather: $e');
      debugPrint('[WeatherPage] Weather error stack: $stack');
      if (!mounted) return;
      setState(() {
        _temperatureText = 'Failed to load temperature';
      });
    }
  }

  // fetch weather for a selected suggestion
  _fetchWeatherForSuggestion(CitySuggestion suggestion) async {
    debugPrint('[WeatherPage] _fetchWeatherForSuggestion: ${suggestion.label}');

    _addRecent(suggestion);

    setState(() {
      _cityText = 'Loading city...';
      _temperatureText = 'Loading temperature...';
    });

    try {
      final weather = await _weatherService.getWeatherByCoords(
        suggestion.lat,
        suggestion.lon,
      );
      if (!mounted) return;
      setState(() {
        _weatherModel = weather;
        _cityText = '${suggestion.name}, ${suggestion.country}';
        _temperatureText = '${weather.temperature?.round()}°';
      });
    } catch (e, stack) {
      debugPrint('[WeatherPage] FAILED suggestion weather: $e');
      debugPrint('[WeatherPage] Stack: $stack');
      if (!mounted) return;
      setState(() {
        _cityText = 'City not found';
        _temperatureText = '--';
      });
    }
  }

  void _addRecent(CitySuggestion s) {
    _recentSearches.removeWhere(
      (r) => r.lat == s.lat && r.lon == s.lon && r.name == s.name,
    );
    _recentSearches.insert(0, s);
    while (_recentSearches.length > _maxRecents) {
      _recentSearches.removeLast();
    }
  }

  // search popup
  Future<void> _openSearchSheet() async {
    final result = await showModalBottomSheet<CitySuggestion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (ctx) => _SearchSheet(
        service: _weatherService,
        recents: List.unmodifiable(_recentSearches),
      ),
    );

    if (result != null) {
      _fetchWeatherForSuggestion(result);
    }
  }

  // weather animations

  String getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return Assets.error;

    switch (mainCondition.toLowerCase()) {
      case 'clouds':
        return Assets.cloud;
      case 'mist':
        return Assets.cloud;
      case 'smoke':
        return Assets.cloud;
      case 'haze':
        return Assets.cloud;
      case 'dust':
        return Assets.dust;
      case 'fog':
        return Assets.fog;
      case 'rain':
        return Assets.rain;
      case 'drizzle':
        return Assets.rain;
      case 'shower rain':
        return Assets.rain;
      case 'thunderstorm':
        return Assets.thunder;
      case 'clear':
        return Assets.sunny;

      default:
        return Assets.error;
    }
  }

  // init state
  @override
  void initState() {
    super.initState();

    // fetch weather on start
    _fetchWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            SizedBox.expand(
              child: Center(
                child: _isLoading
                    ? SizedBox(
                        height: 200,
                        width: 280,
                        child: Lottie.asset(Assets.loader, fit: BoxFit.fill),
                      )
                    : _WeatherContent(
                        cityText: _cityText,
                        temperatureText: _temperatureText,
                        weatherAnimation: getWeatherAnimation(
                          _weatherModel?.maincondition ?? '',
                        ),
                      ),
              ),
            ),
            Positioned(
              top: 12,
              right: 16,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openSearchSheet,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedSearch01,
                    size: 22,
                    color: AppColors.icon,
                    strokeWidth: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeatherContent extends StatefulWidget {
  const _WeatherContent({
    required this.cityText,
    required this.temperatureText,
    required this.weatherAnimation,
  });

  final String cityText;
  final String temperatureText;
  final String weatherAnimation;

  @override
  State<_WeatherContent> createState() => _WeatherContentState();
}

class _WeatherContentState extends State<_WeatherContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _fadeFor(int index) {
    const step = 1 / 3;
    final start = index * step;
    final end = start + step;

    return CurvedAnimation(
      parent: _controller,
      curve: Interval(start, end, curve: Curves.easeIn),
    );
  }

  Widget _fadeIn(int index, Widget child) {
    return FadeTransition(opacity: _fadeFor(index), child: child);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _fadeIn(
          0,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedLocation01,
                size: 18.5,
                color: AppColors.icon,
                strokeWidth: 1.5,
              ),
              const SizedBox(height: 4),
              Text(
                widget.cityText,
                style: AppFont.style(fontSize: 22, color: AppColors.text),
              ),
            ],
          ),
        ),
        _fadeIn(
          1,
          Container(
            padding: const EdgeInsets.symmetric(vertical: 125),
            child: Lottie.asset(widget.weatherAnimation),
          ),
        ),
        _fadeIn(
          2,
          Text(
            widget.temperatureText,
            style: AppFont.style(
              fontSize: 55,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet({required this.service, required this.recents});

  final WeatherServices service;
  final List<CitySuggestion> recents;

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _onSearchPressed() async {
    final query = _controller.text.trim();
    if (query.length < 2 || _loading) return;

    setState(() => _loading = true);
    try {
      final results = await widget.service.searchCities(query, limit: 1);
      if (!mounted) return;
      if (results.isEmpty) {
        setState(() => _loading = false);
        _showNotFoundSnack(query);
        return;
      }
      if (!mounted) return;
      Navigator.of(context).pop(results.first);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showNotFoundSnack(query);
    }
  }

  void _showNotFoundSnack(String query) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlert02,
              size: 18,
              color: AppColors.background,
              strokeWidth: 1.5,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No city found for "$query"',
                style: AppFont.style(
                  fontSize: 14,
                  color: AppColors.background,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _pickRecent(CitySuggestion s) {
    Navigator.of(context).pop(s);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.icon.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'Search city',
              style: AppFont.style(
                fontSize: 18,
                color: AppColors.text,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _onSearchPressed(),
                    cursorColor: AppColors.primary,
                    style: AppFont.style(fontSize: 18, color: AppColors.text),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Try "Cape Town" or "Tokyo"',
                      hintStyle: AppFont.style(
                        fontSize: 18,
                        color: AppColors.icon,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _loading ? null : _onSearchPressed,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.icon,
                            ),
                          )
                        : HugeIcon(
                            icon: HugeIcons.strokeRoundedSearch01,
                            size: 20,
                            color: AppColors.icon,
                            strokeWidth: 1.5,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Container(height: 1, color: AppColors.icon.withValues(alpha: 0.25)),
            const SizedBox(height: 22),
            _buildRecents(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecents() {
    if (widget.recents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No recent searches yet',
          style: AppFont.style(fontSize: 13, color: AppColors.icon),
        ),
      );
    }

    final maxListHeight = MediaQuery.of(context).size.height * 0.4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Recent',
          style: AppFont.style(
            fontSize: 12,
            color: AppColors.icon,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxListHeight),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            physics: const ClampingScrollPhysics(),
            itemCount: widget.recents.length,
            separatorBuilder: (_, _) => Container(
              height: 1,
              color: AppColors.icon.withValues(alpha: 0.15),
            ),
            itemBuilder: (ctx, i) {
              final s = widget.recents[i];
              return InkWell(
                onTap: () => _pickRecent(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedLocation01,
                        size: 16,
                        color: AppColors.icon,
                        strokeWidth: 1.5,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: AppFont.style(
                                fontSize: 16,
                                color: AppColors.text,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              s.state != null && s.state!.isNotEmpty
                                  ? '${s.state}, ${s.country}'
                                  : s.country,
                              style: AppFont.style(
                                fontSize: 12,
                                color: AppColors.icon,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
