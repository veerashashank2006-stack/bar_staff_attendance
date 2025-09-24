import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';


/// Custom app bar widget with glassmorphism effect and professional styling
/// Implements the Contemporary Minimalist Professional design with dark-first approach
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final bool automaticallyImplyLeading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface.withAlpha(230),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: colorScheme.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: AppBar(
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: foregroundColor ?? colorScheme.onSurface,
            letterSpacing: 0.15,
          ),
        ),
        centerTitle: centerTitle,
        backgroundColor: Colors.transparent,
        foregroundColor: foregroundColor ?? colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: automaticallyImplyLeading,
        leading: _buildLeading(context),
        actions: _buildActions(context),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: theme.brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          statusBarBrightness: theme.brightness,
        ),
      ),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leading != null) return leading;

    if (showBackButton && Navigator.of(context).canPop()) {
      return IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        onPressed: () {
          HapticFeedback.lightImpact();
          if (onBackPressed != null) {
            onBackPressed!();
          } else {
            Navigator.of(context).pop();
          }
        },
        tooltip: 'Back',
      );
    }

    return null;
  }

  List<Widget>? _buildActions(BuildContext context) {
    if (actions == null) return null;

    return actions!.map((action) {
      if (action is IconButton) {
        return IconButton(
          icon: action.icon,
          onPressed: () {
            HapticFeedback.lightImpact();
            action.onPressed?.call();
          },
          tooltip: action.tooltip,
        );
      }
      return action;
    }).toList();
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Specialized app bar for dashboard with quick actions
class CustomDashboardAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String userName;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final int notificationCount;

  const CustomDashboardAppBar({
    super.key,
    required this.userName,
    this.onNotificationTap,
    this.onProfileTap,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withAlpha(230),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good ${_getGreeting()}',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withAlpha(179),
              ),
            ),
            Text(
              userName,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // Notifications
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 24),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (onNotificationTap != null) {
                    onNotificationTap!();
                  } else {
                    Navigator.pushNamed(context, '/notifications');
                  }
                },
                tooltip: 'Notifications',
              ),
              if (notificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      notificationCount > 99
                          ? '99+'
                          : notificationCount.toString(),
                      style: GoogleFonts.inter(
                        color: colorScheme.onError,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          // Profile
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, size: 24),
            onPressed: () {
              HapticFeedback.lightImpact();
              if (onProfileTap != null) {
                onProfileTap!();
              } else {
                Navigator.pushNamed(context, '/settings');
              }
            },
            tooltip: 'Profile',
          ),
          const SizedBox(width: 8),
        ],
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: theme.brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          statusBarBrightness: theme.brightness,
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Specialized app bar for scanner screen with minimal design
class CustomScannerAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final VoidCallback? onClose;
  final VoidCallback? onFlashToggle;
  final bool isFlashOn;

  const CustomScannerAppBar({
    super.key,
    this.onClose,
    this.onFlashToggle,
    this.isFlashOn = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(179),
      ),
      child: AppBar(
        title: Text(
          'Scan QR Code',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 24),
          onPressed: () {
            HapticFeedback.lightImpact();
            if (onClose != null) {
              onClose!();
            } else {
              Navigator.of(context).pop();
            }
          },
          tooltip: 'Close',
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFlashOn ? Icons.flash_on : Icons.flash_off,
              size: 24,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              onFlashToggle?.call();
            },
            tooltip: isFlashOn ? 'Turn off flash' : 'Turn on flash',
          ),
          const SizedBox(width: 8),
        ],
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
