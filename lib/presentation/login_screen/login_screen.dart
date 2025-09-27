import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/bar_logo_widget.dart';
import './widgets/login_form_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkExistingAuth();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  Future<void> _checkExistingAuth() async {
    // Check if user is already signed in
    if (AuthService.isAuthenticated) {
      try {
        final profile = await AuthService.getCurrentUserProfile();
        if (profile != null && mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        }
      } catch (e) {
        // If profile fetch fails, continue with login
        debugPrint('Profile fetch failed during auth check: $e');
      }
    }
  }

  Future<void> _handleLogin({
    required String email,
    required String password,
  }) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Perform authentication
      final response = await AuthService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // Get user profile to ensure it exists
        final profile = await AuthService.getCurrentUserProfile();

        if (profile != null && mounted) {
          // Success - navigate to dashboard
          HapticFeedback.lightImpact();
          Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
        } else {
          throw Exception(
            'User profile not found. Please contact administrator.',
          );
        }
      } else {
        throw Exception('Authentication failed. Please try again.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getErrorMessage(e.toString());
        });
        HapticFeedback.heavyImpact();
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('Invalid login credentials')) {
      return 'Invalid email or password. Please try again.';
    } else if (error.contains('Email not confirmed')) {
      return 'Please check your email and confirm your account.';
    } else if (error.contains('Too many requests')) {
      return 'Too many login attempts. Please wait a moment and try again.';
    } else if (error.contains('User profile not found')) {
      return 'Account not found. Please contact your administrator.';
    } else if (error.contains('network')) {
      return 'Network error. Please check your connection and try again.';
    }
    return 'Login failed. Please try again.';
  }

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Column(
                  children: [
                    SizedBox(height: 8.h),

                    // Logo Section
                    FadeTransition(
                      opacity: _fadeInAnimation,
                      child: const BarLogoWidget(),
                    ),

                    SizedBox(height: 4.h),

                    // Welcome Text
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeInAnimation,
                        child: Column(
                          children: [
                            Text(
                              'Welcome Back',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: AppTheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              'Sign in to access your attendance dashboard',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 4.h),

                    // Error Message
                    if (_errorMessage != null)
                      SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          width: double.infinity,
                          margin: EdgeInsets.only(bottom: 3.h),
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.error.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CustomIconWidget(
                                iconName:
                                    Icons.error_outline.codePoint.toString(),
                                color: AppTheme.error,
                                size: 20,
                              ),
                              SizedBox(width: 3.w),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.error,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: CustomIconWidget(
                                  iconName: Icons.close.codePoint.toString(),
                                  color: AppTheme.error,
                                  size: 16,
                                ),
                                onPressed: _clearError,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Login Form
                    Expanded(
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeInAnimation,
                          child: LoginFormWidget(
                            onLogin: _handleLogin,
                            isLoading: _isLoading,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
