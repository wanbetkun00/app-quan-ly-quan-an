import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'screens/auth/login_screen.dart';
import 'models/enums.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late PageController _pageController;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = widget.role == UserRole.staff
        ? const [
            WaiterDashboardScreen(),
          ]
        : const [
            WaiterDashboardScreen(),
            KitchenDisplayScreen(),
            ManagerDashboardScreen(),
          ];
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    final strings = context.strings;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    // Nếu là nhân viên, chỉ hiển thị màn hình phục vụ (không có bottom navigation)
    if (widget.role == UserRole.staff) {
      return Scaffold(
        appBar: AppBar(
          title: const TkaLogo(fontSize: 20),
          actions: [
            TextButton.icon(
              onPressed: () {
                auth.logout();
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Đăng xuất'),
            ),
          ],
        ),
        body: const WaiterDashboardScreen(),
      );
    }
    
    // Nếu là quản lý, hiển thị đầy đủ với bottom navigation
    return Scaffold(
      appBar: AppBar(
        title: const TkaLogo(fontSize: 20),
        actions: [
          TextButton.icon(
            onPressed: () {
              auth.logout();
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Đăng xuất'),
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
