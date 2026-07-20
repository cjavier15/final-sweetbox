import 'package:flutter/material.dart';
//import 'package:sweet_box_flutter/services/database_seeder.dart';
import '../theme/app_theme.dart';
import '../services/firestore_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirestoreService _firestore = FirestoreService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _selectedRole = 'Branch Manager';

  final List<String> _roles = [
    'Branch Manager',
    'Inventory Staff',
    'Front Staff',
    'System Administrator',
  ];

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _firestore.authenticateUser(email, password);

      if (user == null) {
        throw Exception('Invalid email or password');
      }

      final role = (user['Role'] ?? user['role'] ?? _selectedRole).toString();

      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/otp',
          arguments: {'role': role});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.symmetric(
                            vertical: isMobile ? 32 : 48, horizontal: 24),
                        child: Column(
                          children: [
                            // Logo placeholder
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.cake_rounded,
                                size: 52,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Sweet Box',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Centralized Analytics System',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.accent,
                                    letterSpacing: 0.5,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      // Login Card
                      Container(
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        padding: EdgeInsets.all(isMobile ? 20 : 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sign In',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter your credentials to continue',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 28),

                            // Role Selector
                            Text(
                              'Role',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedRole,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              items: _roles
                                  .map((role) => DropdownMenuItem(
                                        value: role,
                                        child: Text(role),
                                      ))
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _selectedRole = value!),
                            ),
                            const SizedBox(height: 16),

                            // Email
                            Text('Email',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'Enter your email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password
                            Text('Password',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: 'Enter your password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Sign In Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Text('Sign In'),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Note
                            Center(
                              child: Text(
                                'A one-time password will be sent to your email',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Quick Access Demo Buttons
                            Text(
                              'Quick Demo Access',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _demoChip('POS Terminal', '/pos',
                                    Icons.point_of_sale),
                                _demoChip('Inventory', '/inventory',
                                    Icons.inventory_2_outlined),
                                _demoChip('Branch Mgr', '/branch-manager',
                                    Icons.dashboard_outlined),
                                _demoChip('Sys Admin', '/admin',
                                    Icons.admin_panel_settings),
                                _demoChip('Enterprise', '/enterprise',
                                    Icons.business_outlined),
                                /* ElevatedButton.icon(
                                  icon: const Icon(Icons.cloud_upload),
                                  label:
                                      const Text('Seed Products to Database'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors
                                        .green, // Makes it stand out as a dev tool
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: () async {
                                    // Show a loading indicator in the console or UI if you want
                                    print('Starting database seed...');

                                    await DatabaseSeeder.seedAllData();

                                    // Optional: Show a little pop-up at the bottom of the screen when done
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Products seeded successfully!'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  },
                                ),*/
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _demoChip(String label, String route, IconData icon) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: AppColors.accent.withValues(alpha: 0.15),
      side: BorderSide(color: AppColors.accent.withValues(alpha: 0.4)),
      onPressed: () => Navigator.pushNamed(context, route),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
