import 'package:flutter/material.dart';

/// Responsive utility class for adaptive layouts
///
/// Provides helpers to determine device type and apply responsive layouts
/// based on Material Design breakpoints:
/// - Phone: < 600dp
/// - Tablet: >= 600dp and < 840dp
/// - Large Tablet: >= 840dp
class ResponsiveUtils {
  // Prevent instantiation
  ResponsiveUtils._();

  /// Material Design breakpoints
  static const double phoneBreakpoint = 600.0;
  static const double tabletBreakpoint = 840.0;

  /// Device types
  static DeviceType getDeviceType(double width) {
    if (width >= tabletBreakpoint) {
      return DeviceType.largeTablet;
    } else if (width >= phoneBreakpoint) {
      return DeviceType.tablet;
    } else {
      return DeviceType.phone;
    }
  }

  /// Check if device is phone
  static bool isPhone(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < phoneBreakpoint;
  }

  /// Check if device is tablet (medium)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= phoneBreakpoint && width < tabletBreakpoint;
  }

  /// Check if device is large tablet
  static bool isLargeTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint;
  }

  /// Check if device is tablet or larger
  static bool isTabletOrLarger(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= phoneBreakpoint;
  }

  /// Get adaptive padding based on device type
  static EdgeInsets getAdaptivePadding(BuildContext context) {
    if (isPhone(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

  /// Get adaptive horizontal padding
  static EdgeInsets getAdaptiveHorizontalPadding(BuildContext context) {
    if (isPhone(context)) {
      return const EdgeInsets.symmetric(horizontal: 16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32.0);
    }
  }

  /// Get adaptive content width (for centering content on large screens)
  static double? getAdaptiveContentWidth(BuildContext context) {
    if (isPhone(context)) {
      return null; // Full width
    } else if (isTablet(context)) {
      return 600.0; // Max 600dp for tablets
    } else {
      return 800.0; // Max 800dp for large tablets
    }
  }

  /// Get adaptive grid cross-axis count
  static int getAdaptiveGridCrossAxisCount(BuildContext context) {
    if (isPhone(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 3;
    }
  }

  /// Get adaptive card width
  static double getAdaptiveCardWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (isPhone(context)) {
      return width - 32; // Full width minus padding
    } else if (isTablet(context)) {
      return 400.0; // Fixed width for tablets
    } else {
      return 500.0; // Fixed width for large tablets
    }
  }

  /// Get adaptive font scale
  static double getAdaptiveFontScale(BuildContext context) {
    if (isPhone(context)) {
      return 1.0;
    } else if (isTablet(context)) {
      return 1.1;
    } else {
      return 1.2;
    }
  }

  /// Get adaptive spacing
  static double getAdaptiveSpacing(BuildContext context) {
    if (isPhone(context)) {
      return 8.0;
    } else if (isTablet(context)) {
      return 12.0;
    } else {
      return 16.0;
    }
  }

  /// Get adaptive dialog width
  static double? getAdaptiveDialogWidth(BuildContext context) {
    if (isPhone(context)) {
      return null; // Default dialog width
    } else {
      return 500.0; // Fixed width for tablets
    }
  }
}

/// Device type enumeration
enum DeviceType {
  phone,
  tablet,
  largeTablet,
}
