import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/enums.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/tka_logo.dart';
import '../../utils/input_sanitizer.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final username = InputSanitizer.sanitizeUsername(
      _usernameController.text,
    );
    final password = InputSanitizer.sanitizePassword(
      _passwordController.text,
    );

    final success = await auth.login(username, password);

    if (!mounted) return;

    if (success) {
      final role = auth.role;
      final loggedUsername = (auth.username ?? '').trim().toLowerCase();
      final isKitchenAccount = loggedUsername == 'kitchen';

      if (_isMobilePlatform) {
        // Mobile: cho phép mọi tài khoản Nhân viên / Phục vụ (role = staff),
        // ngoại trừ tài khoản kitchen (kitchen thuộc về Web).
        final isStaffMobileAllowed = role == UserRole.staff && !isKitchenAccount;
        if (!isStaffMobileAllowed) {
          auth.logout();
          setState(() => _isLoading = false);
          _showErrorDialog(
            'Chỉ tài khoản Nhân viên phục vụ đăng nhập.',
          );
          return;
        }
      } else {
        // Web/Desktop: cho phép Manager, Cashier hoặc tài khoản Kitchen.
        final isWebAllowedRole = role == UserRole.manager || role == UserRole.cashier;
        if (!(isWebAllowedRole || isKitchenAccount)) {
          auth.logout();
          setState(() => _isLoading = false);
          _showErrorDialog(
            'Chỉ tài khoản Quản lý đăng nhập.',
          );
          return;
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sai tài khoản hoặc mật khẩu'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Mobile = Android / iOS. Web và Desktop (Windows/macOS/Linux) đều coi là "không phải mobile".
  bool get _isMobilePlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  void _showErrorDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Không thể đăng nhập'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isMobilePlatform) {
      return _buildMobileLoginScaffold();
    }
    return _buildWebLoginScaffold();
  }

  Widget _buildWebLoginScaffold() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TkaLogo(
                      iconSize: 52,
                      fontSize: 30,
                    ),
                    const SizedBox(height: 22),
                    _buildLoginForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLoginScaffold() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TkaLogo(
                  iconSize: 46,
                  fontSize: 26,
                ),
                const SizedBox(height: 28),
                _buildLoginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final sanitized =
                  value == null ? '' : InputSanitizer.sanitizeUsername(value);
              if (sanitized.isEmpty) {
                return 'Please enter username';
              }
              if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(sanitized)) {
                return 'Username contains invalid characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: (value) {
              final sanitized =
                  value == null ? '' : InputSanitizer.sanitizePassword(value);
              if (sanitized.isEmpty) {
                return 'Please enter password';
              }
              if (sanitized.contains(' ')) {
                return 'Password cannot contain spaces';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'LOGIN',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}


