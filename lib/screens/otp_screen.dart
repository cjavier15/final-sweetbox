import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _secondsRemaining = 300;
  late Timer _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _timerText {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _handleVerify() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final String rawRole = args?['role'] ?? 'Branch Manager';

    // Normalize the string by making it lowercase and removing extra spaces
    // This prevents simple typos in the database from breaking the routing
    final String role = rawRole.trim().toLowerCase();

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);

    if (!mounted) return;

    // Route dynamically based on the normalized role string
    if (role == 'business owner' || role == 'owner') {
      Navigator.pushReplacementNamed(context, '/enterprise', arguments: args);
    } else if (role == 'system administrator' ||
        role == 'admin' ||
        role == 'system admin') {
      Navigator.pushReplacementNamed(context, '/admin', arguments: args);
    } else if (role == 'inventory staff' || role == 'inventory') {
      Navigator.pushReplacementNamed(context, '/inventory', arguments: args);
    } else if (role == 'front staff' || role == 'cashier' || role == 'pos') {
      Navigator.pushReplacementNamed(context, '/pos', arguments: args);
    } else if (role == 'branch manager' || role == 'manager') {
      Navigator.pushReplacementNamed(context, '/branch-manager',
          arguments: args);
    } else {
      // Fallback if the role in the database is completely unrecognized
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Unrecognized role: $rawRole. Defaulting to Branch Manager.'),
          backgroundColor: AppColors.warning,
        ),
      );
      Navigator.pushReplacementNamed(context, '/branch-manager',
          arguments: args);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  size: 34,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Check Your Email',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'We sent a 6-digit verification code to your registered email address.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                    6,
                    (index) => Padding(
                          padding: EdgeInsets.only(right: index < 5 ? 6 : 0),
                          child: _buildOtpField(index),
                        )),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _secondsRemaining > 60
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: _secondsRemaining > 60
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Code expires in $_timerText',
                      style: TextStyle(
                        color: _secondsRemaining > 60
                            ? AppColors.success
                            : AppColors.danger,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerify,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify & Sign In'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _secondsRemaining == 0
                    ? () {
                        setState(() => _secondsRemaining = 300);
                        _startTimer();
                      }
                    : null,
                child: Text(
                  _secondsRemaining == 0
                      ? 'Resend Code'
                      : 'Resend code when timer expires',
                  style: TextStyle(
                    color: _secondsRemaining == 0
                        ? AppColors.accent
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpField(int index) {
    return SizedBox(
      width: 40,
      height: 50,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.accent, width: 2),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }
}
