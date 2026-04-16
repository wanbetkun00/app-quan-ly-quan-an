import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'providers/restaurant_provider.dart';
import 'providers/language_provider.dart';
import 'providers/app_strings.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/tka_logo.dart';
import 'screens/waiter/waiter_dashboard_screen.dart';
import 'screens/kitchen/kitchen_display_screen.dart';
import 'screens/manager/manager_dashboard_screen.dart';
import 'screens/cashier/cashier_dashboard_screen.dart';
import 'screens/waiter/shift_view_screen.dart';
import 'screens/auth/login_screen.dart';
import 'models/enums.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RestaurantProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const TkaRestaurantApp(),
    ),
  );
}

class TkaRestaurantApp extends StatelessWidget {
  const TkaRestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return MaterialApp(
          title: 'TKA Restaurant',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme,
          home: auth.isLoggedIn
              ? MainNavigationScaffold(role: auth.role!)
              : const LoginScreen(),
        );
      },
    );
  }
}

class MainNavigationScaffold extends StatefulWidget {
  final UserRole role;
  const MainNavigationScaffold({super.key, required this.role});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedIndex = 0;
  late PageController _pageController;

  late final List<Widget> _pages;
  late final List<NavigationDestination> _destinations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    switch (widget.role) {
      case UserRole.manager:
        _pages = const [
          WaiterDashboardScreen(),
          CashierDashboardScreen(),
          KitchenDisplayScreen(),
          ManagerDashboardScreen(),
        ];
        _destinations = [
          const NavigationDestination(
            icon: Icon(Icons.room_service),
            label: 'Phục vụ',
          ),
          const NavigationDestination(
            icon: Icon(Icons.point_of_sale),
            label: 'Thu ngân',
          ),
          const NavigationDestination(icon: Icon(Icons.kitchen), label: 'Bếp'),
          const NavigationDestination(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Quản lý',
          ),
        ];
      case UserRole.cashier:
        _pages = const [
          CashierDashboardScreen(),
          KitchenDisplayScreen(),
        ];
        _destinations = const [
          NavigationDestination(
            icon: Icon(Icons.point_of_sale),
            label: 'Thu ngân',
          ),
          NavigationDestination(
            icon: Icon(Icons.kitchen),
            label: 'Bếp',
          ),
        ];
      case UserRole.staff:
        _pages = const [WaiterDashboardScreen()];
        _destinations = const [];
    }
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app resumes, refresh data to sync table statuses
    if (state == AppLifecycleState.resumed && mounted) {
      final provider = Provider.of<RestaurantProvider>(context, listen: false);
      provider.refreshData();
    }
  }

  void _onDestinationSelected(int index) {
    if (index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Cashier và Waiter chỉ hiển thị đúng dashboard vai trò của họ.
    if (widget.role == UserRole.staff) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Staff - ${auth.username ?? ''}'),
          actions: [
            TextButton.icon(
              onPressed: auth.logout,
              icon: const Icon(Icons.logout, size: 18),
              label: Text(context.strings.logout),
            ),
          ],
        ),
        body: const WaiterDashboardScreen(),
      );
    }

    if (widget.role == UserRole.cashier) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Cashier - ${auth.username ?? ''}'),
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              tooltip: context.strings.mgrTabShifts,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const ShiftViewScreen(),
                  ),
                );
              },
            ),
            TextButton.icon(
              onPressed: auth.logout,
              icon: const Icon(Icons.logout, size: 18),
              label: Text(context.strings.logout),
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          children: _pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
          animationDuration: const Duration(milliseconds: 300),
          destinations: _destinations,
        ),
      );
    }

    // Manager có thể truy cập đầy đủ module.
    return Scaffold(
      appBar: AppBar(
        title: const TkaLogo(fontSize: 20),
        actions: [
          TextButton.icon(
            onPressed: () {
              auth.logout();
            },
            icon: const Icon(Icons.logout, size: 18),
            label: Text(context.strings.logout),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        animationDuration: const Duration(milliseconds: 300),
        destinations: _destinations,
      ),
    );
  }
}
