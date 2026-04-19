import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_chenab_times/l10n/app_localizations.dart';
import 'package:the_chenab_times/screens/notification_screen.dart';
import 'package:the_chenab_times/screens/search_screen.dart';
import 'package:the_chenab_times/screens/weather_screen.dart';
import 'package:the_chenab_times/services/location_service.dart';
import 'package:the_chenab_times/widgets/category_news_tab.dart';
import 'package:the_chenab_times/widgets/for_you_tab.dart';

/// The home screen of the app, which displays a tab bar with different news
/// categories.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Tab> _tabs = const [
    Tab(text: 'For You'),
    Tab(text: 'Jammu & Kashmir'),
    Tab(text: 'Chenab Valley'),
    Tab(text: 'Politics'),
    Tab(text: 'Government'),
    Tab(text: 'Education'),
    Tab(text: 'India'),
    Tab(text: 'Artificial Intelligence'),
    Tab(text: 'Religion'),
    Tab(text: 'Business'),
    Tab(text: 'World'),
    Tab(text: 'Crime'),
    Tab(text: 'Technology'),
    Tab(text: 'Agriculture'),
    Tab(text: 'Culture'),
    Tab(text: 'Inspirational Stories'),
    Tab(text: 'Op-ed'),
  ];

  final List<Widget> _tabViews = const [
    ForYouTab(),
    CategoryNewsTab(categoryId: 3),
    CategoryNewsTab(categoryId: 463),
    CategoryNewsTab(categoryId: 497),
    CategoryNewsTab(categoryId: 38866),
    CategoryNewsTab(categoryId: 10),
    CategoryNewsTab(categoryId: 317),
    CategoryNewsTab(categoryId: 40329),
    CategoryNewsTab(categoryId: 37686),
    CategoryNewsTab(categoryId: 548),
    CategoryNewsTab(categoryId: 409),
    CategoryNewsTab(categoryId: 552),
    CategoryNewsTab(categoryId: 40392),
    CategoryNewsTab(categoryId: 37617),
    CategoryNewsTab(categoryId: 38568),
    CategoryNewsTab(categoryId: 37289),
    CategoryNewsTab(categoryId: 398),
  ];

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      setState(() {});
    });
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabSelectionChange);
  }

  void _handleTabSelectionChange() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelectionChange);
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context);
    final locationService = context.watch<LocationService>();
    final weatherTitle =
        locationService.city ??
        locationService.state ??
        locationService.country ??
        'Use location';
    final weatherValue = locationService.temperature != null
        ? '${locationService.temperature!.round()}\u00B0C'
        : (locationService.loading
              ? 'Locating...'
              : (locationService.weatherLabel ?? 'Tap to set'));

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colorScheme.background, colorScheme.surface],
                ),
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.onSurface.withValues(alpha: 0.08),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _WeatherHeaderCard(
                      title: weatherTitle,
                      value: weatherValue,
                      loading: locationService.loading,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WeatherScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Center(
                        child: Image.asset(
                          'lib/images/appheading.png',
                          height: 50,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    _PremiumHeaderActionButton(
                      icon: Icons.search_rounded,
                      semanticLabel: 'Search',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      ),
                    ),
                    const SizedBox(width: 2),
                    _PremiumHeaderActionButton(
                      icon: Icons.notifications_none_rounded,
                      semanticLabel: 'Notifications',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.onSurface.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      colorScheme.primary.withValues(alpha: 0.78),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.16),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: const EdgeInsets.symmetric(horizontal: 6),
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                labelColor: theme.colorScheme.onPrimary,
                unselectedLabelColor: colorScheme.onSurface.withValues(
                  alpha: 0.72,
                ),
                labelStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                splashBorderRadius: BorderRadius.circular(24),
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                tabs: _tabs.map((tab) {
                  final index = _tabs.indexOf(tab);
                  final isSelected = _tabController.index == index;
                  return Tab(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 11,
                      ),
                      transform: Matrix4.translationValues(
                        0,
                        isSelected ? -1.5 : 0,
                        0,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: isSelected
                            ? const [
                                BoxShadow(
                                  color: Color(0x1A8C1D18),
                                  blurRadius: 12,
                                  offset: Offset(0, 5),
                                ),
                              ]
                            : null,
                      ),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        style:
                            (isSelected
                                    ? theme.textTheme.titleSmall
                                    : theme.textTheme.titleSmall)
                                ?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  letterSpacing: isSelected ? 0.22 : 0,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : colorScheme.onSurface.withValues(
                                          alpha: 0.72,
                                        ),
                                ) ??
                            TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : colorScheme.onSurface.withValues(
                                      alpha: 0.72,
                                    ),
                            ),
                        child: Text(
                          tab.text ??
                              localizations?.translate('home') ??
                              'Home',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tabViews,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PremiumHeaderActionButton extends StatefulWidget {
  const _PremiumHeaderActionButton({
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String semanticLabel;

  @override
  State<_PremiumHeaderActionButton> createState() =>
      _PremiumHeaderActionButtonState();
}

class _PremiumHeaderActionButtonState
    extends State<_PremiumHeaderActionButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: widget.semanticLabel,
      button: true,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            onTapDown: (_) => _setPressed(true),
            onTapCancel: () => _setPressed(false),
            onTapUp: (_) => _setPressed(false),
            borderRadius: BorderRadius.circular(999),
            splashColor: colorScheme.primary.withValues(alpha: 0.2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary,
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                widget.icon,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 17,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeatherHeaderCard extends StatelessWidget {
  const _WeatherHeaderCard({
    required this.title,
    required this.value,
    required this.loading,
    required this.onTap,
  });

  final String title;
  final String value;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        splashColor: colorScheme.primary.withValues(alpha: 0.14),
        child: SizedBox(
          width: 78,
          height: 58,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ).copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.68),
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ).copyWith(color: colorScheme.onSurface),
                  ),
                  if (loading) ...[
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                        backgroundColor: colorScheme.onSurface.withValues(
                          alpha: 0.12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
