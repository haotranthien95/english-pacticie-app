import 'package:flutter/material.dart';
import '../../../core/utils/responsive_utils.dart';

/// Responsive builder widget for adaptive layouts
///
/// Builds different layouts based on device type using Material Design breakpoints.
/// Provides three builders for phone, tablet, and large tablet layouts.
class ResponsiveBuilder extends StatelessWidget {
  /// Builder for phone layout (< 600dp)
  final WidgetBuilder phone;

  /// Builder for tablet layout (>= 600dp and < 840dp)
  /// If not provided, uses phone builder
  final WidgetBuilder? tablet;

  /// Builder for large tablet layout (>= 840dp)
  /// If not provided, uses tablet or phone builder
  final WidgetBuilder? largeTablet;

  const ResponsiveBuilder({
    super.key,
    required this.phone,
    this.tablet,
    this.largeTablet,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(
      MediaQuery.of(context).size.width,
    );

    switch (deviceType) {
      case DeviceType.phone:
        return phone(context);
      case DeviceType.tablet:
        return tablet?.call(context) ?? phone(context);
      case DeviceType.largeTablet:
        return largeTablet?.call(context) ??
            tablet?.call(context) ??
            phone(context);
    }
  }
}

/// Responsive value selector
///
/// Returns different values based on device type.
class ResponsiveValue<T> {
  final T phone;
  final T? tablet;
  final T? largeTablet;

  const ResponsiveValue({
    required this.phone,
    this.tablet,
    this.largeTablet,
  });

  /// Get value based on current context
  T get(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(
      MediaQuery.of(context).size.width,
    );

    switch (deviceType) {
      case DeviceType.phone:
        return phone;
      case DeviceType.tablet:
        return tablet ?? phone;
      case DeviceType.largeTablet:
        return largeTablet ?? tablet ?? phone;
    }
  }
}

/// Adaptive container with responsive constraints
///
/// Centers content and applies max width on larger screens
class AdaptiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const AdaptiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = ResponsiveUtils.getAdaptiveContentWidth(context);
    final adaptivePadding =
        padding ?? ResponsiveUtils.getAdaptivePadding(context);

    return Container(
      color: color,
      child: Center(
        child: Container(
          constraints: maxWidth != null
              ? BoxConstraints(maxWidth: maxWidth)
              : null,
          padding: adaptivePadding,
          child: child,
        ),
      ),
    );
  }
}

/// Adaptive grid with responsive column count
///
/// Automatically adjusts number of columns based on device type
class AdaptiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double? spacing;
  final double? runSpacing;
  final double? childAspectRatio;

  const AdaptiveGrid({
    super.key,
    required this.children,
    this.spacing,
    this.runSpacing,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    final crossAxisCount =
        ResponsiveUtils.getAdaptiveGridCrossAxisCount(context);
    final adaptiveSpacing =
        spacing ?? ResponsiveUtils.getAdaptiveSpacing(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: adaptiveSpacing,
        mainAxisSpacing: runSpacing ?? adaptiveSpacing,
        childAspectRatio: childAspectRatio ?? 1.0,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Adaptive dialog wrapper
///
/// Applies responsive width constraints to dialogs
class AdaptiveDialog extends StatelessWidget {
  final Widget child;

  const AdaptiveDialog({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final dialogWidth = ResponsiveUtils.getAdaptiveDialogWidth(context);

    if (dialogWidth == null) {
      return child;
    }

    return Container(
      constraints: BoxConstraints(maxWidth: dialogWidth),
      child: child,
    );
  }
}
