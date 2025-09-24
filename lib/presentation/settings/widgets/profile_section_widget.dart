import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ProfileSectionWidget extends StatefulWidget {
  final String userName;
  final String employeeId;
  final String? profileImageUrl;
  final Function(String)? onNameChanged;
  final Function(String)? onImageChanged;

  const ProfileSectionWidget({
    super.key,
    required this.userName,
    required this.employeeId,
    this.profileImageUrl,
    this.onNameChanged,
    this.onImageChanged,
  });

  @override
  State<ProfileSectionWidget> createState() => _ProfileSectionWidgetState();
}

class _ProfileSectionWidgetState extends State<ProfileSectionWidget> {
  final ImagePicker _picker = ImagePicker();
  String? _selectedImagePath;
  bool _isEditingName = false;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceDialog() async {
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.darkTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 0.5.h,
                margin: EdgeInsets.only(top: 1.h),
                decoration: BoxDecoration(
                  color: AppTheme.darkTheme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    Text(
                      'Change Profile Picture',
                      style: AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildImageSourceOption(
                          icon: 'camera_alt',
                          label: 'Camera',
                          onTap: () => _pickImage(ImageSource.camera),
                        ),
                        _buildImageSourceOption(
                          icon: 'photo_library',
                          label: 'Gallery',
                          onTap: () => _pickImage(ImageSource.gallery),
                        ),
                        if (_selectedImagePath != null ||
                            widget.profileImageUrl != null)
                          _buildImageSourceOption(
                            icon: 'delete',
                            label: 'Remove',
                            onTap: _removeImage,
                            isDestructive: true,
                          ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required String icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 20.w,
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Column(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: isDestructive
                    ? AppTheme.darkTheme.colorScheme.error
                        .withValues(alpha: 0.1)
                    : AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: icon,
                  size: 6.w,
                  color: isDestructive
                      ? AppTheme.darkTheme.colorScheme.error
                      : AppTheme.primary,
                ),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              label,
              style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                color: isDestructive
                    ? AppTheme.darkTheme.colorScheme.error
                    : AppTheme.darkTheme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Request permission
      Permission permission =
          source == ImageSource.camera ? Permission.camera : Permission.photos;

      if (!kIsWeb && !await permission.isGranted) {
        final status = await permission.request();
        if (!status.isGranted) {
          _showPermissionDialog(source);
          return;
        }
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        await _cropImage(image.path);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image. Please try again.');
    }
  }

  Future<void> _cropImage(String imagePath) async {
    try {
      if (kIsWeb) {
        // Web doesn't support image cropping, use image directly
        setState(() {
          _selectedImagePath = imagePath;
        });
        widget.onImageChanged?.call(imagePath);
        return;
      }

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Picture',
            toolbarColor: AppTheme.darkTheme.colorScheme.surface,
            toolbarWidgetColor: AppTheme.darkTheme.colorScheme.onSurface,
            backgroundColor: AppTheme.darkTheme.colorScheme.surface,
            activeControlsWidgetColor: AppTheme.primary,
            cropGridColor: AppTheme.primary,
            cropFrameColor: AppTheme.primary,
            dimmedLayerColor: AppTheme.darkTheme.colorScheme.surface
                .withValues(alpha: 0.8),
          ),
          IOSUiSettings(
            title: 'Crop Profile Picture',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _selectedImagePath = croppedFile.path;
        });
        widget.onImageChanged?.call(croppedFile.path);
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to crop image. Please try again.');
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImagePath = null;
    });
    widget.onImageChanged?.call('');
    HapticFeedback.lightImpact();
  }

  void _showPermissionDialog(ImageSource source) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkTheme.colorScheme.surface,
        title: Text(
          'Permission Required',
          style: AppTheme.darkTheme.textTheme.titleMedium,
        ),
        content: Text(
          'Please grant ${source == ImageSource.camera ? 'camera' : 'photo'} permission to change your profile picture.',
          style: AppTheme.darkTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                  color: AppTheme.darkTheme.colorScheme.onSurface
                      .withValues(alpha: 0.7)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text(
              'Settings',
              style: TextStyle(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.darkTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _toggleNameEdit() {
    setState(() {
      _isEditingName = !_isEditingName;
    });

    if (!_isEditingName && _nameController.text != widget.userName) {
      widget.onNameChanged?.call(_nameController.text);
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        color: AppTheme.darkTheme.colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.darkTheme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.darkTheme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Picture Section
          GestureDetector(
            onTap: _showImageSourceDialog,
            child: Stack(
              children: [
                Container(
                  width: 25.w,
                  height: 25.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: _selectedImagePath != null
                        ? (kIsWeb
                            ? Image.network(
                                _selectedImagePath!,
                                width: 25.w,
                                height: 25.w,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildDefaultAvatar(),
                              )
                            : Image.file(
                                File(_selectedImagePath!),
                                width: 25.w,
                                height: 25.w,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildDefaultAvatar(),
                              ))
                        : widget.profileImageUrl != null
                            ? CustomImageWidget(
                                imageUrl: widget.profileImageUrl!,
                                width: 25.w,
                                height: 25.w,
                                fit: BoxFit.cover,
                              )
                            : _buildDefaultAvatar(),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 8.w,
                    height: 8.w,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.darkTheme.colorScheme.surface,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: CustomIconWidget(
                        iconName: 'camera_alt',
                        size: 4.w,
                        color: AppTheme.darkTheme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 3.h),

          // Name Section
          Row(
            children: [
              Expanded(
                child: _isEditingName
                    ? TextField(
                        controller: _nameController,
                        style:
                            AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppTheme.primary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: AppTheme.primary, width: 2),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 3.w, vertical: 1.h),
                        ),
                        textAlign: TextAlign.center,
                        onSubmitted: (_) => _toggleNameEdit(),
                      )
                    : Text(
                        widget.userName,
                        style:
                            AppTheme.darkTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
              ),
              SizedBox(width: 2.w),
              InkWell(
                onTap: _toggleNameEdit,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  child: CustomIconWidget(
                    iconName: _isEditingName ? 'check' : 'edit',
                    size: 5.w,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 1.h),

          // Employee ID
          Text(
            'ID: ${widget.employeeId}',
            style: AppTheme.darkTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.darkTheme.colorScheme.onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 25.w,
      height: 25.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.3),
            AppTheme.primary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: CustomIconWidget(
          iconName: 'person',
          size: 12.w,
          color: AppTheme.primary,
        ),
      ),
    );
  }
}
