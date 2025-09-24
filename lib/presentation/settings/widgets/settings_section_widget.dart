import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SettingsSectionWidget extends StatelessWidget {
  final String title;
  final List<SettingsItem> items;
  final EdgeInsets? margin;

  const SettingsSectionWidget({
    super.key,
    required this.title,
    required this.items,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 2.w, bottom: 1.h),
            child: Text(
              title,
              style: AppTheme.darkTheme.textTheme.titleSmall?.copyWith(
                color: AppTheme.primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color:
                  AppTheme.darkTheme.colorScheme.surface.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.darkTheme.colorScheme.outline
                    .withValues(alpha: 0.2),
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
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isLast = index == items.length - 1;

                return _buildSettingsItem(item, isLast);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(SettingsItem item, bool isLast) {
    return Container(
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: AppTheme.darkTheme.colorScheme.outline
                      .withValues(alpha: 0.1),
                  width: 1,
                ),
              )
            : null,
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
        leading: item.icon != null
            ? Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: (item.iconColor ?? AppTheme.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: item.icon!,
                    size: 5.w,
                    color: item.iconColor ?? AppTheme.primary,
                  ),
                ),
              )
            : null,
        title: Text(
          item.title,
          style: AppTheme.darkTheme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: item.isDestructive
                ? AppTheme.darkTheme.colorScheme.error
                : AppTheme.darkTheme.colorScheme.onSurface,
          ),
        ),
        subtitle: item.subtitle != null
            ? Text(
                item.subtitle!,
                style: AppTheme.darkTheme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.darkTheme.colorScheme.onSurface
                      .withValues(alpha: 0.7),
                ),
              )
            : null,
        trailing: _buildTrailing(item),
        onTap: item.onTap != null
            ? () {
                HapticFeedback.lightImpact();
                item.onTap!();
              }
            : null,
      ),
    );
  }

  Widget? _buildTrailing(SettingsItem item) {
    if (item.trailing != null) {
      return item.trailing;
    }

    if (item.hasSwitch) {
      return Switch(
        value: item.switchValue ?? false,
        onChanged: item.onSwitchChanged,
        activeColor: AppTheme.primary,
        activeTrackColor: AppTheme.primary.withValues(alpha: 0.3),
        inactiveThumbColor:
            AppTheme.darkTheme.colorScheme.onSurface.withValues(alpha: 0.5),
        inactiveTrackColor: AppTheme.darkTheme.colorScheme.outline,
      );
    }

    if (item.showDisclosure) {
      return CustomIconWidget(
        iconName: 'chevron_right',
        size: 5.w,
        color: AppTheme.darkTheme.colorScheme.onSurface.withValues(alpha: 0.5),
      );
    }

    return null;
  }
}

class SettingsItem {
  final String title;
  final String? subtitle;
  final String? icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool hasSwitch;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final bool showDisclosure;
  final bool isDestructive;

  const SettingsItem({
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.onTap,
    this.trailing,
    this.hasSwitch = false,
    this.switchValue,
    this.onSwitchChanged,
    this.showDisclosure = true,
    this.isDestructive = false,
  });
}
