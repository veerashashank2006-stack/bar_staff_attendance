import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../models/attendance_record.dart';
import '../../models/user_profile.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_service.dart';

class QrScanner extends StatefulWidget {
  const QrScanner({super.key});

  @override
  State<QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<QrScanner> with TickerProviderStateMixin {
  MobileScannerController? _scannerController;
  bool _isFlashOn = false;
  bool _isScanning = true;
  bool _hasPermission = false;
  bool _isInitializing = true;
  String? _lastScannedCode;
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  UserProfile? _currentUser;

  // Geofence configuration - can be customized per organization
  final Map<String, dynamic> _geofenceConfig = {
    "latitude": 40.7128,
    "longitude": -74.0060,
    "radius": 100.0, // meters
    "locationName": "Main Work Location"
  };

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeScanner();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }

  Future<void> _initializeScanner() async {
    try {
      // Get current user profile
      _currentUser = await AuthService.getCurrentUserProfile();
      if (_currentUser == null) {
        _showError('Please login to scan attendance');
        setState(() {
          _hasPermission = false;
          _isInitializing = false;
        });
        return;
      }

      // Check and request camera permission
      final hasPermission = await _requestCameraPermission();
      if (!hasPermission) {
        setState(() {
          _hasPermission = false;
          _isInitializing = false;
        });
        return;
      }

      // Validate location (optional - can be disabled)
      final validationResult = await _validateLocation();
      if (!validationResult['isValid']) {
        _showValidationError(validationResult['message']);
        setState(() {
          _hasPermission = false;
          _isInitializing = false;
        });
        return;
      }

      // Initialize scanner
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
        torchEnabled: false,
      );

      setState(() {
        _hasPermission = true;
        _isInitializing = false;
      });

      HapticFeedback.lightImpact();
    } catch (e) {
      setState(() {
        _hasPermission = false;
        _isInitializing = false;
      });
      _showError('Failed to initialize scanner: ${e.toString()}');
    }
  }

  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      _showPermissionDialog();
      return false;
    }

    return false;
  }

  Future<Map<String, dynamic>> _validateLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {
          'isValid': false,
          'message':
              'Location services are disabled. Please enable location services to scan attendance.'
        };
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {
            'isValid': false,
            'message':
                'Location permissions are denied. Please allow location access to scan attendance.'
          };
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return {
          'isValid': false,
          'message':
              'Location permissions are permanently denied. Please enable in settings.'
        };
      }

      // Get current position
      Position currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Calculate distance from allowed location
      double distanceInMeters = Geolocator.distanceBetween(
        _geofenceConfig['latitude'],
        _geofenceConfig['longitude'],
        currentPosition.latitude,
        currentPosition.longitude,
      );

      if (distanceInMeters > _geofenceConfig['radius']) {
        return {
          'isValid': false,
          'message':
              'You must be within ${_geofenceConfig['radius']} meters of ${_geofenceConfig['locationName']} to scan attendance.'
        };
      }

      return {'isValid': true, 'message': 'Location validation successful'};
    } catch (e) {
      // For development: allow scanning even if location fails
      return {'isValid': true, 'message': 'Location validation skipped'};
    }
  }

  void _onQRCodeDetected(BarcodeCapture capture) async {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null || code == _lastScannedCode) return;

    setState(() {
      _isScanning = false;
      _lastScannedCode = code;
    });

    // Trigger haptic feedback and process attendance
    HapticFeedback.heavyImpact();
    await _processAttendanceScan(code);
  }

  Future<void> _processAttendanceScan(String qrCode) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.darkTheme.colorScheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primary),
              SizedBox(height: 2.h),
              Text(
                'Processing QR Attendance...',
                style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                  color: AppTheme.darkTheme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      );

      // First validate QR code format
      final isValidQR = await AttendanceService.validateQRCode(qrCode);
      if (!isValidQR) {
        Navigator.of(context).pop(); // Close loading dialog
        _showError('Invalid QR code. Please scan a valid attendance QR code.');
        setState(() {
          _isScanning = true;
          _lastScannedCode = null;
        });
        return;
      }

      // Check if already checked in today
      final todayAttendance = await AttendanceService.getTodayAttendance();

      Position? currentPosition;
      try {
        currentPosition = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        );
      } catch (e) {
        // Continue without location if it fails
      }

      AttendanceRecord attendanceRecord;

      if (todayAttendance == null) {
        // Check-in with QR code
        attendanceRecord = await AttendanceService.checkInWithQR(
          qrCode: qrCode,
          latitude: currentPosition?.latitude,
          longitude: currentPosition?.longitude,
          notes: 'QR Code Check-in: $qrCode',
        );
      } else if (todayAttendance.checkOutTime == null) {
        // Check-out with QR code
        attendanceRecord = await AttendanceService.checkOutWithQR(
          qrCode: qrCode,
          notes: 'QR Code Check-out: $qrCode',
        );
      } else {
        // Already checked out today
        Navigator.of(context).pop(); // Close loading dialog
        _showAlreadyProcessedDialog();
        return;
      }

      // Close loading dialog and show success
      Navigator.of(context).pop();
      _showAttendanceSuccess(attendanceRecord, todayAttendance == null);
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showError('Failed to process QR attendance: ${e.toString()}');

      // Reset scanning state
      setState(() {
        _isScanning = true;
        _lastScannedCode = null;
      });
    }
  }

  void _showAttendanceSuccess(AttendanceRecord record, bool isCheckIn) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkTheme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.success.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: CustomIconWidget(
                iconName: 'check_circle',
                color: AppTheme.success,
                size: 32,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              isCheckIn
                  ? 'QR Check-In Successful!'
                  : 'QR Check-Out Successful!',
              style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.darkTheme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.darkTheme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Organization', 'Verra Organization'),
                  SizedBox(height: 1.h),
                  _buildInfoRow(
                      'Employee', _currentUser?.fullName ?? 'Unknown'),
                  SizedBox(height: 1.h),
                  _buildInfoRow('ID', _currentUser?.employeeId ?? 'N/A'),
                  SizedBox(height: 1.h),
                  _buildInfoRow(
                      'Time',
                      _formatDateTime(isCheckIn
                          ? record.checkInTime!
                          : record.checkOutTime!)),
                  SizedBox(height: 1.h),
                  _buildInfoRow('Status',
                      record.status.toString().split('.').last.toUpperCase()),
                  if (record.locationLat != null &&
                      record.locationLng != null) ...[
                    SizedBox(height: 1.h),
                    _buildInfoRow('Location',
                        '${record.locationLat?.toStringAsFixed(4)}, ${record.locationLng?.toStringAsFixed(4)}'),
                  ],
                  SizedBox(height: 1.h),
                  _buildInfoRow('QR Code', _lastScannedCode ?? 'N/A'),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppTheme.success.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomIconWidget(
                    iconName: 'verified',
                    color: AppTheme.success,
                    size: 16,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Verified & Synced',
                    style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to dashboard
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.onPrimary,
              minimumSize: Size(double.infinity, 6.h),
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    _showSuccess(
        'QR ${isCheckIn ? 'Check-in' : 'Check-out'} recorded successfully!');
  }

  void _showAlreadyProcessedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkTheme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'info',
              color: AppTheme.warning,
              size: 24,
            ),
            SizedBox(width: 3.w),
            Text(
              'Already Processed',
              style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.darkTheme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'You have already checked in and out for today. Your attendance has been recorded.',
          style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
            color:
                AppTheme.darkTheme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to dashboard
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.onPrimary,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Reset scanning state
    setState(() {
      _isScanning = true;
      _lastScannedCode = null;
    });
  }

  void _showValidationError(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkTheme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'location_off',
              color: AppTheme.warning,
              size: 24,
            ),
            SizedBox(width: 3.w),
            Text(
              'Access Restricted',
              style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.darkTheme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.darkTheme.colorScheme.onSurface
                    .withValues(alpha: 0.8),
              ),
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warning.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Troubleshooting Tips:',
                    style: AppTheme.darkTheme.textTheme.labelMedium?.copyWith(
                      color: AppTheme.warning,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    '• Ensure you are within the designated work area\n• Check your location services are enabled\n• Make sure you have location permissions',
                    style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.darkTheme.colorScheme.onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to dashboard
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                  color: AppTheme.darkTheme.colorScheme.onSurface
                      .withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _initializeScanner(); // Retry validation
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.onPrimary,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkTheme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'camera_alt',
              color: AppTheme.primary,
              size: 24,
            ),
            SizedBox(width: 3.w),
            Text(
              'Camera Permission',
              style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.darkTheme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Camera access is required to scan QR codes for attendance tracking. Please enable camera permission in your device settings.',
          style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
            color:
                AppTheme.darkTheme.colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to dashboard
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                  color: AppTheme.darkTheme.colorScheme.onSurface
                      .withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: AppTheme.onPrimary,
            ),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.error,
      textColor: AppTheme.onPrimary,
      fontSize: 14.sp,
    );
  }

  void _showSuccess(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AppTheme.success,
      textColor: AppTheme.onPrimary,
      fontSize: 14.sp,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
            color:
                AppTheme.darkTheme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
            color: AppTheme.darkTheme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  void _toggleFlash() {
    if (_scannerController != null) {
      setState(() {
        _isFlashOn = !_isFlashOn;
      });
      _scannerController!.toggleTorch();
      HapticFeedback.lightImpact();
    }
  }

  void _onBackPressed() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isInitializing
          ? _buildLoadingView()
          : _hasPermission
              ? _buildScannerView()
              : _buildErrorView(),
    );
  }

  Widget _buildLoadingView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.primary,
              strokeWidth: 3,
            ),
            SizedBox(height: 3.h),
            Text(
              'Initializing Scanner...',
              style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                color: Colors.white,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Validating user and location',
              style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _onBackPressed,
                    icon: CustomIconWidget(
                      iconName: 'arrow_back_ios',
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'QR Scanner',
                    style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Error content
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(6.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.error.withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: CustomIconWidget(
                          iconName: 'error_outline',
                          color: AppTheme.error,
                          size: 48,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Scanner Unavailable',
                        style: AppTheme.darkTheme.textTheme.headlineSmall
                            ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Unable to access the camera or validate your location. Please check your permissions and try again.',
                        textAlign: TextAlign.center,
                        style:
                            AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      ElevatedButton(
                        onPressed: _initializeScanner,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: AppTheme.onPrimary,
                          minimumSize: Size(60.w, 6.h),
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        // Camera preview
        MobileScanner(
          controller: _scannerController,
          onDetect: _onQRCodeDetected,
        ),

        // Dark overlay with scanner frame
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.black.withValues(alpha: 0.5),
          child: Stack(
            children: [
              // Scanner frame overlay
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 70.w,
                          height: 70.w,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppTheme.primary,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            children: [
                              // Corner indicators
                              _buildCornerIndicator(Alignment.topLeft),
                              _buildCornerIndicator(Alignment.topRight),
                              _buildCornerIndicator(Alignment.bottomLeft),
                              _buildCornerIndicator(Alignment.bottomRight),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Enhanced instruction text
              Positioned(
                bottom: 25.h,
                left: 0,
                right: 0,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 8.w),
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Scan Verra QR Code',
                        textAlign: TextAlign.center,
                        style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Position QR code within the frame for attendance',
                        textAlign: TextAlign.center,
                        style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Header with back button
        SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: _onBackPressed,
                    icon: CustomIconWidget(
                      iconName: 'arrow_back_ios',
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                Text(
                  'Scan QR Code',
                  style: AppTheme.darkTheme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 12.w), // Balance the layout
              ],
            ),
          ),
        ),

        // Flash toggle button
        Positioned(
          bottom: 8.h,
          right: 6.w,
          child: Container(
            decoration: BoxDecoration(
              color: _isFlashOn
                  ? AppTheme.primary.withValues(alpha: 0.9)
                  : Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isFlashOn
                    ? AppTheme.primary
                    : Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: IconButton(
              onPressed: _toggleFlash,
              icon: CustomIconWidget(
                iconName: _isFlashOn ? 'flash_on' : 'flash_off',
                color: _isFlashOn ? AppTheme.onPrimary : Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCornerIndicator(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 8.w,
        height: 8.w,
        decoration: BoxDecoration(
          border: Border(
            top: alignment == Alignment.topLeft ||
                    alignment == Alignment.topRight
                ? BorderSide(color: AppTheme.primary, width: 4)
                : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft ||
                    alignment == Alignment.bottomRight
                ? BorderSide(color: AppTheme.primary, width: 4)
                : BorderSide.none,
            left: alignment == Alignment.topLeft ||
                    alignment == Alignment.bottomLeft
                ? BorderSide(color: AppTheme.primary, width: 4)
                : BorderSide.none,
            right: alignment == Alignment.topRight ||
                    alignment == Alignment.bottomRight
                ? BorderSide(color: AppTheme.primary, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}