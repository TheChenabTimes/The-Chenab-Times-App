import 'package:flutter/material.dart';
import 'dart:async';
import 'package:the_chenab_times/widgets/article_list_tab.dart';
import 'package:the_chenab_times/widgets/category_news_tab.dart';

/// The home screen of the app, which displays a tab bar with different news
/// categories.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  // A controller for the tab bar.
  late TabController _tabController;

  // A list of the tabs to display.
  final List<Tab> _tabs = const [
    Tab(text: 'Latest'),
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

  // A list of the widgets to display for each tab.
  final List<Widget> _tabViews = const [
    ArticleListTab(),
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

  @override
  void initState() {
    super.initState();
    // Auto refresh every 5 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      setState(() {});
    });
    // Initialize the tab controller.
    _tabController = TabController(length: _tabs.length, vsync: this);
  Timer? _refreshTimer;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabBar(
        controller: _tabController,
        tabs: _tabs,
        isScrollable: true,
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabViews,
      ),
    );
  }
}
