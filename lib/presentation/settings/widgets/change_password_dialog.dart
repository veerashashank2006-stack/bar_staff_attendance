import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ChangePasswordDialog extends StatefulWidget {
  const ChangePasswordDialog({super.key});

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  PasswordStrength _passwordStrength = PasswordStrength.weak;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String password) {
    setState(() {
      if (password.isEmpty) {
        _passwordStrength = PasswordStrength.weak;
      } else if (password.length < 6) {
        _passwordStrength = PasswordStrength.weak;
      } else if (password.length < 8 || !_hasSpecialCharacters(password)) {
        _passwordStrength = PasswordStrength.medium;
      } else {
        _passwordStrength = PasswordStrength.strong;
      }
    });
  }

  bool _hasSpecialCharacters(String password) {
    return password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      // Mock validation - in real app, validate against backend
      if (_currentPasswordController.text != 'password123') {
        throw Exception('Current password is incorrect');
      }

      HapticFeedback.lightImpact();

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Password changed successfully'),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.darkTheme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: 90.w),
        decoration: BoxDecoration(
          color: AppTheme.darkTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                AppTheme.darkTheme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.darkTheme.colorScheme.shadow,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(6.w),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: 'lock',
                          size: 5.w,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Text(
                        'Change Password',
                        style:
                            AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: EdgeInsets.all(2.w),
                        child: CustomIconWidget(
                          iconName: 'close',
                          size: 5.w,
                          color: AppTheme.darkTheme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 4.h),

                // Current Password
                Text(
                  'Current Password',
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 1.h),
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: !_isCurrentPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Enter current password',
                    suffixIcon: IconButton(
                      icon: CustomIconWidget(
                        iconName: _isCurrentPasswordVisible
                            ? 'visibility_off'
                            : 'visibility',
                        size: 5.w,
                        color: AppTheme.darkTheme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          _isCurrentPasswordVisible =
                              !_isCurrentPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your current password';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 3.h),

                // New Password
                Text(
                  'New Password',
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 1.h),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: !_isNewPasswordVisible,
                  onChanged: _checkPasswordStrength,
                  decoration: InputDecoration(
                    hintText: 'Enter new password',
                    suffixIcon: IconButton(
                      icon: CustomIconWidget(
                        iconName: _isNewPasswordVisible
                            ? 'visibility_off'
                            : 'visibility',
                        size: 5.w,
                        color: AppTheme.darkTheme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          _isNewPasswordVisible = !_isNewPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    if (value == _currentPasswordController.text) {
                      return 'New password must be different from current password';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 1.h),

                // Password Strength Indicator
                _buildPasswordStrengthIndicator(),

                SizedBox(height: 3.h),

                // Confirm Password
                Text(
                  'Confirm New Password',
                  style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 1.h),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    hintText: 'Confirm new password',
                    suffixIcon: IconButton(
                      icon: CustomIconWidget(
                        iconName: _isConfirmPasswordVisible
                            ? 'visibility_off'
                            : 'visibility',
                        size: 5.w,
                        color: AppTheme.darkTheme.colorScheme.onSurface
                            .withValues(alpha: 0.7),
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 4.h),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _changePassword,
                        child: _isLoading
                            ? SizedBox(
                                width: 5.w,
                                height: 5.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.darkTheme.colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : const Text('Change Password'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    Color strengthColor;
    String strengthText;
    double strengthValue;

    switch (_passwordStrength) {
      case PasswordStrength.weak:
        strengthColor = AppTheme.darkTheme.colorScheme.error;
        strengthText = 'Weak';
        strengthValue = 0.33;
        break;
      case PasswordStrength.medium:
        strengthColor = AppTheme.warning;
        strengthText = 'Medium';
        strengthValue = 0.66;
        break;
      case PasswordStrength.strong:
        strengthColor = AppTheme.success;
        strengthText = 'Strong';
        strengthValue = 1.0;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password Strength',
              style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                color: AppTheme.darkTheme.colorScheme.onSurface
                    .withValues(alpha: 0.7),
              ),
            ),
            Text(
              strengthText,
              style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                color: strengthColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 0.5.h),
        LinearProgressIndicator(
          value: strengthValue,
          backgroundColor:
              AppTheme.darkTheme.colorScheme.outline.withValues(alpha: 0.3),
          valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
          minHeight: 0.5.h,
        ),
      ],
    );
  }
}

enum PasswordStrength { weak, medium, strong }
