import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ExportToolbarWidget extends StatelessWidget {
  final VoidCallback onExportPDF;
  final VoidCallback onExportExcel;
  final bool isExporting;
  final String? exportingType;

  const ExportToolbarWidget({
    super.key,
    required this.onExportPDF,
    required this.onExportExcel,
    this.isExporting = false,
    this.exportingType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: _buildExportButton(
                context,
                'Export PDF',
                Icons.picture_as_pdf,
                onExportPDF,
                isExporting && exportingType == 'PDF',
                colorScheme.error,
                theme,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: _buildExportButton(
                context,
                'Export Excel',
                Icons.table_chart,
                onExportExcel,
                isExporting && exportingType == 'Excel',
                AppTheme.success,
                theme,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed,
    bool isLoading,
    Color color,
    ThemeData theme,
  ) {
    return ElevatedButton.icon(
      onPressed: isExporting
          ? null
          : () {
              HapticFeedback.lightImpact();
              onPressed();
            },
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.onPrimary,
                ),
              ),
            )
          : Icon(icon, size: 20),
      label: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 2.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }
}
