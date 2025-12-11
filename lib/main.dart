import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/restaurant_provider.dart';
import 'providers/language_provider.dart';
import 'providers/app_strings.dart';
import 'theme/app_theme.dart';
import 'screens/waiter/waiter_dashboard_screen.dart';
import 'screens/kitchen/kitchen_display_screen.dart';
import 'screens/manager/manager_dashboard_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: const TkaRestaurantApp(),
    ),
  );
}

class TkaRestaurantApp extends StatelessWidget {
  const TkaRestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TKA Restaurant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MainNavigationScaffold(),
    );
  }
}

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    WaiterDashboardScreen(),
    KitchenDisplayScreen(),
    ManagerDashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.restaurant_menu),
            label: strings.navWaiter,
          ),
          NavigationDestination(
            icon: const Icon(Icons.kitchen),
            label: strings.navKitchen,
          ),
          NavigationDestination(
            icon: const Icon(Icons.admin_panel_settings),
            label: strings.navManager,
          ),
        ],
      ),
    );
  }
}
