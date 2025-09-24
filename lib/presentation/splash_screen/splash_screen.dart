import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _glowAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _glowAnimation;

  bool _showRetryOption = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    // Logo animation controller
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Glow animation controller
    _glowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Logo scale animation
    _logoScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    // Logo opacity animation
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    // Glow animation
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _logoAnimationController.forward();
    _glowAnimationController.repeat(reverse: true);
  }

  Future<void> _initializeApp() async {
    try {
      // Simulate app initialization tasks
      await Future.wait([
        _checkAuthenticationTokens(),
        _loadUserPreferences(),
        _fetchGeofenceConfigurations(),
        _prepareCachedData(),
      ]);

      // Add minimum splash display time
      await Future.delayed(const Duration(milliseconds: 2500));

      if (mounted) {
        _navigateToNextScreen();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _showRetryOption = true;
        });

        // Auto-retry after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted && _showRetryOption) {
            _retryInitialization();
          }
        });
      }
    }
  }

  Future<void> _checkAuthenticationTokens() async {
    // Simulate checking secure storage for authentication tokens
    await Future.delayed(const Duration(milliseconds: 800));
  }

  Future<void> _loadUserPreferences() async {
    // Simulate loading user preferences
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<void> _fetchGeofenceConfigurations() async {
    // Simulate fetching geofence configurations from Supabase
    await Future.delayed(const Duration(milliseconds: 700));
  }

  Future<void> _prepareCachedData() async {
    // Simulate preparing cached attendance data
    await Future.delayed(const Duration(milliseconds: 500));
  }

  void _navigateToNextScreen() {
    // Add haptic feedback
    HapticFeedback.lightImpact();

    // Simulate authentication check
    final bool isAuthenticated = _checkAuthenticationStatus();
    final bool hasValidToken = _checkTokenValidity();

    if (isAuthenticated && hasValidToken) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      Navigator.pushReplacementNamed(context, '/login-screen');
    }
  }

  bool _checkAuthenticationStatus() {
    // Simulate authentication status check
    // In real implementation, this would check secure storage
    return false; // Default to false for new users
  }

  bool _checkTokenValidity() {
    // Simulate token validity check
    // In real implementation, this would validate JWT tokens
    return false; // Default to false for expired tokens
  }

  void _retryInitialization() {
    setState(() {
      _showRetryOption = false;
      _isInitializing = true;
    });
    _initializeApp();
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _glowAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkTheme.scaffoldBackgroundColor,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppTheme.darkTheme.scaffoldBackgroundColor,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: SafeArea(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: _buildBackgroundDecoration(),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAnimatedLogo(),
                        SizedBox(height: 8.h),
                        _buildLoadingSection(),
                      ],
                    ),
                  ),
                ),
                _buildBottomSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildBackgroundDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppTheme.darkTheme.scaffoldBackgroundColor,
          AppTheme.darkTheme.colorScheme.surface.withValues(alpha: 0.8),
          AppTheme.darkTheme.scaffoldBackgroundColor,
        ],
        stops: const [0.0, 0.5, 1.0],
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _logoAnimationController,
        _glowAnimationController,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value,
          child: Opacity(
            opacity: _logoOpacityAnimation.value,
            child: Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary
                        .withValues(alpha: _glowAnimation.value * 0.6),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: AppTheme.primary
                        .withValues(alpha: _glowAnimation.value * 0.3),
                    blurRadius: 80,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.9),
                      AppTheme.primary.withValues(alpha: 0.7),
                      AppTheme.darkTheme.colorScheme.surface,
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                  border: Border.all(
                    color: AppTheme.primary
                        .withValues(alpha: _glowAnimation.value),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: 'local_bar',
                    color: AppTheme.darkTheme.colorScheme.onPrimary,
                    size: 12.w,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingSection() {
    if (_showRetryOption) {
      return _buildRetrySection();
    }

    return Column(
      children: [
        _buildLoadingIndicator(),
        SizedBox(height: 3.h),
        _buildLoadingText(),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 8.w,
      height: 8.w,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
        backgroundColor:
            AppTheme.darkTheme.colorScheme.outline.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildLoadingText() {
    return Text(
      'Initializing...',
      style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
        color: AppTheme.darkTheme.colorScheme.onSurface.withValues(alpha: 0.7),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildRetrySection() {
    return Column(
      children: [
        CustomIconWidget(
          iconName: 'error_outline',
          color: AppTheme.warning,
          size: 6.w,
        ),
        SizedBox(height: 2.h),
        Text(
          'Connection timeout',
          style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.warning,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Please check your internet connection',
          style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
            color:
                AppTheme.darkTheme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 3.h),
        ElevatedButton(
          onPressed: _retryInitialization,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: AppTheme.darkTheme.colorScheme.onPrimary,
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.5.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: 'refresh',
                color: AppTheme.darkTheme.colorScheme.onPrimary,
                size: 4.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Retry',
                style: AppTheme.darkTheme.textTheme.labelLarge?.copyWith(
                  color: AppTheme.darkTheme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Column(
        children: [
          Text(
            'Bar Staff Attendance',
            style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.darkTheme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Professional Attendance Management',
            style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.darkTheme.colorScheme.onSurface
                  .withValues(alpha: 0.6),
              letterSpacing: 0.3,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'v1.0.0',
            style: AppTheme.darkTheme.textTheme.labelSmall?.copyWith(
              color: AppTheme.darkTheme.colorScheme.onSurface
                  .withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}
